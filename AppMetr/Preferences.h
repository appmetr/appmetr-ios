/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface Preferences : NSObject {
    NSString *mLastProcessedCommandID;
}

/** An unique identifier of last process command */
@property(nonatomic, assign) NSString *lastProcessedCommandIdentifier;

@end
