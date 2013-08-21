/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface JSONException : NSException
+ (void)raiseWithError:(NSError *)error;
@end
