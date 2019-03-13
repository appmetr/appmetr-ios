/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "TrackingManager.h"

#import "CJSONSerializer.h"
#import "AMBase64Util.h"
#import "Constants.h"
#import "Utils.h"
#import "SessionData.h"
#import "BatchFile.h"
#import "AppMetrUnsatisfiedConditionException.h"
#import "ServerError.h"
#import "AppMetr.h"
#import "UploadCacheTask.h"


// Global variables
extern TrackingManager *gSharedManager;

#pragma mark - Private category

@interface TrackingManager ()

@property(readwrite, retain) UploadCacheTask* uploadCacheTask;

- (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval selector:(SEL)selector;

- (void)createTimers;

- (NSData *)createBatchData;

// flush events to disk
- (void)flushData;

- (void)flushTimer:(NSTimer *)timer;

// send prepared files to server
- (void)uploadTimer:(NSTimer *)timer;

- (void)closeStreams;

/// track methods
- (void)track:(NSDictionary *)trackProperties;

@end


#pragma mark - Class implementation

@implementation TrackingManager

@synthesize token = mToken;
@synthesize userIdentifier = mUserID;
@synthesize debugLoggingEnabled = mDebugLoggingEnabled;
@synthesize uploadCacheTask;

#pragma mark - Initializing

- (id)init {
    self = [super init];
    if (self) {
        mFlushDataTimeInterval = kDefaultFlashDataDelay;
        mUploadDataTimeInterval = kDefaultUploadDataDelay;
        mBatchFileMaxSize = kDefaultBatchFileMaxSize;

        //initialize main stack
        mEventStack = [[NSMutableArray alloc] init];

        // restore data from previous sessions
        mSessionData = [[SessionData alloc] init];

        mBatchFileLock = [[NSLock alloc] init];

        [self setupWithUserID:[Utils uniqueIdentifier]];

        // retrieve version string
        [self readSettingsFromPInfoFile];
        
        self.uploadCacheTask = [[UploadCacheTask alloc] initWithSession:mSessionData];
        self.uploadCacheTask.logging = mDebugLoggingEnabled;

        // subscribe notifications
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(applicationDidEnterBackground)
                                   name:UIApplicationWillResignActiveNotification object:nil];

        [notificationCenter addObserver:self selector:@selector(applicationWillEnterForeground)
                                   name:UIApplicationDidBecomeActiveNotification object:nil];

        [notificationCenter addObserver:self selector:@selector(applicationDidEnterBackground)
                                   name:UIApplicationDidEnterBackgroundNotification object:nil];

        [notificationCenter addObserver:self selector:@selector(applicationWillEnterForeground)
                                   name:UIApplicationWillEnterForegroundNotification object:nil];

        [notificationCenter addObserver:self selector:@selector(applicationWillTerminate)
                                   name:UIApplicationWillTerminateNotification object:nil];
        mWorkingQueue = dispatch_queue_create("AppmetrFlush", NULL);
        [self createTimers];

        // send previous session duration
        [self startSession];
        mStartTime = [[NSDate date] timeIntervalSince1970];
    }

    return self;
}

#pragma mark - Destructor

- (void)dealloc {
    [mFlashDataTimer invalidate];
    [mFlashDataTimer release];
    [mUploadDataTimer invalidate];
    [mUploadDataTimer release];
    
    [self flushData];
    [self closeStreams];

    @synchronized (mEventStack) {
        [mEventStack release];
    }

    [mSessionData release];
    [mBatchFileStream release];
    [mBatchFileLock release];
    self.uploadCacheTask = nil;
    

    [mToken release];
    [mUserID release];
    [mVersion release];
    
    dispatch_release(mWorkingQueue);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}

#pragma mark - Setting up
- (void)readSettingsFromPInfoFile {
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];

    mVersion = [[info objectForKey:@"CFBundleShortVersionString"] retain];
    if (![mVersion length]) {
        mVersion = [[info objectForKey:@"CFBundleVersion"] retain];
    }

    assert(([mVersion length] != 0) && "CFBundleShortVersionString or CFBundleVersion should be presented in Info.plist");


    mServerAddress = kAppMetrDefaultUrl;
    if ([info objectForKey:@"appmetrUrl"] != nil) {
        mServerAddress = [info objectForKey:@"appmetrUrl"];
    }
    assert(([mServerAddress length] != 0) && "appmetrUrl should be not empty");
}

#pragma mark - Setting up

- (void)setupWithToken:(NSString *)token {
    if (mToken == nil) {
        if (token.length > kTokenSizeLimit) {
            [NSException raise:NSInvalidArgumentException
                        format:@"Invalid token. length should be no more than %d", (unsigned int)kTokenSizeLimit];
        }
        else if ([token isKindOfClass:[NSNull class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"Invalid token. token should not be null: %@", token];
        }
    }
    else {
        [mToken release];
    }
    
    if (token != nil && ![token isKindOfClass:[NSNull class]]) {
        mToken = [token copy];
    }
}

- (void)setupSizeLimitOfCacheFile:(NSUInteger)limit {
    mBatchFileMaxSize = limit;
}

- (void)setupWithUserID:(NSString *)userID {
    [mUserID release];
    mUserID = [userID retain];
}

#pragma mark - Timer methods

- (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval
                                   selector:(SEL)selector {
    return [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                            target:self
                                          selector:selector
                                          userInfo:nil repeats:YES];
}


- (void)createTimers {
    mFlashDataTimer = [[self scheduledTimerWithTimeInterval:mFlushDataTimeInterval
                                                   selector:@selector(flushTimer:)]
                       retain];
    
    // schedule timer for sending packets to server
    mUploadDataTimer = [[self scheduledTimerWithTimeInterval:mUploadDataTimeInterval
                                                    selector:@selector(uploadTimer:)]
                        retain];
}

- (NSData *)createBatchData {
    NSMutableDictionary *batches = [NSMutableDictionary dictionary];
    [batches setObject:[NSNumber numberWithUnsignedInteger:[mSessionData nextBatchIndex]]
                forKey:@"batchId"];

    @synchronized (mEventStack) {
        NSMutableArray *eventList = [mEventStack mutableCopy];
        [mEventStack removeAllObjects];

        [batches setObject:eventList
                    forKey:@"batch"];

        [eventList release];
    }

    NSError *serializeError = nil;
    NSData *data = [[AMCJSONSerializer serializer] serializeDictionary:batches
                                                               error:&serializeError];
    if (serializeError) {
        NSLog(@"JSON serializer error: %@", serializeError.description);
        [NSException raise:NSGenericException
                    format:@"%@", serializeError.description];
    }
    
    if(data)
        data = [Utils compressData:data];

    return data;
}

- (void)flushData {
    NSData *chunk = nil;
    @synchronized (mEventStack) {
        if ([mEventStack count]) {
            chunk = [self createBatchData];
        }
    }

    if (chunk) {
        // lock mutex
        @synchronized (mBatchFileLock) {

            if (!mBatchFileStream) {
                mBatchFileStream = [[BatchFile alloc] initWithIndex:[mSessionData nextFileIndex]];
            }
            else if (mBatchFileStream.contentSize + [chunk length] > mBatchFileMaxSize) {
                [self closeStreams];
                mBatchFileStream = [[BatchFile alloc] initWithIndex:[mSessionData nextFileIndex]];
            }

            [mBatchFileStream addChunkData:chunk];
        }
    }
}

- (void)uploadData {
    if (mToken == nil || [mToken isKindOfClass:[NSNull class]]) {
        NSLog(@"Call setupWithToken before uploadData");
    }
    
    NSString* requestAddress = [Utils requestParametersForMethod:@"server.track"
                                                         address:mServerAddress
                                                           token:mToken
                                                  userIdentifier:mUserID];
    self.uploadCacheTask.logging = mDebugLoggingEnabled;
    [self.uploadCacheTask uploadWithAddress:requestAddress];
}

- (void)flushTimer:(NSTimer *)timer {
    dispatch_async(mWorkingQueue, ^{
        @try {
            [self flushData];
        }
        @catch (NSException *exception) {
            NSLog(@"Failed to flush data. Reason: %@", [exception description]);
        }
    });
}

- (void)uploadTimer:(NSTimer *)timer {
    dispatch_async(mWorkingQueue, ^{
        @try {
            [self uploadData];
        }
        @catch (NSException *exception) {
            NSLog(@"Failed to upload data. Reason: %@", [exception description]);
        }
    });
}

- (void)closeStreams {
    // lock mutex
    @synchronized (mBatchFileLock) {
        if (mBatchFileStream) {
            [mBatchFileStream close];
            @synchronized (mSessionData) {
                [mSessionData.fileList addObject:mBatchFileStream.fullPath];
                [mSessionData saveFileList];
            }

            [mBatchFileStream release], mBatchFileStream = nil;
        }
    }
}

#pragma mark - track methods

- (void)track:(NSDictionary *)trackProperties {
    NSMutableDictionary *updatedTrackProperties = [trackProperties mutableCopy];
    NSMutableDictionary* properties = [NSMutableDictionary dictionaryWithDictionary:[updatedTrackProperties objectForKey:@"properties"]];
    id timestamp = [properties objectForKey:kAppmetrPropertyTimestamp];
    
    NSNumber* ts;
    if(timestamp != nil && [timestamp isKindOfClass:[NSNumber class]]) {
        ts = (NSNumber*)timestamp;
        [properties removeObjectForKey:kAppmetrPropertyTimestamp];
    } else if(timestamp != nil && [timestamp isKindOfClass:[NSDate class]]) {
        ts = [NSNumber numberWithUnsignedLongLong:(unsigned long long) ([(NSDate*)timestamp timeIntervalSince1970] * 1000.0)];
        [properties removeObjectForKey:kAppmetrPropertyTimestamp];
    } else {
        ts = [NSNumber numberWithUnsignedLongLong:[Utils timestamp]];
    }
    [updatedTrackProperties setObject:ts forKey:kAppmetrPropertyTimestamp];
    if(properties.count > 0)
        [updatedTrackProperties setObject:properties forKey:@"properties"];
    else
        [updatedTrackProperties removeObjectForKey:@"properties"];

    @synchronized (mEventStack) {
        [mEventStack addObject:updatedTrackProperties];
    }

    [updatedTrackProperties release];
}

- (void)attachProperties {
    [self attachProperties:nil];
}

- (void)attachProperties:(NSDictionary *)properties {
    NSMutableDictionary *userProperties;
    if (properties != nil)
        userProperties = [properties mutableCopy];
    else
        userProperties = [[NSMutableDictionary alloc] init];

    [userProperties setObject:mVersion forKey:kActionVersionKeyName];

    if ([userProperties objectForKey:kActionCountryKeyName] == nil) {
        NSString *country = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        if (country) {
            [userProperties setObject:country
                               forKey:kActionCountryKeyName];
        }
    }
    
    if ([userProperties objectForKey:kActionLanguageKeyName] == nil || [userProperties objectForKey:kActionLocaleKeyName] == nil) {
        NSString* language = [NSLocale preferredLanguages].count > 0 ?[[NSLocale preferredLanguages] objectAtIndex:0] : nil;
        NSString* locale = [[NSLocale currentLocale] localeIdentifier];
        if(language) {
            locale = [language stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
            language = [[NSLocale componentsFromLocaleIdentifier:language] objectForKey:NSLocaleLanguageCode];
        }
        if (language && [userProperties objectForKey:kActionLanguageKeyName] == nil) {
            [userProperties setObject:language
                               forKey:kActionLanguageKeyName];
        }
        if(locale && [userProperties objectForKey:kActionLocaleKeyName] == nil) {
            [userProperties setObject:locale forKey:kActionLocaleKeyName];
        }
    }

    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionAttachProperties forKey:kActionKeyName];
    [action setObject:userProperties forKey:kActionPropertiesKeyName];

    [self track:action];

    [userProperties release];
}

//Track session
- (void)trackSession {
    [self trackSessionWithProperties:nil];
}

- (void)trackSessionWithProperties:(NSDictionary *)properties {
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionTrackSession
               forKey:kActionKeyName];
    
    NSMutableDictionary *mutableProperties = [NSMutableDictionary dictionaryWithDictionary:properties];
    
    long duration = [mSessionData sessionDuration];
    [mSessionData setSessionDuration:0];
    //Set -1 for first session or 0-duration session (only tracking params)
    if (mSessionData.isFirstTrackSessionSent && duration <= 0) {
        return; // not first launch and session duration is empty, ignoring
    }
    if(!mSessionData.isFirstTrackSessionSent) {
        duration = -1; // first launch, track install
    }
    [mutableProperties setValue:[NSNumber numberWithLong:duration] forKey:kSessionDurationKeyName];
    
    [action setObject:mutableProperties
               forKey:kActionPropertiesKeyName];

    [self track:action];

    if (!mSessionData.isFirstTrackSessionSent) {
        [self flushAndUploadAllEvents];
        mSessionData.isFirstTrackSessionSent = YES;
    }
}

//Track level
- (void)trackLevel:(int)level {
    NSMutableDictionary *action = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            kActionTrackLevel, kActionKeyName,
            [NSNumber numberWithInt:level], @"level", nil];
    [self track:action];
}

- (void)trackLevel:(int)level properties:(NSDictionary *)properties {
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionTrackLevel
               forKey:kActionKeyName];
    [action setObject:[NSNumber numberWithInt:level]
               forKey:@"level"];
    [action setObject:properties
               forKey:kActionPropertiesKeyName];

    [self track:action];
}

//Track event
- (void)trackEvent:(NSString *)event {
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionTrackEvent
               forKey:kActionKeyName];
    [action setObject:event
               forKey:@"event"];

    [self track:action];
}

- (void)trackEvent:(NSString *)event properties:(NSDictionary *)properties {
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionTrackEvent
               forKey:kActionKeyName];
    [action setObject:event
               forKey:@"event"];
    [action setObject:properties
               forKey:@"properties"];
    [self track:action];
}

//Track payment
- (void)trackPayment:(NSDictionary *)payment {
    [Utils validatePayment:payment];

    NSMutableDictionary *action = [NSMutableDictionary dictionaryWithDictionary:payment];
    [action setObject:kActionTrackPayment
               forKey:kActionKeyName];

    [self track:action];
}

- (void)trackPayment:(NSDictionary *)payment properties:(NSDictionary *)properties {
    [Utils validatePayment:payment];

    NSMutableDictionary *action = [NSMutableDictionary dictionaryWithDictionary:payment];
    [action setObject:kActionTrackPayment
               forKey:kActionKeyName];

    [action setObject:properties
               forKey:kActionPropertiesKeyName];

    [self track:action];
}

//Track custom event
- (void)trackAdsEvent:(NSString *)eventName {
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionTrackAdsEvent
               forKey:kActionKeyName];

    [action setObject:eventName
               forKey:@"event"];

    [self track:action];
}

- (void)trackInstallURL:(NSURL *)url {
    if (!mSessionData.isInstallURLTracked) {
        NSMutableDictionary *action = [NSMutableDictionary dictionary];
        [action setObject:kActionTrackInstallURL
                   forKey:kActionKeyName];
        NSString *absotuleUrl = [url absoluteString];
        [action setObject:absotuleUrl
                   forKey:@"installURL"];

        [self track:action];

        [self flushAndUploadAllEvents];
        mSessionData.isInstallURLTracked = YES;
    }
}

- (void)trackOptions:(NSArray *)options forCommand:(NSString *)commandId {
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionTrackOptions
               forKey:kActionKeyName];
    [action setObject:commandId
               forKey:@"commandId"];
    [action setObject:@"OK"
               forKey:@"status"];
    [action setObject:options
               forKey:@"options"];

    [self track:action];
}

- (void)trackOptions:(NSArray *)options forCommand:(NSString *)commandId errorCode:(NSString *)code errorMessage:(NSString *)message {
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionTrackOptions
               forKey:kActionKeyName];
    [action setObject:commandId
               forKey:@"commandId"];
    [action setObject:@"ERROR"
               forKey:@"status"];
    [action setObject:options
               forKey:@"options"];

    NSMutableDictionary *error = [NSMutableDictionary dictionary];
    [error setObject:code
              forKey:@"code"];
    [error setObject:message
              forKey:@"message"];

    [action setObject:error forKey:@"error"];

    [self track:action];
}

- (void)trackExperimentStart:(NSString *)experiment group:(NSString *)group {
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionTrackExperiment
               forKey:kActionKeyName];
    [action setObject:@"ON"
               forKey:@"status"];
    [action setObject:experiment
               forKey:@"experiment"];
    [action setObject:group
               forKey:@"group"];

    [self track:action];
}

- (void)trackExperimentEnd:(NSString *)experiment {
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionTrackExperiment
               forKey:kActionKeyName];
    [action setObject:@"END"
               forKey:@"status"];
    [action setObject:experiment
               forKey:@"experiment"];

    [self track:action];
}

- (void)trackState:(NSDictionary *)state {
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionTrackState
               forKey:kActionKeyName];
    [action setObject:state
               forKey:@"state"];

    [self track:action];
}


- (void)identify:(NSString *)userId {
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionIdentify
               forKey:kActionKeyName];
    [action setObject:userId
               forKey:@"userId"];

    [self track:action];
    [self flushAndUploadAllEvents];
}

- (BOOL)verifyPaymentWithProductId:(NSString *)productId transactionId:(NSString *)transactionId receipt:(NSString *)base64EncodedReceipt privateKey:(NSString *)privateKey {
    NSString *purchase = [NSString stringWithFormat:@"{\"productId\":\"%@\", \"transactionId\":\"%@\"}",
                                                    productId, transactionId];

    NSString *salt = [Utils md5:[NSString stringWithFormat:@"123567890:%ldl", time(NULL)]];

    NSDictionary *result = [Utils sendVerifyPaymentRequest:mServerAddress
                                                     token:mToken
                                            userIdentifier:mUserID
                                                  purchase:purchase
                                                   receipt:base64EncodedReceipt
                                                      salt:salt
                                                   logging:mDebugLoggingEnabled];

    BOOL succeeded = NO;
    if ([[result objectForKey:@"status"] isEqualToString:@"valid"]) {
        NSString *signature = [Utils md5:[NSString stringWithFormat:@"%@:%@:%@", transactionId, salt, privateKey]];
        succeeded = [[result objectForKey:@"sig"] isEqualToString:signature];
    }

    return succeeded;
}

- (void)flushAndUploadAllEvents {
    dispatch_async(mWorkingQueue, ^{
        // flush and send all events
        [self flushData];
        [self closeStreams];
        [self uploadData];
    });
}

- (void)flushAllEvents {
    dispatch_async(mWorkingQueue, ^{
        [self flushData];
        [self closeStreams];
    });
}

#pragma mark - Application lifecycle

- (void)applicationDidEnterBackground {
    [mSessionData setSessionDurationCurrent:[mSessionData sessionDurationCurrent] + [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] - mStartTime] longValue]];
    // saves sleep time for calculating pause duration in future
    mStartTime = [[NSDate date] timeIntervalSince1970];
    
    [self flushData];
    [self closeStreams];
    [self uploadData];
}

- (void)applicationWillEnterForeground {
    // If application was paused more than MAX time
    if([[NSDate date] timeIntervalSinceDate:[NSDate dateWithTimeIntervalSince1970:mStartTime]] >= kSessionMaxPauseState) {
        [self startSession];
    }
    mStartTime = [[NSDate date] timeIntervalSince1970];
}

- (void)applicationWillTerminate {
    [mSessionData setSessionDurationCurrent:[mSessionData sessionDurationCurrent] + [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] - mStartTime] longValue]];
    [self flushData];
    [self closeStreams];

    if (gSharedManager == self) {
        [gSharedManager release];
        gSharedManager = nil;
    }
}

#pragma mark - Private methods

- (void)startSession {
    if(mSessionData.sessionDuration > 0)
        [self trackSession];
    long currentDuration = mSessionData.sessionDurationCurrent;
    mSessionData.sessionDuration = currentDuration;
    mSessionData.sessionDurationCurrent = 0;
}

#pragma mark - Testing methods

- (NSMutableArray *)getEventStack {
    return mEventStack;
}

- (SessionData *)sessionData {
    return mSessionData;
}

- (NSString *)instanceIdentifier {
    return [Utils instanceIdentifierForToken:mToken];
}

@end
