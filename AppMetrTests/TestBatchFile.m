/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "TestBatchFile.h"
#import "BatchFile.h"

const NSUInteger kTestBatchFileIndex = 9999999;

@interface TestBatchFile ()
+ (NSString *)testFilePath;
@end

@implementation TestBatchFile {
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

    // remove test file
    [[NSFileManager defaultManager] removeItemAtPath:[TestBatchFile testFilePath] error:nil];
}

+ (NSString *)testFilePath {
    NSArray *writablePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [writablePaths lastObject];
    return [documentsPath stringByAppendingFormat:@"/batch%u", kTestBatchFileIndex];
}

- (void)tearDown {
    // remove test file
    [[NSFileManager defaultManager] removeItemAtPath:[TestBatchFile testFilePath] error:nil];

    [mAutoreleasePool release], mAutoreleasePool = nil;
    [super tearDown];
}

- (void)testFilePath {
    BatchFile *batchFile = [[BatchFile alloc] initWithIndex:kTestBatchFileIndex];

    XCTAssertTrue([batchFile.fullPath isEqualToString:[TestBatchFile testFilePath]],
    @"Expected path: %@, but got %@", [TestBatchFile testFilePath], batchFile.fullPath);

    [batchFile release];
}

- (void)testCreateFile {
    BatchFile *batchFile = [[BatchFile alloc] initWithIndex:kTestBatchFileIndex];


    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:batchFile.fullPath],
    @"File not exist: %@", batchFile.fullPath);

    [batchFile release];
}

//-(void)_testContentSize
//{
//	BatchFile* batchFile = [[BatchFile alloc]initWithIndex:kTestBatchFileIndex];
//
//	XCTAssertNoThrow([batchFile addChunk:@"test1"], @"Failed write to file: %@", batchFile.fullPath);
//	XCTAssertEqual((NSUInteger)5, batchFile.contentSize,
//	@"Invalid content size, expected 5, but is %u", batchFile.contentSize);
//
//	XCTAssertNoThrow([batchFile addChunk:@"test2"], @"Failed write to file: %@", batchFile.fullPath);
//	XCTAssertEqual((NSUInteger)11, batchFile.contentSize,
//	@"Invalid content size, expected 11, but is %u", batchFile.contentSize);
//
//	[batchFile release];
//
//	NSString* content = [NSString stringWithContentsOfFile:[TestBatchFile testFilePath]
//	                                              encoding:NSUTF8StringEncoding
//			                                         error:nil];
//
//	XCTAssertTrue([content isEqualToString:@"test1$test2"], @"Invalid content of file: '%@'", content);
//}

@end
