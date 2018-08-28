/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import <StoreKit/StoreKit.h>

// pre-declare classes
@class SessionData;
@class BatchFile;
@class Preferences;

/**
 * A tracking manager
 */
@interface TrackingManager : NSObject {
    // flush and upload queue
    dispatch_queue_t mWorkingQueue;
    
    // timer for
    NSTimer *mFlashDataTimer;
    NSTimer *mUploadDataTimer;

    //
    NSTimeInterval mFlushDataTimeInterval;
    NSTimeInterval mUploadDataTimeInterval;
    NSUInteger mBatchFileMaxSize;

    NSMutableArray *mEventStack;
    SessionData *mSessionData;
    BatchFile *mBatchFileStream;
    NSLock *mBatchFileLock;

    NSString *mServerAddress;
    NSString *mUserID;
    NSString *mVersion;

    NSTimeInterval mStartTime;
    
    BOOL mDebugLoggingEnabled;
}

/** An application token */
@property(nonatomic, readonly) NSString *token;

/** An unique identifier of user */
@property(nonatomic, readonly) NSString *userIdentifier;

/** Enabling or disabling debug logging */
@property(nonatomic, assign, getter=isDebugLoggingEnabled) BOOL debugLoggingEnabled;

/**
 * Setting up the application token
 * @since in 1.10.0
 */
- (void)setupWithToken:(NSString *)token;

/**
 * Setting up the maximum size of cache file
 */
- (void)setupSizeLimitOfCacheFile:(NSUInteger)limit;

/**
 * If value not set, the unique identifier of device will be used by default.
 */
- (void)setupWithUserID:(NSString *)userID;

/**
 * Updating information about the user
 * @param properties Information about the user
 */
- (void)attachProperties;

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
* Registering advertising event track
*/
- (void)trackAdsEvent:(NSString *)eventName;

/**
 * Registering the URL of game installation
 */
- (void)trackInstallURL:(NSURL *)url;

/**
* Registering options processing
*/
- (void)trackOptions:(NSArray *)options forCommand:(NSString *)commandId;

/**
* Registering options processing error
*/
- (void)trackOptions:(NSArray *)options forCommand:(NSString *)commandId errorCode:(NSString *)code errorMessage:(NSString *)message;

/**
* Registering start of experiment
*/
- (void)trackExperimentStart:(NSString *)experiment group:(NSString *)group;

/**
* Registering end of experiment
*/
- (void)trackExperimentEnd:(NSString *)experiment;

/**
* Registering user state
*/
- (void)trackState:(NSDictionary *)state;

/**
* Identify user
*/
- (void)identify:(NSString *)userId;

/**
* Verify payment
*/
- (BOOL)verifyPaymentWithProductId:(NSString *)productId transactionId:(NSString *)transactionId receipt:(NSString *)base64EncodedReceipt privateKey:(NSString *)privateKey;

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
 * Flushing all events to the disk
 */
- (void)flushAllEvents;

/** Returns an unique identifier of current installation instance */
- (NSString *)instanceIdentifier;

@end
