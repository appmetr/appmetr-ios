/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "AcceptanceTest.h"
#import "TrackingManager+DirtyHack.h"
#import "SessionData.h"

@implementation AcceptanceTest {
    NSAutoreleasePool *mAutoreleasePool;
}

- (void)dealloc {
    // do app code happy...
    [mAutoreleasePool release];

    [super dealloc];
}

- (void)setUp {
    [super setUp];
    mAutoreleasePool = [[NSAutoreleasePool alloc] init];
}

- (void)tearDown {
    [mAutoreleasePool release], mAutoreleasePool = nil;

    [super tearDown];
}

- (void)_testShortTestWithoutPayment {
    TrackingManager *testLibrary = [[TrackingManager alloc] initAndStopThread];

    [[testLibrary dirtySessionData].fileList removeAllObjects];
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys:@"red", @"abGroup",
                                                                          @"test", @"adRef", nil];
    [testLibrary attachProperties:properties];

    properties = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:80] forKey:@"level"];
    [testLibrary trackSessionWithProperties:properties];

    properties = [NSDictionary dictionaryWithObject:@"blue" forKey:@"abGroup"];
    [testLibrary trackLevel:81 properties:properties];
    [testLibrary trackEvent:@"test/test"];

    [testLibrary dirtyFlushData];
    [testLibrary dirtyCloseStreams];

    properties = [NSDictionary dictionaryWithObjectsAndKeys:@"red", @"abGroup",
                                                            @"test", @"adRef", nil];
    [testLibrary attachProperties:properties];
    [testLibrary trackSession];

    properties = [NSDictionary dictionaryWithObject:@"green" forKey:@"abGroup"];
    [testLibrary trackLevel:82 properties:properties];
    [testLibrary trackEvent:@"test/test2"];

    [testLibrary dirtyFlushData];
    [testLibrary dirtyCloseStreams];

    XCTAssertEqual((NSUInteger) 2, [testLibrary dirtyUploadData], @"Failed to upload data");

    [testLibrary release];
}

- (NSUInteger)numOfBatchSplitterInString:(NSString *)content fromIndex:(NSUInteger)index {
    NSUInteger length = [content length];
    NSRange range = NSMakeRange(index, length - index);

    range = [content rangeOfString:@"$" options:0 range:range];
    if (range.location == NSNotFound) {
        return 0;
    }
    return [self numOfBatchSplitterInString:content fromIndex:range.location + 1] + 1;
}

- (void)_testFourFiles {

    TrackingManager *testLibrary = [[TrackingManager alloc] initAndStopThread];
    [testLibrary setupSizeLimitOfCacheFile:142 * 3];
    [[[testLibrary dirtySessionData] fileList] removeAllObjects];

    NSUInteger beginTestFilesCount = [[[testLibrary dirtySessionData] fileList] count] + 1;

    for (NSUInteger i = 0; i < 10; i++) {
        [testLibrary trackEvent:@"test"];
        [testLibrary dirtyFlushData];
    }
    [testLibrary dirtyCloseStreams];
    [testLibrary applicationWillEnterForeground];

    NSUInteger endTestFilesCount = [[[testLibrary dirtySessionData] fileList] count] + 1;

    NSMutableString *content = [NSMutableString string];
    NSArray *fileList = [[testLibrary dirtySessionData] fileList];
    for (NSString *filename in fileList) {
        NSString *contentFile = [NSString stringWithContentsOfFile:filename
                                                          encoding:NSUTF8StringEncoding
                                                             error:nil];
        [content appendString:contentFile];
    }

    XCTAssertEqual((NSUInteger) 4, (endTestFilesCount - beginTestFilesCount), @"Invalid file count");
    XCTAssertEqual((NSUInteger) 6, [self numOfBatchSplitterInString:content fromIndex:0], @"Invalid batch count");
}

// FIXME: recalculate batch size
- (void)_testThreeFilesWithAllocation // allocation 2 events - 1 event - 1 event
{
    TrackingManager *testLibrary = [[TrackingManager alloc] initAndStopThread];
    [testLibrary setupSizeLimitOfCacheFile:12];
    NSUInteger beginTestFilesCount = [[[testLibrary dirtySessionData] fileList] count];

    [testLibrary trackEvent:@"First test event"];
    [testLibrary trackEvent:@"Second test event"];

    [testLibrary dirtyFlushData];
    [testLibrary dirtyCloseStreams];

    [testLibrary trackEvent:@"Third test event with length > S"];
    [testLibrary dirtyFlushData];
    [testLibrary dirtyCloseStreams];

    [testLibrary trackEvent:@"Fourth test event"];
    [testLibrary dirtyFlushData];
    [testLibrary dirtyCloseStreams];

    NSUInteger endTestFilesCount = [[[testLibrary dirtySessionData] fileList] count];
    XCTAssertTrue((3 == (endTestFilesCount - beginTestFilesCount)), @"Failed to create three files");
    [testLibrary release];
}


- (void)testHundredEvents {
    TrackingManager *testLibrary = [[TrackingManager alloc] initAndStopThread];

    for (NSUInteger i = 0; i < 100; i++) {
        [testLibrary trackEvent:@"test"];
    }

    NSUInteger count = [[testLibrary getDirtyEventStack] count];
    XCTAssertEqual((NSUInteger) 100, count, @"Failed to create 100 events");
    [testLibrary release];
}

#pragma mark - private function 

- (NSString *)filePathWithIndex:(NSUInteger)index {
    NSArray *writablePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [writablePaths lastObject];
    return [documentsPath stringByAppendingFormat:@"/batch%u", index];
}
@end
