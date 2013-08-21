/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface UIDeviceUtil : NSObject
/** This method retruns the hardware type */
+ (NSString *)hardwareString;

/** This method returns the readable description of hardware string */
+ (NSString *)hardwareDescription;
@end
