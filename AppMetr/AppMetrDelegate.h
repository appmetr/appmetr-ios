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
 * @deprecated in v1.3, use -(void)executeCommand: instead
 */
- (void)executeCommand:(NSString *)commandId withProperties:(NSDictionary *)properties DEPRECATED_ATTRIBUTE;

/**
 * Executing a remote command from server
 * @since v1.3
 */
- (void)executeCommand:(NSDictionary *)command;
@end
