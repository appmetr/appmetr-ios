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
#import "RemoteCommand.h"
#import "RemoteCommandPacket.h"
#import "AppMetrUnsatisfiedConditionException.h"
#import "AppMetrInvalidCommandException.h"
#import "ServerError.h"
#import "Preferences.h"


// Global variables
extern TrackingManager *gSharedManager;

#pragma mark - Private category

@interface TrackingManager ()

@property(retain) NSString *lastReceivedCommandID;

- (void)startBackgroundThread;

- (void)stopBackgroundThread;

- (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval selector:(SEL)selector;

- (void)createTimers;

- (void)destroyTimers;

- (void)runFromThread:(id)object;

- (NSData *)createBatchData;

// flush events to disk
- (void)flushData;

- (void)flushTimer:(NSTimer *)timer;

// send prepared files to server
- (void)uploadTimer:(NSTimer *)timer;

- (void)closeStreams;

/// track methods
- (void)track:(NSDictionary *)trackProperties;

- (void)trackInstallBroadcast;

- (void)trackInstallBroadcast:(NSDictionary *)properties;

- (void)trackAppStart;


- (void)flushAndUploadAllEventsImpl;

- (void)pullCommands;

- (void)sentQueryRemoteCommandList;

- (RemoteCommand *)nextCommand;

- (void)setCommandThread:(NSThread *)thread;

@end


#pragma mark - Class implementation

@implementation TrackingManager

@synthesize lastReceivedCommandID = mLastReceivedCommandID;

@synthesize delegate = mDelegate;
@synthesize token = mToken;
@synthesize userIdentifier = mUserID;
@synthesize debugLoggingEnabled = mDebugLoggingEnabled;

#pragma mark - Initializing

- (id)init {
    self = [super init];
    if (self) {
        mThreadCondition = [[NSCondition alloc] init];

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

        mPreferences = [[Preferences alloc] init];
        self.lastReceivedCommandID = mPreferences.lastProcessedCommandIdentifier;

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

        mRemoteCommandList = [[NSMutableArray alloc] init];
        NSArray *savedCommandList = [[NSUserDefaults standardUserDefaults] objectForKey:kPreferencesProcessedCommandsKeyName];
        mProcessedCommandList = (savedCommandList ? [savedCommandList mutableCopy] : [NSMutableArray new]);

        // starting background thread
        [self startBackgroundThread];

        mStartTime = [[NSDate date] timeIntervalSince1970];
    }

    return self;
}

#pragma mark - Destructor

- (void)dealloc {
    [self stopBackgroundThread];
    [self flushData];
    [self closeStreams];

    [mThreadCondition release];

    [mFlashDataTimer release];
    [mUploadDataTimer release];
    [mPullRemoteCommandsTimer release];

    @synchronized (mEventStack) {
        [mEventStack release];
    }

    [mSessionData release];
    [mBatchFileStream release];
    [mBatchFileLock release];

    [mToken release];
    [mUserID release];
    [mVersion release];

    @synchronized (self) {
        [mCommandThread release];
    }

    @synchronized (mRemoteCommandList) {
        [mRemoteCommandList release];
    }

    @synchronized (mProcessedCommandList) {
        [mProcessedCommandList release];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [mPreferences release];

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

    mTrackInstallByApp = YES;
    if ([info objectForKey:@"trackInstallByApp"] != nil) {
        mTrackInstallByApp = [[info objectForKey:@"trackInstallByApp"] boolValue];
    }
}

#pragma mark - Setting up

- (void)setupWithToken:(NSString *)token delegate:(id)delegate commandsThread:(NSThread *)thread {
    if (!mToken) {
        if (token.length > kTokenSizeLimit) {
            [NSException raise:NSInvalidArgumentException
                        format:@"Invalid token. length should be no more than %u", kTokenSizeLimit];
        }
        [mToken release];
        mToken = [token copy];
    }

    self.delegate = delegate;
    [self setCommandThread:thread];
}

- (void)setupSizeLimitOfCacheFile:(NSUInteger)limit {
    mBatchFileMaxSize = limit;
}

- (void)setupWithUserID:(NSString *)userID {
    [mUserID release];
    mUserID = [userID retain];
}

#pragma mark - Thread methods

- (void)startBackgroundThread {
    // lock thread mutex
    [mThreadCondition lock];
    if (!mRunning && !mWorkingThread) {
        mRunning = YES;

        // create and start thread
        mWorkingThread = [[NSThread alloc] initWithTarget:self selector:@selector(runFromThread:) object:self];
        assert(mWorkingThread);
        [mWorkingThread start];

        // wait while thread start
        [mThreadCondition wait];
    }
    [mThreadCondition unlock];

}

- (void)stopBackgroundThread {
    if (mWorkingThread) {
        mRunning = NO;
        [mWorkingThread cancel];
        while ([mWorkingThread isExecuting]) {
            // just a wait
            sleep(1);
        }

        [mWorkingThread release], mWorkingThread = nil;
    }
}

- (void)runFromThread:(id)object {
    // synchronize with main thread
    [mThreadCondition lock];
    // unlock main thread
    [mThreadCondition broadcast];
    [mThreadCondition unlock];

    // first send app start event
    [self trackAppStart];

    [self createTimers];

    while (mRunning && ![mWorkingThread isCancelled]) {
        if (mPullCommands) {
            mPullCommands = NO;
            [self sentQueryRemoteCommandList];
        }
        // call run every second
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    // stop timers
    [self destroyTimers];

    // save all events
    [self flushData];
    [self closeStreams];
#ifdef DEBUG
    NSLog(@"AppMetr thread closed.");
#endif
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
    // schedule timer for flushing events to files
    mFlashDataTimer = [[self scheduledTimerWithTimeInterval:mFlushDataTimeInterval
                                                   selector:@selector(flushTimer:)]
            retain];

    // schedule timer for sending packets to server
    mUploadDataTimer = [[self scheduledTimerWithTimeInterval:mUploadDataTimeInterval
                                                    selector:@selector(uploadTimer:)]
            retain];

    // create timer for remote commands
    mPullRemoteCommandsTimer = [[self scheduledTimerWithTimeInterval:kPullRemoteCommandsDelay
                                                            selector:@selector(sentQueryRemoteCommandList)]
            retain];
}

- (void)destroyTimers {
    [mFlashDataTimer invalidate];
    [mFlashDataTimer release], mFlashDataTimer = nil;

    [mUploadDataTimer invalidate];
    [mUploadDataTimer release], mUploadDataTimer = nil;

    [mPullRemoteCommandsTimer invalidate];
    [mPullRemoteCommandsTimer release], mPullRemoteCommandsTimer = nil;
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
    NSData *data = [[CJSONSerializer serializer] serializeDictionary:batches
                                                               error:&serializeError];
    if (serializeError) {
        NSLog(@"JSON serializer error: %@", serializeError.description);
        [NSException raise:NSGenericException
                    format:@"%@", serializeError.description];
    }

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

- (NSUInteger)uploadData {
    NSUInteger ret = 0;
    NSArray *fileList;
    @synchronized (mSessionData) {
        fileList = [mSessionData.fileList copy];
    }

    for (NSString *fileName in fileList) {
        NSError *error = nil;
        if (mDebugLoggingEnabled) {
            NSLog(@"uploadData: Batches: %@", [NSString stringWithContentsOfFile:fileName
                                                                        encoding:NSUTF8StringEncoding
                                                                           error:&error]);
        }

        NSData *content = [NSData dataWithContentsOfFile:fileName options:0 error:&error];
        BOOL result = YES;
        if (!error) {
            result = [Utils sendRequest:mServerAddress
                                  token:mToken
                         userIdentifier:mUserID
                                batches:[Utils compressData:content]
                                logging:mDebugLoggingEnabled];
        }
        else {
            NSLog(@"File error: %@", error.localizedDescription);
        }

        if (result) {
            @synchronized (mSessionData) {
                [mSessionData.fileList removeObject:fileName];
                ret++;
            }

            NSError *fileError = nil;
            [[NSFileManager defaultManager] removeItemAtPath:fileName error:&fileError];
            if (fileError) {
                NSLog(@"Failed to delete file. Reason: %@", fileError.localizedDescription);
            }
        }
        else {
            NSLog(@"Server error, break.");
            break;
        }
    }

    if (ret) {
        @synchronized (mSessionData) {
            [mSessionData saveFileList];
        }
    }

    [fileList release];

    return ret;
}

- (void)flushTimer:(NSTimer *)timer {
    @try {
        [self flushData];
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to flush data. Reason: %@", [exception description]);
    }
}

- (void)uploadTimer:(NSTimer *)timer {
    @try {
        [self uploadData];
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to upload data. Reason: %@", [exception description]);
    }
//	[mBatchSender sendAllToServer:mServerUrl];
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

    [updatedTrackProperties setObject:[NSNumber numberWithUnsignedLongLong:[Utils timestamp]]
                               forKey:@"timestamp"];

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

    if (properties == nil) {
        properties = [NSMutableDictionary dictionary];
    }

    if (!mSessionData.isFirstTrackSessionSent) {    //Set -1 for first session
        [properties setValue:[NSNumber numberWithLong:-1] forKey:kSessionDurationKeyName];
    } else {
        [properties setValue:[NSNumber numberWithLong:[mSessionData sessionDuration]] forKey:kSessionDurationKeyName];
    }
    [mSessionData setSessionDuration:0];

    [action setObject:properties
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

- (void)trackGameState:(NSString *)state properties:(NSDictionary *)properties {
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionTrackGameState
               forKey:kActionKeyName];
    [action setObject:state
               forKey:@"state"];
    [action setObject:properties
               forKey:kActionPropertiesKeyName];

    [self track:action];
}

//Track install broadcast
- (void)trackInstallBroadcast {
    [self trackInstallBroadcast:nil];
}

- (void)trackInstallBroadcast:(NSDictionary *)properties {
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionTrackInstall
               forKey:kActionKeyName];

    if (properties != nil) {
        [action setObject:properties
                   forKey:kActionPropertiesKeyName];
    }

    NSString *country = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    if (country) {
        [action setObject:country
                   forKey:kActionCountryKeyName];
    }

    [self track:action];
    [self flushAndUploadAllEventsImpl];
}

- (void)trackAppStart {
    // Skip track session and install if it doesn't set in plist file or set to true
    if (mTrackInstallByApp) {
        return;
    }

    NSUInteger batchIndex = 0;
    @synchronized (mSessionData) {
        batchIndex = mSessionData.batchIndex;
    }

    if (!batchIndex) {
        [self trackInstallBroadcast];
    }
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

        [self flushAndUploadAllEventsImpl];
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

- (void)identify:(NSString *)userId {
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionIdentify
               forKey:kActionKeyName];
    [action setObject:userId
               forKey:@"userId"];

    [self track:action];
}

- (BOOL)verifyPayment:(SKPaymentTransaction *)transaction privateKey:(NSString *)privateKey {
    NSString *purchase = [NSString stringWithFormat:@"{\"productId\":\"%@\", \"transactionId\":\"%@\"}",
                                                    transaction.payment.productIdentifier,
                                                    transaction.transactionIdentifier];
    NSString *receipt = [AMBase64Util encode:[transaction transactionReceipt]];
    NSString *salt = [Utils md5:[NSString stringWithFormat:@"123567890:%ul", (NSUInteger) time(NULL)]];

    NSDictionary *result = [Utils sendVerifyPaymentRequest:mServerAddress
                                                     token:mToken
                                            userIdentifier:mUserID
                                                  purchase:purchase
                                                   receipt:receipt
                                                      salt:salt
                                                   logging:mDebugLoggingEnabled];

    BOOL succeeded = NO;
    if ([[result objectForKey:@"status"] isEqualToString:@"valid"]) {
        NSString *signature = [Utils md5:[NSString stringWithFormat:@"%@:%@:%@", transaction.transactionIdentifier, salt, privateKey]];
        succeeded = [[result objectForKey:@"sig"] isEqualToString:signature];
    }

    return succeeded;
}

- (void)trackCommand:(NSString *)commandID status:(NSString *)status properties:(NSDictionary *)properties; {
    NSMutableDictionary *action = (properties ? [NSMutableDictionary dictionaryWithDictionary: properties] : [NSMutableDictionary dictionary]);
    [action setObject:kActionTrackCommand
               forKey:kActionKeyName];
    [action setObject:commandID
               forKey:@"commandId"];
    [action setObject:status
               forKey:@"status"];
    [self track:action];
}

- (void)trackCommand:(NSString *)commandID {
    [self trackCommand:commandID status:@"success" properties:nil];
}

- (void)trackCommand:(NSString *)commandID skipReason:(NSString *)reason {
    [self trackCommand:commandID
                status:@"skip"
            properties:[NSMutableDictionary dictionaryWithObject:reason forKey:@"reason"]];
}

- (void)trackCommand:(NSString *)commandID exception:(NSException *)exception {
    NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"clientError", @"errorCode",
                                                                                        [exception description], @"errorDescription", nil];

    NSMutableString *backTrace = [NSMutableString string];
    for (NSString *stackItem in exception.callStackSymbols) {
        [backTrace appendFormat:@"%@\n", stackItem];
    }

    NSString *decodedData = [AMBase64Util encode:[backTrace dataUsingEncoding:NSUTF8StringEncoding]];
    [properties setObject:decodedData forKey:@"backtrace"];

    [self trackCommand:commandID
                status:@"fail"
            properties:properties];
}

- (void)trackCommandBatchWithLastCommandID:(NSString *)lastCommandID
                                     error:(NSString *)errorName
                               description:(NSString *)errorDescription {
    NSMutableDictionary *action = [NSMutableDictionary dictionary];
    [action setObject:kActionTrackCommandBatch forKey:kActionKeyName];
    if (lastCommandID) {
        [action setObject:lastCommandID forKey:@"lastCommandId"];
    }
    [action setObject:@"fail" forKey:@"status"];
    [action setObject:errorName forKey:@"error"];
    [action setObject:errorDescription forKey:@"errorDescription"];

    [self track:action];
}

- (void)flushAndUploadAllEvents {
    if (mWorkingThread) {
        [self performSelector:@selector(flushAndUploadAllEventsImpl)
                     onThread:mWorkingThread
                   withObject:nil waitUntilDone:NO];
    }
}

- (void)flushAndUploadAllEventsImpl {
    // flush and send all events
    [self flushData];
    [self closeStreams];
    [self uploadData];
}

#pragma mark - Application lifecycle

- (void)applicationDidEnterBackground {
    [mSessionData setSessionDuration:[mSessionData sessionDuration] + [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] - mStartTime] longValue]];

// 	do not stop the thread to avoid error:0x8badf00d aka "bad food"
//	[self stopBackgroundThread];
    [self flushData];
    [self closeStreams];
}

- (void)applicationWillEnterForeground {
    [self startBackgroundThread];

    mStartTime = [[NSDate date] timeIntervalSince1970];
}

- (void)applicationWillTerminate {
    [mSessionData setSessionDuration:[mSessionData sessionDuration] + [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] - mStartTime] longValue]];

    [self stopBackgroundThread];
    [self flushData];
    [self closeStreams];

    if (gSharedManager == self) {
        [gSharedManager release];
        gSharedManager = nil;
    }
}

#pragma mark - Private methods

- (void)addRemoteCommand:(RemoteCommand *)command {
    @synchronized (mRemoteCommandList) {
        [mRemoteCommandList addObject:command];
    }
}

- (BOOL)hasProcessedCommandWithID:(NSString *)commandID {
    @synchronized (mProcessedCommandList) {
        return ([mProcessedCommandList indexOfObject:commandID] != NSNotFound);
    }
}

- (void)setProcessedCommandWithID:(NSString *)commandID {
    @synchronized (mProcessedCommandList) {
        if (![self hasProcessedCommandWithID:commandID]) {
            [mProcessedCommandList addObject:commandID];

            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:mProcessedCommandList forKey:kPreferencesProcessedCommandsKeyName];
            [defaults synchronize];
        }
    }
}

- (void)processPacket:(RemoteCommandPacket *)packet {
    BOOL res = NO;
    for (RemoteCommand *command in packet.commands) {
        [self addRemoteCommand:command];
        res = true;
        self.lastReceivedCommandID = command.uniqueIdentifier;
    }

    @synchronized (self) {
        if (res && mCommandThread) {
            [self performSelector:@selector(processRemoteCommands)
                         onThread:mCommandThread
                       withObject:nil waitUntilDone:NO];
        }
    }
}

- (void)sentQueryRemoteCommandList {
    @try {
        NSDictionary *response = [Utils sendQueryRemoteCommand:mServerAddress
                                                         token:mToken
                                                userIdentifier:mUserID
                                         lastCommandIdentifier:mLastReceivedCommandID
                                                       logging:mDebugLoggingEnabled];

        if ([[response objectForKey:@"status"] isEqualToString:@"OK"]) {
            RemoteCommandPacket *packet = [RemoteCommandPacket packetWithSerializedObject:response andDelegate:self];
            [self processPacket:packet];

            if (packet.commands.count && !packet.isLastCommandsBatch) {
                [self sentQueryRemoteCommandList];
            }
        }
        else {
            NSLog(@"server.getCommands failed, received: %@", response);
        }
    }
    @catch (ServerError *exception) {
        NSLog(@"getCommand failed with server error %@", exception);
    }
    @catch (NSException *exception) {
        NSLog(@"getCommand failed %@", exception);
        [self trackCommandBatchWithLastCommandID:mLastReceivedCommandID
                                           error:exception.name
                                     description:exception.description];
    }
}

- (void)pullCommands {
    mPullCommands = YES;
}

- (RemoteCommand *)nextCommand {
    RemoteCommand *ret = nil;
    @synchronized (mRemoteCommandList) {
        if ([mRemoteCommandList count]) {
            ret = [[mRemoteCommandList objectAtIndex:0] retain];
            [mRemoteCommandList removeObjectAtIndex:0];
        }
    }
    return [ret autorelease];
}

- (void)setCommandThread:(NSThread *)thread {
    @synchronized (self) {
        NSThread *tmpValue = mCommandThread;
        mCommandThread = [thread retain];
        [tmpValue release];
    }
}

#pragma mark - Remote commands

- (void)processRemoteCommands {
    id <AppMetrDelegate> delegate = [self.delegate retain];

    SEL executeCommandSelector = @selector(executeCommand:);
    bool hasSelector = [delegate respondsToSelector:executeCommandSelector];
    if (delegate && hasSelector) {
        NSDate *now = [NSDate date];
        RemoteCommand *command;
        while ((command = [self nextCommand])) {
            @try {
                if ([self hasProcessedCommandWithID:command.uniqueIdentifier]) {
                    [self trackCommand:command.uniqueIdentifier skipReason:@"duplicateId"];
                }
                else if ([now compare:command.validTo] == NSOrderedDescending) {
                    [self trackCommand:command.uniqueIdentifier skipReason:@"validTo"];
                }
                else {
                    [self setProcessedCommandWithID:command.uniqueIdentifier];

                    NSLog(@"Processing command id: %@", command.uniqueIdentifier);
                    if (hasSelector) {
                        [delegate performSelector:executeCommandSelector
                                       withObject:command.properties];
                    }

                    [self trackCommand:command.uniqueIdentifier];
                }
            }
            @catch (AppMetrInvalidCommandException *exception) {
                NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"invalidFormat", @"errorCode",
                        [exception description], @"errorDescription", nil];

                [self trackCommand:command.uniqueIdentifier status:@"fail" properties:properties];
            }
            @catch (AppMetrUnsatisfiedConditionException *exception) {

                NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        [exception description], @"reason", nil];

                [self trackCommand:command.uniqueIdentifier status:@"skip" properties:properties];
            }
            @catch (NSException *exception) {
                NSLog(@"Failed to execute remote command id: %@, reason: %@", command.uniqueIdentifier, exception);
                [self trackCommand:command.uniqueIdentifier exception:exception];
            }

            mPreferences.lastProcessedCommandIdentifier = command.uniqueIdentifier;
        }
    }
    [delegate release];
}

#pragma mark - RemoteCommandPacketDelegate

- (BOOL)remoteCommandParsingError:(NSException *)exception {
    [self trackCommand:mLastReceivedCommandID exception:exception];

    return YES;
}

#pragma mark - Testing methods

- (NSMutableArray *)getEventStack {
    return mEventStack;
}

- (SessionData *)sessionData {
    return mSessionData;
}

- (NSMutableArray *)getRemoteCommandList {
    return mRemoteCommandList;
}

- (NSMutableArray *)getProcessedCommandList {
    return mProcessedCommandList;
}

- (NSString *)instanceIdentifier {
    return [Utils instanceIdentifierForToken:mToken];
}

@end
