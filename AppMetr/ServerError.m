/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "ServerError.h"

@implementation ServerError

+ (void)raiseWithReason:(NSString *)reason {
    ServerError *exception = [[[self alloc] initWithName:@"Server error."
                                                  reason:reason
                                                userInfo:nil]
            autorelease];
    [exception raise];
}

+ (void)raiseWithStatusCore:(NSInteger)statusCode {
    [self raiseWithReason:[NSString stringWithFormat:@"Server return error with code %d", (int)statusCode]];
}

@end
