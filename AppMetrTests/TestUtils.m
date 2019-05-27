/**
 * Copyright (c) 2019 AppMetr.
 * All rights reserved.
 */

#import <XCTest/XCTest.h>
#import "Utils.h"

@interface TestUtils : XCTestCase

@end

@implementation TestUtils {
    NSAutoreleasePool *mAutoreleasePool;
}

- (void)setUp {
    [super setUp];
    mAutoreleasePool = [[NSAutoreleasePool alloc] init];
}

- (void)tearDown {
    [mAutoreleasePool release];
    mAutoreleasePool = nil;
    [super tearDown];
}

- (void)testConvertData {
    NSNumber* intVal1 = @142;
    NSNumber* intVal2 = @15;
    unsigned long long date1 = 1558443178531;
    unsigned long long date2 = 1265014800000;
    NSDate* dateVal1 = [NSDate dateWithTimeIntervalSince1970:(date1 / 1000.0)];
    NSDate* dateVal2 = [NSDate dateWithTimeIntervalSince1970:(date2 / 1000.0)];
    NSMutableDictionary* testData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     intVal1, @"intV",
                                     dateVal1, @"date",
                                     @{@"intVal": intVal2, @"dateVal": dateVal2}, @"dic",
                                     nil];
    [Utils convertDateToLong:testData];
    XCTAssertEqual(intVal1, testData[@"intV"], @"Wrong integer converted");
    XCTAssertEqual(date1, [testData[@"date"] unsignedLongLongValue], @"Date value doesn't converted correctly");
    XCTAssertEqual(intVal2, testData[@"dic"][@"intVal"], @"Wrong internal integer converted");
    XCTAssertEqual(date2, [testData[@"dic"][@"dateVal"] unsignedLongLongValue], @"Date internal value doesn't converted correctly");
}

@end
