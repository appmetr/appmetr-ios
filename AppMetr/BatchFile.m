/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */
#import "BatchFile.h"


#pragma mark - Private category

NSString *const kOpeningBracket = @"[";
NSString *const kClosingBracket = @"]";
NSString *const kKoma = @",";

@interface BatchFile ()
- (NSUInteger)write:(char const *)buffer maxLength:(NSUInteger)length;

- (NSUInteger)writeData:(NSData *)data;

- (NSUInteger)writeString:(NSString *)string;
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
        else {
            // write opening bracket
            [self writeString:kOpeningBracket];
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
        // write closing bracket
        [self writeString:kClosingBracket];

        [mOutputStream close];
        [mOutputStream release], mOutputStream = nil;
    }
}

- (void)addChunkData:(NSData *)data {
    if (mContentSize) {
        mContentSize += [self writeString:kKoma];
    }

    mContentSize += [self writeData:data];
}

- (NSUInteger)write:(const char *)buffer maxLength:(NSUInteger)length {
    NSUInteger res = (NSUInteger) [mOutputStream write:(const uint8_t *) buffer maxLength:length];
    if (res != length) {
        [NSException raise:NSGenericException
                    format:@"Failed to write to stream. %@",
                           mOutputStream.streamError.localizedDescription];
    }

    return length;
}

- (NSUInteger)writeData:(NSData *)data {
    NSUInteger res = (NSUInteger) [mOutputStream write:data.bytes maxLength:data.length];
    if (res != data.length) {
        [NSException raise:NSGenericException
                    format:@"Failed to write to stream. %@",
                           mOutputStream.streamError.localizedDescription];
    }

    return res;
}

- (NSUInteger)writeString:(NSString *)string {
    return [self writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
