/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>

/**
 * Specilized delegate to process AppMetr commands
 */
@protocol AppMetrDelegate <NSObject>
@optional

/**
 * Executing a remote command from server
 */
- (void)executeCommand:(NSDictionary *)command;
@end
