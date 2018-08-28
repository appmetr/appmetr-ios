/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>


@interface Utils : NSObject

/**
 * Validates the specified key of payment dictionary
 */
+ (void)validatePayment:(NSDictionary *)payment
                    key:(NSString *)key
              valueType:(Class)valueClass
              mandatory:(BOOL)mandatory;

/**
 * Validates all parameters of payment dictionary
 */
+ (void)validatePayment:(NSDictionary *)payment;

/**
 * Sends the request to the server
 */
+ (BOOL)sendRequest:(NSString *)address
              token:(NSString *)token
     userIdentifier:(NSString *)userIdentifier
            batches:(NSData *)batches
            logging:(BOOL)logging;

/**
* Send verify payment request
*/
+ (NSDictionary *)sendVerifyPaymentRequest:(NSString *)address
                                     token:(NSString *)token
                            userIdentifier:(NSString *)userIdentifier
                                  purchase:(NSString *)purchase
                                   receipt:(NSString *)receipt
                                      salt:(NSString *)salt
                                   logging:(BOOL)logging;

/**
 * Returns the timestamp in milliseconds
 */
+ (unsigned long long)timestamp;

/**
 * Returns a unique identifier specific to the app
 */
+ (NSString *)uniqueIdentifier;

/**
 * Returns the local MAC address
 */
+ (NSString *)stringWithDeviceMACAddress;

/**
 * Compressing the specified data
 */
+ (NSData *)compressData:(NSData *)data;

/** Returns an unique instance identifier for given token */
+ (NSString *)instanceIdentifierForToken:(NSString *)token;

/** Returns a string with request parameters */
+ (NSString *)requestParametersForMethod:(NSString *)method
                                 address:(NSString *)address
                                   token:(NSString *)token
                          userIdentifier:(NSString *)userIdentifier;

/** Returns MD5 cache */
+ (NSString *)md5:(NSString *)input;

@end
