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

    NSMutableArray *mEventStack;
    SessionData *mSessionData;
    NSLock *mBatchFileLock;

    NSString *mServerAddress;
    NSString *mUserID;
    NSString *mDeviceKey;
    NSString *mVersion;

    NSTimeInterval mStartTime;
    
    BOOL mDebugLoggingEnabled;
}

/** An application token */
@property(nonatomic, readonly) NSString *token;

/** An unique identifier of user */
@property(nonatomic, readonly) NSString *userIdentifier;

/** Contains a set of unique identifiers specific to the app, as query string */
@property(nonatomic, readonly) NSString *deviceKey;

/** Enabling or disabling debug logging */
@property(nonatomic, assign, getter=isDebugLoggingEnabled) BOOL debugLoggingEnabled;

/**
 * Setting up the application token
 * @since in 1.10.0
 */
- (void)setupWithToken:(NSString *)token;

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
* Registering user state
*/
- (void)trackState:(NSDictionary *)state;

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
 * Flushing all events to the disk
 */
- (void)flushAllEvents;

/** Returns an unique identifier of current installation instance */
- (NSString *)instanceIdentifier;

/** Attach attributes to separate entity instead of user */
- (void)attachEntityAttributesForName:(NSString*)name value:(NSString*)value withProperies:(NSDictionary*)properties;

@end
