/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import <StoreKit/StoreKit.h>

/**
 * Public constants
 */
extern NSString *const kAppmetrPropertyTimestamp;

/**
 * Main library class
 */
@interface AppMetr : NSObject

/**
 * Setting up the application token.
 */
+ (void)setupWithToken:(NSString *)token;

/**
 * Updating information about the user
 */
+ (void)attachProperties;

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
* Registering advertising event track
*/
+ (void)trackAdsEvent:(NSString *)eventName;

/**
 * Registering the URL of game installation
 */
+ (void)trackInstallURL:(NSURL *)url;

/**
* Registering options processing
*/
+ (void)trackOptions:(NSArray *)options forCommand:(NSString *)commandId;

/**
* Registering options processing error
*/
+ (void)trackOptions:(NSArray *)options forCommand:(NSString *)commandId errorCode:(NSString *)code errorMessage:(NSString *)message;

/**
* Registering start of experiment
*/
+ (void)trackExperimentStart:(NSString *)experiment group:(NSString *)group;

/**
* Registering end of experiment
*/
+ (void)trackExperimentEnd:(NSString *)experiment;

/**
* Registering user state
*/
+ (void)trackState:(NSDictionary *)state;

/**
* Identify user
*/
+ (void)identify:(NSString *)userId;

/**
* Verify payment
*
* @param transaction - SKPaymentTransaction object
* @param privateKey - set in deploy setting on appmetr server
* @return YES - if payment is valid, and NO otherwise
*/
+ (BOOL)verifyPayment:(SKPaymentTransaction *)transaction privateKey:(NSString *)privateKey;

/**
* Verify payment
*
* @param productId - Product identifier
* @param transactionId - Transaction identifier
* @param receipt - Base64 encoded transaction receipt
* @param privateKey - set in deploy setting on appmetr server
* @return YES - if payment is valid, and NO otherwise
*/
+ (BOOL)verifyPaymentWithProductId:(NSString *)productId transactionId:(NSString *)transactionId receipt:(NSString *)base64EncodedReceipt privateKey:(NSString *)privateKey;

/**
* Force flush events on server
*/
+ (void)flush;

/**
 * Force flush events to the disk
 */
+ (void)flushLocal;

/** Enabling or disabling debug logging */
+ (void)setDebugLoggingEnabled:(BOOL)debugLoggingEnabled;

/** Returns whether debug logging is enabled or not */
+ (BOOL)isDebugLoggingEnabled;

/** Returns an unique identifier of current installation instance */
+ (NSString *)instanceIdentifier;

/** Returns a set of unique identifiers specific to the app, as query string */
+ (NSString *)deviceKey;

/** Return NSDictionary object which was converted from JSON string. Used for external calls */
+ (NSDictionary *)stringToDictionary:(NSString *)json;

/** Return NSArray object which was converted from JSON string. Used for external calls */
+ (NSArray *)stringToArray:(NSString *)json;

@end
