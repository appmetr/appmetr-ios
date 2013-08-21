/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "JSONException.h"

@implementation JSONException

+ (void)raiseWithError:(NSError *)error {
    [[[[self alloc] initWithName:@"JSONException"
                          reason:[NSString stringWithFormat:@"Invalid format: %@", error.description]
                        userInfo:nil] autorelease] raise];
}

@end
