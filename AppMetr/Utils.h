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
 * Returns the timestamp in milliseconds
 */
+ (unsigned long long)timestamp;

/**
 * Returns a unique identifier specific to the app
 */
+ (NSString *)uniqueIdentifier;

/**
 * Returns a set of device ids, encoded in a query string
 */
+ (NSString *)deviceKeyForToken:(NSString*)token;

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

+ (BOOL)convertDateToLong:(NSMutableDictionary*)data;

+ (NSInteger)convertObjectToInt:(id)object;

+ (NSDictionary *)convertObjectToDict:(id)object;

+ (void)getDiskSpaceAvailable:(NSNumber**)availableSpace total:(NSNumber**)totalSpace;

@end
