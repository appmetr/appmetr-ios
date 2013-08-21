/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "TestSessionData.h"
#import "SessionData.h"

@implementation TestSessionData {
    NSAutoreleasePool *mAutoreleasePool;
    SessionData *mSessionData;
}

- (void)dealloc {
    // do app code happy...
    [mSessionData release];
    [mAutoreleasePool release];
    [super dealloc];
}

- (void)setUp {
    [super setUp];
    mAutoreleasePool = [[NSAutoreleasePool alloc] init];

    mSessionData = [[SessionData alloc] init];
}

- (void)tearDown {
    [mSessionData saveFileList];
    [mSessionData release], mSessionData = nil;
    [mAutoreleasePool release], mAutoreleasePool = nil;
    [super tearDown];
}

- (void)testBatchIndex {
    SessionData *sessionData = [[SessionData alloc] init];

    NSUInteger firstValue = sessionData.batchIndex;
    NSUInteger secondValue = [sessionData nextBatchIndex];
    STAssertEquals(firstValue, secondValue, @"Wrong batch ID");
    [sessionData release];

    sessionData = [[SessionData alloc] init];
    NSUInteger finalValue = [sessionData nextBatchIndex];
    STAssertEquals(firstValue + 1, finalValue, @"Wrong batch ID restored");

    [sessionData release];
}

- (void)testFileIndex {
    SessionData *sessionData = [[SessionData alloc] init];

    NSUInteger firstValue = sessionData.fileIndex;
    NSUInteger secondValue = [sessionData nextFileIndex];
    STAssertEquals(firstValue + 1, secondValue, @"Wrong file index");
    [sessionData release];

    sessionData = [[SessionData alloc] init];
    NSUInteger finalValue = [sessionData nextFileIndex];
    STAssertEquals(firstValue + 2, finalValue, @"Wrong file indes rrestored");

    [sessionData release];
}

- (void)testFileList {
    SessionData *sessionData1 = [[SessionData alloc] init];
    [sessionData1.fileList removeAllObjects];
    [sessionData1 saveFileList];


    SessionData *sessionData2 = [[SessionData alloc] init];
    STAssertEquals((NSUInteger) 0, sessionData2.fileList.count,
    @"Expecter file list size 0, but got %u", sessionData2.fileList.count);
    [sessionData2 release];

    [sessionData1.fileList addObject:@"testFiliList"];
    [sessionData1 saveFileList];

    sessionData2 = [[SessionData alloc] init];
    NSString *fileName = [sessionData2.fileList objectAtIndex:0];
    STAssertTrue([fileName isEqualToString:@"testFiliList"],
    @"Expected file name 'testFiliList', but got %@", fileName);

    [sessionData2 release];
    [sessionData1 release];
}

@end
