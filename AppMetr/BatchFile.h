/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */
#import <Foundation/Foundation.h>

@interface BatchFile : NSObject {
    NSOutputStream *mOutputStream;
    NSString *mFullPath;
    NSUInteger mContentSize;
}

/** The full path to batch file */
@property(nonatomic, readonly) NSString *fullPath;
/** The current size of file content */
@property(nonatomic, readonly) NSUInteger contentSize;

/**
 * Initializing and return output stream for batch file with specified index
 */
- (id)initWithIndex:(NSUInteger)index;

/**
 * Close file stream
 */
- (void)close;

/**
 * Adds a new chunk to batch file
 */
- (void)addChunkData:(NSData *)data;

@end
