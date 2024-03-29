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

/// track methods
- (void)track:(NSDictionary *)trackProperties;

@end


#pragma mark - Class implementation

@implementation TrackingManager

@synthesize token = mToken;
@synthesize userIdentifier = mUserID;
@synthesize deviceKey = mDeviceKey;
@synthesize debugLoggingEnabled = mDebugLoggingEnabled;
@synthesize uploadCacheTask = mUploadCacheTask;

#pragma mark - Initializing

- (id)init {
    self = [super init];
    if (self) {
        mFlushDataTimeInterval = kDefaultFlashDataDelay;
        mUploadDataTimeInterval = MAX(kDefaultFlashDataDelay, kDefaultUploadDataDelay);

        //initialize main stack
        mEventStack = [[NSMutableArray alloc] init];

        // restore data from previous sessions
        mSessionData = [[SessionData alloc] init];

        mBatchFileLock = [[NSLock alloc] init];

        [self setupWithUserID:[Utils uniqueIdentifier]];

        // retrieve version string
        [self readSettingsFromPInfoFile];
        
        mUploadCacheTask = [[UploadCacheTask alloc] initWithSession:mSessionData];
        mUploadCacheTask.logging = mDebugLoggingEnabled;

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

    @synchronized (mEventStack) {
        [mEventStack release];
    }

    [mSessionData release];
    [mBatchFileLock release];
    mUploadCacheTask = nil;
    

    [mToken release];
    [mUserID release];
    [mDeviceKey release];
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
        mToken = nil;
    }
    
    if (token != nil && ![token isKindOfClass:[NSNull class]]) {
        mToken = [token copy];
        
        // save device identifires
        if(mDeviceKey != nil)
            [mDeviceKey release];
        mDeviceKey = [[Utils deviceKeyForToken:mToken] retain];
    }
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
    }
    
    if(data)
        data = [Utils compressData:data];

    return data;
}

- (void)flushData {
    [self checkConversionValue];
    NSData *chunk = nil;
    @synchronized (mEventStack) {
        if ([mEventStack count]) {
            chunk = [self createBatchData];
        }
    }

    if (chunk && chunk.length > 0) {
        // lock mutex
        @synchronized (mBatchFileLock) {
            NSUInteger fileId = [mSessionData nextFileIndex];
            BatchFile* batchFileStream = [[BatchFile alloc] initWithIndex:fileId];
            NSError* error = nil;
            if(batchFileStream != nil) {
                [batchFileStream addChunkData:chunk error:&error];
                [batchFileStream close];
                if(error == nil) {
                    @synchronized (mSessionData) {
                        [mSessionData.fileList addObject:batchFileStream.fullPath];
                        [mSessionData saveFileList];
                    }
                }
                [batchFileStream release];
            } else {
                error = [NSError errorWithDomain:@"BatchFile" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Failed to open output stream"}];
            }
            if(error != nil) {
                @synchronized (mSessionData) {
                    if(mSessionData.uploadList.count < kUploadInMemoryCount) {
                        [mSessionData.uploadList addObject:chunk];
                        [self trackError:error];
                    }
                    else
                        NSLog(@"Skip uploading file %lu due to in-memory size limit", (unsigned long)fileId);
                }
                
            }
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
    mUploadCacheTask.logging = mDebugLoggingEnabled;
    [mUploadCacheTask uploadWithAddress:requestAddress];
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

#pragma mark - track methods

- (void)track:(NSDictionary *)trackProperties {
    NSMutableDictionary *updatedTrackProperties = [trackProperties mutableCopy];
    NSMutableDictionary* properties = [NSMutableDictionary dictionaryWithDictionary:[updatedTrackProperties objectForKey:@"properties"]];
    id timestamp = [properties objectForKey:kAppmetrPropertyTimestamp];
    if(timestamp != nil) {
        if([timestamp isKindOfClass:[NSNumber class]]) {
            [updatedTrackProperties setObject:(NSNumber*)timestamp forKey:kAppmetrPropertyUsertime];
        } else if([timestamp isKindOfClass:[NSDate class]]) {
            timestamp = [NSNumber numberWithUnsignedLongLong:(unsigned long long) ([(NSDate*)timestamp timeIntervalSince1970] * 1000.0)];
            [updatedTrackProperties setObject:timestamp forKey:kAppmetrPropertyUsertime];
        }
        [properties removeObjectForKey:kAppmetrPropertyTimestamp];
    }
    NSNumber* currentTimestamp = [NSNumber numberWithUnsignedLongLong:[Utils timestamp]];
    [updatedTrackProperties setObject:currentTimestamp forKey:kAppmetrPropertyTimestamp];
    if(properties.count > 0)
        [updatedTrackProperties setObject:properties forKey:@"properties"];
    else
        [updatedTrackProperties removeObjectForKey:@"properties"];
    NSString* userIdentity = mSessionData.userIdentity;
    if(userIdentity != nil && userIdentity.length > 0)
        [updatedTrackProperties setObject:userIdentity forKey:@"serverUserId"];
    [Utils convertDateToLong:updatedTrackProperties];

    @synchronized (mEventStack) {
        [mEventStack addObject:updatedTrackProperties];
    }

    [updatedTrackProperties release];
}

- (void)attachProperties {
    [self attachProperties:nil];
}

- (void)attachProperties:(NSDictionary *)properties {
    NSMutableDictionary *userProperties = [self fillProperties:properties];
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionAttachProperties forKey:kActionKeyName];
    [action setObject:userProperties forKey:kActionPropertiesKeyName];
    [self track:action];
}

//Track session
- (void)trackSession {
    [self trackSessionWithProperties:nil];
}

- (void)trackSessionWithProperties:(NSDictionary *)properties {
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionTrackSession
               forKey:kActionKeyName];
    
    NSMutableDictionary *mutableProperties = [self fillProperties:properties];
    NSNumber* totalDisk = nil;
    NSNumber* availDisk = nil;
    [Utils getDiskSpaceAvailable:&availDisk total:&totalDisk];
    [mutableProperties setValue:totalDisk forKey:@"$diskTotal"];
    [mutableProperties setValue:availDisk forKey:@"$diskFree"];
    
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
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys:
                                             [NSNumber numberWithInt:level], kActionLevelKeyName, nil];
    [self attachProperties:properties];
}

- (void)trackLevel:(int)level properties:(NSDictionary *)properties {
    NSMutableDictionary *mutableProperties = properties == nil ? [NSMutableDictionary dictionary] : [properties mutableCopy];
    [mutableProperties setObject:[NSNumber numberWithInt:level] forKey:kActionLevelKeyName];
    [self attachProperties:mutableProperties];
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
    if(properties != nil) {
        [action setObject:properties
                   forKey:@"properties"];
    }
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

- (void)trackState:(NSDictionary *)state {
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionTrackState
               forKey:kActionKeyName];
    [action setObject:state
               forKey:@"state"];

    [self track:action];
}

- (void)trackError:(NSError*)error {
    NSString* message = [NSString stringWithFormat:@"%@: %@", NSStringFromClass(error.class), error.localizedDescription];
    [self trackEvent:@"appmetr_error" properties:@{@"message": message}];
    NSData *chunk = nil;
    @synchronized (mEventStack) {
        if ([mEventStack count]) {
            chunk = [self createBatchData];
        }
    }
    if (chunk && chunk.length > 0) {
        @synchronized (mSessionData) {
            if(mSessionData.uploadList.count < kUploadInMemoryCount)
                [mSessionData.uploadList addObject:chunk];
            else
                NSLog(@"Skip uploading error batch due to in-memory size limit");
        }
    }
}

- (void)identify:(NSString *)userId {
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionIdentify
               forKey:kActionKeyName];
    [action setObject:userId
               forKey:@"userId"];

    [self track:action];
    [self flushAndUploadAllEvents];
    mSessionData.userIdentity = userId;
}

- (void)attachEntityAttributesForName:(NSString*)name value:(NSString*)value withProperies:(NSDictionary*)properties {
    if(name == nil || name.length == 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"entity name is null or empty" userInfo:nil];
    }
    if(value == nil || value.length == 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"entity value is null or empty" userInfo:nil];
    }
    if(properties == nil || properties.count == 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"properties is null or empty" userInfo:nil];
    }
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionAttachEntityAttributes forKey:kActionKeyName];
    [action setObject:name forKey:kActionEntityNameKey];
    [action setObject:value forKey:kActionEntityValueKey];
    [action setObject:properties forKey:kActionPropertiesKeyName];
    [self track:action];
}

- (void)flushAndUploadAllEvents {
    dispatch_async(mWorkingQueue, ^{
        // flush and send all events
        [self flushData];
        [self uploadData];
    });
}

- (void)flushAllEvents {
    dispatch_async(mWorkingQueue, ^{
        [self flushData];
    });
}

#pragma mark - Application lifecycle

- (void)applicationDidEnterBackground {
    [mSessionData setSessionDurationCurrent:[mSessionData sessionDurationCurrent] + [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] - mStartTime] longValue]];
    // saves sleep time for calculating pause duration in future
    mStartTime = [[NSDate date] timeIntervalSince1970];
    
    [self flushData];
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

- (NSMutableDictionary*)fillProperties:(NSDictionary*)properties
{
    NSMutableDictionary *mutableProperties = properties != nil ? [properties mutableCopy] : [NSMutableDictionary dictionary];
    [mutableProperties setObject:mVersion forKey:kActionVersionKeyName];

    if ([mutableProperties objectForKey:kActionCountryKeyName] == nil) {
        NSString *country = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        if (country) {
            [mutableProperties setObject:country forKey:kActionCountryKeyName];
        }
    }
    
    if ([mutableProperties objectForKey:kActionLanguageKeyName] == nil || [mutableProperties objectForKey:kActionLocaleKeyName] == nil) {
        NSString* language = [NSLocale preferredLanguages].count > 0 ?[[NSLocale preferredLanguages] objectAtIndex:0] : nil;
        NSString* locale = [[NSLocale currentLocale] localeIdentifier];
        if(language) {
            locale = [language stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
            language = [[NSLocale componentsFromLocaleIdentifier:language] objectForKey:NSLocaleLanguageCode];
        }
        if (language && [mutableProperties objectForKey:kActionLanguageKeyName] == nil) {
            [mutableProperties setObject:language forKey:kActionLanguageKeyName];
        }
        if(locale && [mutableProperties objectForKey:kActionLocaleKeyName] == nil) {
            [mutableProperties setObject:locale forKey:kActionLocaleKeyName];
        }
    }
    return mutableProperties;
}

- (void)checkConversionValue
{
    if (@available(iOS 14.0, *)) {
        id cachedReportData = [[NSUserDefaults standardUserDefaults] objectForKey:@"com.facebook.sdk:FBSDKSKAdNetworkReporter"];
        if(cachedReportData == nil || ![cachedReportData isKindOfClass:[NSData class]]) {
            NSLog(@"Appmetr can't find Facebook cached SKAdNetwork report data");
            return;
        }
        NSDictionary<NSString*, id> *data = [Utils convertObjectToDict:[NSKeyedUnarchiver unarchiveObjectWithData:cachedReportData]];
        if(data == nil) {
            NSLog(@"Appmetr can't unarchive Facebook cached SKAdNetwork report data");
            return;
        }
        NSInteger conversionValue = [Utils convertObjectToInt:data[@"conversion_value"]];;
        if(conversionValue == 0 || conversionValue == mSessionData.conversionValue) return;
        [self trackEvent:@"SKAdNetwork" properties:@{@"conversion_value":[NSNumber numberWithInteger:conversionValue]}];
        mSessionData.conversionValue = conversionValue;
    }
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
