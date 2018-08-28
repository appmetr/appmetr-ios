/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "TrackingManager+DirtyHack.h"

@implementation TrackingManager (DirtyHack)

- (id)initAndStopThread {
    self = [self init];
    if (self) {
        [self setupWithToken:@"5f294acf-4510-4bd9-a936-e27f59f7b7dd"];
        [self applicationDidEnterBackground];
    }

    return self;
}

- (NSArray *)getDirtyEventStack {
    return [self performSelector:@selector(getEventStack)];
}

- (NSString *)dirtyCreateBatchData {
    return [self performSelector:@selector(createBatchData)];
}

- (SessionData *)dirtySessionData {
    return [self performSelector:@selector(sessionData)];
}

- (void)dirtyFlushData {
    [self performSelector:@selector(flushData)];
}

- (void)dirtyCloseStreams {
    [self performSelector:@selector(closeStreams)];
}

- (NSUInteger)dirtyUploadData {
    return (NSUInteger) [self performSelector:@selector(uploadData)];
}

@end
