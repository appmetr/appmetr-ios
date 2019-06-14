/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface SessionData : NSObject {
    NSUInteger mBatchIndex;
    NSUInteger mFileIndex;
    NSMutableArray *mFileList;
    NSMutableArray *mUploadList;
    BOOL mIsInstallURLTracked;
    BOOL mIsFirstTrackSessionSent;
    long mSessionDuration;
    long mSessionDurationCurrent;
}

/** The current batch index */
@property(nonatomic, readonly) NSUInteger batchIndex;
/** The current index of batch file */
@property(nonatomic, readonly) NSUInteger fileIndex;
/** The list of batch files */
@property(nonatomic, readonly) NSMutableArray *fileList;
/** Is install URL tracked or not? */
@property(nonatomic, readwrite) BOOL isInstallURLTracked;
/** Is first trackSession */
@property(nonatomic, readwrite) BOOL isFirstTrackSessionSent;
/** Duration of previous session */
@property(nonatomic, readwrite) long sessionDuration;
/** Duration of current session */
@property(nonatomic, readwrite) long sessionDurationCurrent;
/** The list of event date for direct upload */
@property(nonatomic, readwrite) NSMutableArray *uploadList;

/** Returns the index of new batch */
- (NSUInteger)nextBatchIndex;

/** Returns the index of new file */
- (NSUInteger)nextFileIndex;

/** Saves file list */
- (void)saveFileList;

@end
