/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "TrackingManager.h"

/**
 * Main library class
 */
@interface AppMetr : TrackingManager

/**
 * Returns the singleton library instance
 */
+ (AppMetr *)sharedInstance;

/**
 * Setting up the application token.
 */
+ (void)setupWithToken:(NSString *)token;

/**
 * Setting up the application token and set the current thread for processing remote command.
 */
+ (void)setupWithToken:(NSString *)token delegate:(id)delegate;

/**
 * Setting up the application token
 */
+ (void)setupWithToken:(NSString *)token delegate:(id)delegate commandsThread:(NSThread *)thread;

/**
 * Setting up the maximum size of cache file
 */
+ (void)setupSizeLimitOfCacheFile:(NSUInteger)limit;

/**
 * Setting up the user identifier.
 * If value not set, the unique identifier of device will be used by default.
 */
+ (void)setupWithUserID:(NSString *)userID;

/**
 * Updating information about the user
 * @param properties Information about the user
 */
+ (void)attachProperties:(NSDictionary *)properties;

/**
 * Registering the session at application startup
 */
+ (void)trackSession;

/**
 * Registering the session at application startup with specified properties
 */
+ (void)trackSessionWithProperties:(NSDictionary *)properties;

/**
 * Registering when the player receive next level.
 */
+ (void)trackLevel:(int)level;

/**
 * Registering when the player receive next level.
 */
+ (void)trackLevel:(int)level properties:(NSDictionary *)properties;

/**
 * Registering custom event
 */
+ (void)trackEvent:(NSString *)event;

/**
 * Registering custom event with specified value and properties
 */
+ (void)trackEvent:(NSString *)event properties:(NSDictionary *)properties;

/**
 * Registering when making a payment
 */
+ (void)trackPayment:(NSDictionary *)payment;

/**
 * Registering when making a payment
 */
+ (void)trackPayment:(NSDictionary *)payment properties:(NSDictionary *)properties;

/**
 * Registering state of the game
 */
+ (void)trackGameState:(NSString *)state properties:(NSDictionary *)properties;

/**
 * Registering the URL of game installation
 */
+ (void)trackInstallURL:(NSURL *)url;

/**
* Registering options processing
*/
+ (void)trackOptions:(NSDictionary *)options forCommand:(NSString *)commandId;

/**
* Registering options processing error
*/
+ (void)trackOptions:(NSDictionary *)options forCommand:(NSString *)commandId errorCode:(NSString *)code errorMessage:(NSString *)message;

/**
* Registering start of experiment
*/
+ (void)trackExperimentStart:(NSString *)experiment group:(NSString *)group;

/**
* Registering end of experiment
*/
+ (void)trackExperimentEnd:(NSString *)experiment;

/**
 * Pull remote commands
 */
+ (void)pullCommands;

/**
* Force flush events on server
*/
+ (void)flush;

/**
 * Retrieves the user unique identifier used by this library
 */
+ (NSString *)userIdentifier;

/**
 * Sets the thread for executing remote commands
 */
+ (void)setCommandThread:(NSThread *)thread;

/** Enabling or disabling debug logging */
+ (void)setDebugLoggingEnabled:(BOOL)debugLoggingEnabled;

/** Returns whether debug logging is enabled or not */
+ (BOOL)isDebugLoggingEnabled;

/** Returns an unique identifier of current installation instance */
+ (NSString *)instanceIdentifier;

@end
