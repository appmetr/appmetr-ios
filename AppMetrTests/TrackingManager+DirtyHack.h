/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "TrackingManager.h"
#import "SessionData.h"

// Pre-declare classes
@class SessionData;

@interface TrackingManager (DirtyHack)

- (id)initAndStopThread;

- (NSArray *)getDirtyEventStack;

- (NSString *)dirtyCreateBatchData;

- (SessionData *)dirtySessionData;

- (void)dirtyFlushData;

- (void)dirtyCloseStreams;

- (NSUInteger)dirtyUploadData;

@end
