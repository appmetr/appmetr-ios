/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */
#import "BatchFile.h"


#pragma mark - Private category

@interface BatchFile ()
- (NSUInteger)write:(const char *)buffer maxLength:(NSUInteger)length error:(NSError **)outError;

- (NSUInteger)writeData:(NSData *)data error:(NSError **)outError;

- (NSUInteger)writeString:(NSString *)string error:(NSError **)outError;
@end

@implementation BatchFile

@synthesize fullPath = mFullPath;
@synthesize contentSize = mContentSize;

#pragma mark - Initializing

- (id)initWithIndex:(NSUInteger)index {
    self = [self init];
    if (self) {

        NSArray *writablePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [writablePaths lastObject];
        mFullPath = [[documentsPath stringByAppendingFormat:@"/batch%u", (unsigned int)index] retain];
        if (!mFullPath) {
            mFullPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingFormat:@"/batch%u", (unsigned int)index] retain];
        }

        mOutputStream = [[NSOutputStream alloc] initToFileAtPath:mFullPath append:NO];
        [mOutputStream open];
        assert(mOutputStream && "Failed to open output stream");

        if (!mOutputStream) {
            NSLog(@"Failed to open file: %@", mFullPath);
            [self release];
            self = nil;
        }
    }

    return self;
}

#pragma mark - Destructor

- (void)dealloc {
    [self close];
    [mFullPath release];

    [super dealloc];
}

#pragma mark - Instance methods

- (void)close {
    if (mOutputStream) {
        [mOutputStream close];
        [mOutputStream release], mOutputStream = nil;
    }
}

- (void)addChunkData:(NSData *)data error:(NSError **)outError {
    NSUInteger count = [self writeData:data error:outError];
    mContentSize += count;
}

- (NSUInteger)write:(const char *)buffer maxLength:(NSUInteger)length error:(NSError **)outError {
    NSUInteger res = (NSUInteger) [mOutputStream write:(const uint8_t *) buffer maxLength:length];
    if (res != length) {
        NSLog(@"Failed to write to stream. %@", mOutputStream.streamError.localizedDescription);
        *outError = mOutputStream.streamError;
    }

    return length;
}

- (NSUInteger)writeData:(NSData *)data error:(NSError **)outError {
    NSUInteger res = (NSUInteger) [mOutputStream write:data.bytes maxLength:data.length];
    if (res != data.length) {
        NSLog(@"Failed to write to stream. %@", mOutputStream.streamError.localizedDescription);
        *outError = mOutputStream.streamError;
    }

    return res;
}

- (NSUInteger)writeString:(NSString *)string error:(NSError **)outError {
    return [self writeData:[string dataUsingEncoding:NSUTF8StringEncoding] error:outError];
}

@end
