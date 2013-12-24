/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */
#import "SessionData.h"
#import "Constants.h"

#pragma mark - Private category

@interface SessionData ()
+ (void)setPreferences:(id)object forKey:(NSString *)key;
@end

@implementation SessionData

@synthesize batchIndex = mBatchIndex;
@synthesize fileIndex = mFileIndex;
@synthesize fileList = mFileList;
@synthesize isInstallURLTracked = mIsInstallURLTracked;
@synthesize isFirstTrackSessionSent = mIsFirstTrackSessionSent;
@synthesize sessionDuration = mSessionDuration;

#pragma mark - Initializing

- (id)init {
    self = [super init];
    if (self) {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

        // restore data from previous sessions
        mBatchIndex = [[preferences objectForKey:kPreferencesBatchNumberKeyName] unsignedIntegerValue];
        mFileIndex = [[preferences objectForKey:kPreferencesFileIndexKeyName] unsignedIntegerValue];
        mFileList = [[preferences objectForKey:kPreferencesFileListKeyName] mutableCopy];
        mIsInstallURLTracked = [[preferences objectForKey:kPreferencesInstallURLKeyName] boolValue];
        mIsFirstTrackSessionSent = [[preferences objectForKey:kPreferencesFirstTrackSessionKeyName] boolValue];
        mSessionDuration = [[preferences objectForKey:kPreferencesSessionDuration] longValue];

        if (!mFileList) {
            mFileList = [[NSMutableArray alloc] init];
        }
    }
    return self;
}

- (void)dealloc {
    [self saveFileList];

    [mFileList release];
    [super dealloc];
}

#pragma mark - Instance methods

- (NSUInteger)nextBatchIndex {
    NSUInteger ret = mBatchIndex;
    [SessionData setPreferences:[NSNumber numberWithUnsignedInt:(++mBatchIndex)] forKey:kPreferencesBatchNumberKeyName];
    return ret;
}

- (NSUInteger)nextFileIndex {
    [SessionData setPreferences:[NSNumber numberWithUnsignedInt:(++mFileIndex)] forKey:kPreferencesFileIndexKeyName];
    return mFileIndex;
}

- (void)saveFileList {
    [SessionData setPreferences:mFileList forKey:kPreferencesFileListKeyName];
}

#pragma mark  - Properties

- (void)setIsInstallURLTracked:(BOOL)isInstallURLTracked {
    [SessionData setPreferences:[NSNumber numberWithBool:isInstallURLTracked] forKey:kPreferencesInstallURLKeyName];
    mIsInstallURLTracked = isInstallURLTracked;
}

- (void)setIsFirstTrackSessionSent:(BOOL)isFirstTrackSessionSent {
    [SessionData setPreferences:[NSNumber numberWithBool:isFirstTrackSessionSent]
                         forKey:kPreferencesFirstTrackSessionKeyName];
    mIsFirstTrackSessionSent = isFirstTrackSessionSent;
}

- (void)setSessionDuration:(long)sessionDuration {
    [SessionData setPreferences:[NSNumber numberWithLong:sessionDuration] forKey:kPreferencesSessionDuration];
    mSessionDuration = sessionDuration;
}

#pragma mark - Class methods

+ (void)setPreferences:(id)object forKey:(NSString *)key {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setObject:object forKey:key];

    // flush preferences
    [preferences synchronize];
}

@end
