/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "AppMetrDelegate.h"

// pre-declare classes
@class SessionData;
@class BatchFile;
@class Preferences;

/**
 * A tracking manager
 */
@interface TrackingManager : NSObject {
    NSThread *mWorkingThread;
    NSCondition *mThreadCondition;

    // timer for
    NSTimer *mFlashDataTimer;
    NSTimer *mUploadDataTimer;
    NSTimer *mPullRemoteCommandsTimer;

    //
    volatile BOOL mRunning;
    //
    NSTimeInterval mFlushDataTimeInterval;
    NSTimeInterval mUploadDataTimeInterval;
    NSUInteger mBatchFileMaxSize;

    NSMutableArray *mEventStack;
    SessionData *mSessionData;
    BatchFile *mBatchFileStream;
    NSLock *mBatchFileLock;

    NSString *mServerAddress;
    NSString *mToken;
    NSString *mUserID;
    NSString *mVersion;
    BOOL mTrackInstallByApp;

    NSDate *mEnterBackgroundDate;

    NSMutableArray *mRemoteCommandList;
    NSMutableArray *mProcessedCommandList;
    NSString *mLastReceivedCommandID;
    volatile BOOL mPullCommands;
    id <AppMetrDelegate> mDelegate;
    NSThread *mCommandThread;
    Preferences *mPreferences;
    BOOL mDebugLoggingEnabled;
}

/** The delegate object*/
@property(assign) id delegate;

/** An application token */
@property(nonatomic, readonly) NSString *token;

/** An unique identifier of user */
@property(nonatomic, readonly) NSString *userIdentifier;

/** Enabling or disabling debug logging */
@property(nonatomic, assign, getter=isDebugLoggingEnabled) BOOL debugLoggingEnabled;

/**
 * Setting up the application token
 * @since in 1.3
 */
- (void)setupWithToken:(NSString *)token delegate:(id)delegate commandsThread:(NSThread *)thread;

/**
 * Setting up the maximum size of cache file
 */
- (void)setupSizeLimitOfCacheFile:(NSUInteger)limit;

/**
 * @deprecated in version 1.3 Use setupWithToken:delegate: instead
 * Setting up the user identifier.
 * If value not set, the unique identifier of device will be used by default.
 */
- (void)setupWithUserID:(NSString *)userID;

/**
 * Updating information about the user
 * @param properties Information about the user
 */
- (void)attachProperties:(NSDictionary *)properties;

/**
 * Registering the session at application startup
 */
- (void)trackSession;

/**
 * Registering the session at application startup with specified properties
 */
- (void)trackSessionWithProperties:(NSDictionary *)properties;

/**
 * Registering when the player receive next level.
 */
- (void)trackLevel:(int)level;

/**
 * Registering when the player receive next level.
 */
- (void)trackLevel:(int)level properties:(NSDictionary *)properties;

/**
 * Registering custom event
 */
- (void)trackEvent:(NSString *)event;

/**
 * Registering custom event with specified properties
 */
- (void)trackEvent:(NSString *)event properties:(NSDictionary *)properties;

/**
 * Registering when making a payment
 */
- (void)trackPayment:(NSDictionary *)payment;

/**
 * Registering when making a payment
 */
- (void)trackPayment:(NSDictionary *)payment properties:(NSDictionary *)properties;

/**
 * Registering state of the game
 */
- (void)trackGameState:(NSString *)state properties:(NSDictionary *)properties;

/**
 * Registering the URL of game installation
 */
- (void)trackInstallURL:(NSURL *)url;

/**
* Registering options processing
*/
- (void)trackOptions:(NSDictionary *)options forCommand:(NSString *)commandId;

/**
* Registering options processing error
*/
- (void)trackOptions:(NSDictionary *)options forCommand:(NSString *)commandId errorCode:(NSString *)code errorMessage:(NSString *)message;

/**
* Registering start of experiment
*/
- (void)trackExperimentStart:(NSString *)experiment group:(NSString *)group;

/**
* Registering end of experiment
*/
- (void)trackExperimentEnd:(NSString *)experiment;

/**
* Identify user
*/
- (void)identify:(NSString *)userId;

/**
 * Called when application goes into background mode
 */
- (void)applicationDidEnterBackground;

/**
 * Called when application exits background mode
 */
- (void)applicationWillEnterForeground;

/**
 * Called when application closes
 */
- (void)applicationWillTerminate;

/**
 * Flushing all events to the disk and uploading them to server
 */
- (void)flushAndUploadAllEvents;

/**
 * Processing queue with remote commands
 */
- (void)processRemoteCommands;

/**
 * Pull remote commands
 */
- (void)pullCommands;

/**
 * Sets the thread for executing remote commands
 */
- (void)setCommandThread:(NSThread *)thread;

/** Returns an unique identifier of current installation instance */
- (NSString *)instanceIdentifier;

@end
