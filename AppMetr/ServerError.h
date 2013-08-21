/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface ServerError : NSException

+ (void)raiseWithReason:(NSString *)reason;

+ (void)raiseWithStatusCore:(NSInteger)statusCode;

@end
