/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "TestAppMetr.h"
#import "../AppMetr/AppMetr.h"
#import "TrackingManager+DirtyHack.h"
#import "AMBase64Util.h"
#import "CJSONDeserializer.h"
#import "../AppMetr/Utils.h"

@protocol AppMetrTesting <NSObject>
@end


@implementation TestAppMetr {
    NSAutoreleasePool *mAutoreleasePool;
    NSArray *mSavedProcessedCommandsList;
}

- (void)dealloc {
    // do app code happy...
    [mAutoreleasePool release];

    [super dealloc];
}

- (void)setUp {
    [super setUp];
    mAutoreleasePool = [[NSAutoreleasePool alloc] init];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    mSavedProcessedCommandsList = [[defaults arrayForKey:@"AppMetrMobile-ProcessedCommandList"] copy];
    [defaults setObject:[NSArray array] forKey:@"AppMetrMobile-ProcessedCommandList"];
    [defaults synchronize];
}

- (void)tearDown {
    if (mSavedProcessedCommandsList) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:mSavedProcessedCommandsList forKey:@"AppMetrMobile-ProcessedCommandList"];
        [defaults synchronize];
        [mSavedProcessedCommandsList release], mSavedProcessedCommandsList = nil;
    }

    [mAutoreleasePool release], mAutoreleasePool = nil;
    [super tearDown];
}

- (NSDictionary *)anyProperties {
    return [NSDictionary dictionaryWithObject:@"prop-value"
                                       forKey:@"prop-key"];
}

- (NSDictionary *)anyPayment {
    return [NSDictionary dictionaryWithObjectsAndKeys:@"mm", @"processor",
                                                      @"MAILIKI", @"psUserSpentCurrencyCode",
                                                      [NSNumber numberWithInt:10], @"psUserSpentCurrencyAmount",
                                                      @"MAILIKI", @"psReceivedCurrencyCode",
                                                      [NSNumber numberWithInt:10], @"psReceivedCurrencyAmount",
                                                      @"Totem", @"appCurrencyCode",
                                                      [NSNumber numberWithInt:2], @"appCurrencyAmount", nil];

}

- (void)testTrack {
    unsigned long long startTime = (unsigned long long) ([[NSDate date] timeIntervalSince1970] * 1000.0);

    TrackingManager *testLibrary = [[TrackingManager alloc] initAndStopThread];
    NSArray *eventStack = [testLibrary getDirtyEventStack];

    [testLibrary performSelector:@selector(trackEvent:)
                      withObject:[self anyProperties]];

    XCTAssertTrue([eventStack count] == 1, @"Invalid event stack size");

    NSDictionary *event = [eventStack lastObject];
    XCTAssertTrue([event isKindOfClass:[NSDictionary class]], @"Invalid event class");

    unsigned long long time = [[event objectForKey:@"timestamp"] unsignedLongLongValue];
    unsigned long long currentTime = (unsigned long long) ([[NSDate date] timeIntervalSince1970] * 1000.0);
    XCTAssertTrue((time >= startTime && time <= currentTime), @"Invalid value of timestamp");

    [testLibrary release];
}

- (void)testEventStack {
    TrackingManager *testLibrary = [[TrackingManager alloc] initAndStopThread];
    NSArray *eventStack = [testLibrary getDirtyEventStack];

    // need for first launch because first track session immediately flushes data
    if (!testLibrary.dirtySessionData.isFirstTrackSessionSent) {
        [testLibrary trackSession];
    }
    //Attach properties
    [testLibrary attachProperties:[self anyProperties]];
    XCTAssertTrue([eventStack count] == 1, @"[attachProperties:] failed") ;

    //Track session
    [testLibrary trackSession];
    XCTAssertTrue([eventStack count] == 2, @"[trackSession] failed") ;

    [testLibrary trackSessionWithProperties:[self anyProperties]];
    XCTAssertTrue([eventStack count] == 3, @"[trackSessionWithProperties:] failed") ;

    //Track level
    [testLibrary trackLevel:1];
    XCTAssertTrue([eventStack count] == 4, @"[trackLevel:] failed");

    [testLibrary trackLevel:2
                 properties:[self anyProperties]];
    XCTAssertTrue([eventStack count] == 5, @"[trackLevel:properties] failed");

    //Track event
    [testLibrary trackEvent:@"event1"];
    XCTAssertTrue([eventStack count] == 6, @"[trackEvent:] failed");

    [testLibrary trackEvent:@"event2"];
    XCTAssertTrue([eventStack count] == 7, @"[trackEvent:value] failed");

    [testLibrary trackEvent:@"event3"
                 properties:[self anyProperties]];
    XCTAssertTrue([eventStack count] == 8, @"[trackEvent:value:properties] failed");


    //Track payment
    [testLibrary trackPayment:[self anyPayment]];
    XCTAssertTrue([eventStack count] == 9, @"[trackPayment:] failed");

    [testLibrary trackPayment:[self anyPayment]
                   properties:[self anyProperties]];
    XCTAssertTrue([eventStack count] == 10, @"[trackPayment:properties] failed");

    [testLibrary release];
}


- (void)testAttachProperties {
    TrackingManager *testLibrary = [[TrackingManager alloc] initAndStopThread];
    NSArray *eventStack = [testLibrary getDirtyEventStack];

    [testLibrary attachProperties:[self anyProperties]];
    NSDictionary *event = [eventStack lastObject];

    NSString *actionName = [event objectForKey:@"action"];
    XCTAssertTrue([actionName isEqualToString:@"attachProperties"], @"Invalid action");
    XCTAssertTrue([event objectForKey:@"timestamp"] != nil, @"Missing timestamp");

    NSString *propertyValue = [[event objectForKey:@"properties"] objectForKey:@"prop-key"];
    XCTAssertTrue([propertyValue isEqualToString:@"prop-value"], @"Invalie property value");

    [testLibrary release];
}

- (void)testAttachEntityAttributes {
    TrackingManager* testLibrary = [[TrackingManager alloc] initAndStopThread];
    NSArray* eventStack = [testLibrary getDirtyEventStack];
    NSString* anyName = @"testEntity";
    NSString* anyValue = @"testEntityValue";
    NSDictionary* anyProperties = @{@"testAttrib" : @"testVal"};
    [testLibrary attachEntityAttributesForName:anyName value:anyValue withProperies:anyProperties];
    
    NSDictionary *event = [eventStack lastObject];
    NSString *actionName = [event objectForKey:@"action"];
    XCTAssertTrue([actionName isEqualToString:@"attachEntityAttributes"], @"Invalid action");
    XCTAssertTrue([[event objectForKey:@"entityName"] isEqualToString:anyName], @"Invalid entity name");
    XCTAssertTrue([[event objectForKey:@"entityValue"] isEqualToString:anyValue], @"Invalid entity value");
    XCTAssertTrue([[[event objectForKey:@"properties"] objectForKey:@"testAttrib"] isEqualToString:@"testVal"], @"Invalid attribute value");
}

- (void)testTrackSession {
    TrackingManager *testLibrary = [[TrackingManager alloc] initAndStopThread];
    NSArray *eventStack = [testLibrary getDirtyEventStack];

    // test 1
    [testLibrary trackSession];
    NSDictionary *session1 = [eventStack lastObject];

    NSString *actionName = [session1 objectForKey:@"action"];
    XCTAssertTrue([actionName isEqualToString:@"trackSession"], @"Invalid action");
    XCTAssertTrue([session1 objectForKey:@"timestamp"] != nil, @"Missing timestamp");


    // test 2
    [testLibrary trackSessionWithProperties:[self anyProperties]];
    NSDictionary *session2 = [eventStack lastObject];

    actionName = [session2 objectForKey:@"action"];
    XCTAssertTrue([actionName isEqualToString:@"trackSession"], @"Invalid action");
    XCTAssertTrue([session2 objectForKey:@"timestamp"] != nil, @"Missing timestamp");

    NSString *propertyValue = [[session2 objectForKey:@"properties"] objectForKey:@"prop-key"];
    XCTAssertTrue([propertyValue isEqualToString:@"prop-value"], @"Invalie property value");

    [testLibrary release];
}

- (void)testTrackEvent {
    TrackingManager *testLibrary = [[TrackingManager alloc] initAndStopThread];
    NSArray *eventStack = [testLibrary getDirtyEventStack];

    // test 1
    [testLibrary trackEvent:@"event1"];

    NSDictionary *action1 = [eventStack lastObject];
    NSString *actionName = [action1 objectForKey:@"action"];
    NSString *eventName = [action1 objectForKey:@"event"];

    XCTAssertTrue([actionName isEqualToString:@"trackEvent"], @"Invalid action");
    XCTAssertNotNil([action1 objectForKey:@"timestamp"], @"Missing timestamp");
    XCTAssertTrue([eventName isEqualToString:@"event1"], @"Invalid event name");

    // test 2
    [testLibrary trackEvent:@"event2"];

    NSDictionary *action2 = [eventStack lastObject];
    actionName = [action2 objectForKey:@"action"];
    eventName = [action2 objectForKey:@"event"];

    XCTAssertTrue([actionName isEqualToString:@"trackEvent"], @"Invalid action");
    XCTAssertNotNil([action2 objectForKey:@"timestamp"], @"Missing timestamp");
    XCTAssertTrue([eventName isEqualToString:@"event2"], @"Invalid event name");

    // test 3
    [testLibrary trackEvent:@"event3" properties:[self anyProperties]];

    NSDictionary *action3 = [eventStack lastObject];
    actionName = [action3 objectForKey:@"action"];
    eventName = [action3 objectForKey:@"event"];

    XCTAssertTrue([actionName isEqualToString:@"trackEvent"], @"Invalid action");
    XCTAssertNotNil([action3 objectForKey:@"timestamp"], @"Missing timestamp");
    XCTAssertTrue([eventName isEqualToString:@"event3"], @"Invalid event name");

    NSString *propertyValue = [[action3 objectForKey:@"properties"] objectForKey:@"prop-key"];
    XCTAssertTrue([propertyValue isEqualToString:@"prop-value"], @"Invalie property value");

    [testLibrary release];
}

- (void)testTrackPayment {
    TrackingManager *testLibrary = [[TrackingManager alloc] initAndStopThread];
    NSArray *eventStack = [testLibrary getDirtyEventStack];

    // test 1
    [testLibrary trackPayment:[self anyPayment]];
    NSDictionary *action1 = [eventStack lastObject];
    NSString *actionName = [action1 objectForKey:@"action"];
    NSString *processor = [action1 objectForKey:@"processor"];

    XCTAssertTrue([actionName isEqualToString:@"trackPayment"], @"Invalid action");
    XCTAssertTrue([action1 objectForKey:@"timestamp"] != nil, @"Missing timestamp");
    XCTAssertTrue([processor isEqualToString:@"mm"], @"Invalid payment");


    // test 2
    [testLibrary trackPayment:[self anyPayment]
                   properties:[self anyProperties]];
    NSDictionary *action2 = [eventStack lastObject];
    actionName = [action2 objectForKey:@"action"];
    processor = [action2 objectForKey:@"processor"];

    XCTAssertTrue([actionName isEqualToString:@"trackPayment"], @"Invalid action");
    XCTAssertTrue([action2 objectForKey:@"timestamp"] != nil, @"Missing timestamp");
    XCTAssertTrue([processor isEqualToString:@"mm"], @"Invalid payment");

    NSString *propertyValue = [[action2 objectForKey:@"properties"] objectForKey:@"prop-key"];
    XCTAssertTrue([propertyValue isEqualToString:@"prop-value"], @"Invalie property value");

    [testLibrary release];
}

- (void)_testCreateBatchData {
    TrackingManager *testLibrary = [[TrackingManager alloc] initAndStopThread];

    [testLibrary trackEvent:@"event1"];

    NSDate *testDate = [NSDate dateWithTimeIntervalSinceNow:100500];
    NSDictionary *properties = [NSDictionary dictionaryWithObject:testDate
                                                           forKey:@"test-date"];
    [testLibrary trackEvent:@"event2"
                 properties:properties];

    NSString *encodeBatchData = nil;
    XCTAssertNoThrow(encodeBatchData = [testLibrary dirtyCreateBatchData], @"Failed to create batch data");
    NSData *decodedData = [AMBase64Util decode:encodeBatchData];

    NSError *error = nil;
    NSDictionary *bathes = [[AMCJSONDeserializer deserializer] deserializeAsDictionary:decodedData
                                                                               error:&error];
    XCTAssertNil(error, @"JSON Deserializer failed: %@", [error localizedDescription]);

    NSNumber *batchId = [bathes objectForKey:@"batchId"];
    XCTAssertEqual([batchId unsignedIntValue] + 1, [testLibrary dirtySessionData].batchIndex, @"Invalid batch ID");

    NSArray *eventList = [bathes objectForKey:@"batch"];
    XCTAssertTrue([eventList count] == 2, @"Invalid size of event list");

    NSString *firstEventName = [[eventList objectAtIndex:0] objectForKey:@"event"];
    XCTAssertTrue([firstEventName isEqualToString:@"event1"], @"First event is invalid");

    NSDictionary *secondEvent = [eventList objectAtIndex:1];
    NSString *secondEventName = [secondEvent objectForKey:@"event"];
    XCTAssertTrue([secondEventName isEqualToString:@"event2"], @"Second event is invalid");

    NSNumber *referenceDate = [[secondEvent objectForKey:@"properties"] objectForKey:@"test-date"];

    XCTAssertEqual((unsigned long long) ([testDate timeIntervalSince1970] * 1000.0), [referenceDate unsignedLongLongValue],
    @"Wrong date value");

    [testLibrary release];
}

- (void)_testBatchFiles {
    TrackingManager *testLibrary = [[TrackingManager alloc] initAndStopThread];
    [testLibrary dirtyFlushData];

    [testLibrary trackEvent:@"testBatchFiles"];

    [testLibrary dirtyFlushData];

    NSString *batchFile = [[testLibrary dirtySessionData].fileList lastObject];

    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:batchFile encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error, @"Error while reading batch file: %@", [error localizedDescription]);

    NSData *decodedData = [AMBase64Util decode:content];

    error = nil;
    NSDictionary *batches = [[AMCJSONDeserializer deserializer] deserializeAsDictionary:decodedData
                                                                                error:&error];
    XCTAssertNil(error, @"JSON Deserializer failed: %@", [error localizedDescription]);

    NSArray *eventList = [batches objectForKey:@"batch"];
    XCTAssertEqual((NSUInteger) 1, [eventList count],
    @"Invalid size of event list. Expected 1, got is %u", [eventList count]);

    NSString *eventName = [[eventList objectAtIndex:0] objectForKey:@"event"];
    XCTAssertTrue([eventName isEqualToString:@"testBatchFiles"],
    @"Invalid event, expected 'testBatchFiles' but got '%@'", eventName);

    [testLibrary release];
}

// FIXME: recalculate batch size
- (void)_testAmountOfBatchFiles {
    TrackingManager *testLibrary = [[TrackingManager alloc] initAndStopThread];
    [testLibrary dirtyFlushData];
    [[testLibrary dirtySessionData].fileList removeAllObjects];

    [testLibrary trackEvent:@"testBatchFile1"];
    [testLibrary dirtyFlushData];
    [testLibrary trackEvent:@"testBatchFile2"];
    [testLibrary dirtyFlushData];
    [testLibrary trackEvent:@"testBatchFile3"];
    [testLibrary dirtyFlushData];
    [testLibrary trackEvent:@"testBatchFile4"];
    [testLibrary dirtyFlushData];
    [testLibrary trackEvent:@"testBatchFile5"];
    [testLibrary dirtyFlushData];
    [testLibrary trackEvent:@"testBatchFile6"];
    [testLibrary dirtyFlushData];

    XCTAssertEqual((NSUInteger) 2, [testLibrary dirtySessionData].fileList.count,
    @"Wrong file numbers. Experted 2, but got %u", [testLibrary dirtySessionData].fileList.count);

    XCTAssertEqual((NSUInteger) 3, [testLibrary dirtySessionData].fileList.count,
    @"Wrong file numbers. Experted 3, but got %u", [testLibrary dirtySessionData].fileList.count);

    [testLibrary release];
}

- (void)testUploadData {
    TrackingManager *testLibrary = [[TrackingManager alloc] initAndStopThread];
    [[testLibrary dirtySessionData].fileList removeAllObjects];

    [testLibrary trackEvent:@"event1"];
    [testLibrary dirtyFlushData];

    XCTAssertEqual((NSUInteger) 1, [testLibrary dirtyUploadData], @"Failed to upload data");

    [testLibrary trackEvent:@"event2"];
    [testLibrary dirtyFlushData];

    [testLibrary trackEvent:@"event3"];
    [testLibrary dirtyFlushData];

    XCTAssertEqual((NSUInteger) 2, [testLibrary dirtyUploadData], @"Failed to upload data");

    [testLibrary release];
}

- (void)testGameState {
    TrackingManager *testLibrary = [[TrackingManager alloc] initAndStopThread];
    [[testLibrary dirtySessionData].fileList removeAllObjects];
    [testLibrary dirtyFlushData];

    XCTAssertEqual((NSUInteger) 0, [testLibrary dirtyUploadData], @"Failed to upload data");

    [testLibrary release];
}

#define BASE_TEST_STRING "So?This 4, 5, 6, 7, 8, 9, z, {, |, } tests Base64 encoder. Show me: @, A," \
                            " B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z, [, \\, ], ^, _, `" \
                            ", a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s."

#define BASE_TEST_RESULT @"U28_VGhpcyA0LCA1LCA2LCA3LCA4LCA5LCB6LCB7LCB8LCB9IHRlc3RzIEJhc2U2NCBlbmNvZGVyLiBTa" \
                            "G93IG1lOiBALCBBLCBCLCBDLCBELCBFLCBGLCBHLCBILCBJLCBKLCBLLCBMLCBNLCBOLCBPLCBQLCBRLCB" \
                            "SLCBTLCBULCBVLCBWLCBXLCBYLCBZLCBaLCBbLCBcLCBdLCBeLCBfLCBgLCBhLCBiLCBjLCBkLCBlLCBmL" \
                            "CBnLCBoLCBpLCBqLCBrLCBsLCBtLCBuLCBvLCBwLCBxLCByLCBzLg=="

- (void)testUrlSafeBase64 {
    NSData *data = [[NSString stringWithFormat:@"%s", BASE_TEST_STRING] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *res = [AMBase64Util encode:data];

    XCTAssertTrue([res isEqualToString:BASE_TEST_RESULT], @"Base64 not URL safe");
}

- (void)testSetTimestamp {
    TrackingManager *testLibrary = [[TrackingManager alloc] initAndStopThread];
    [testLibrary dirtyFlushData];
    NSArray *eventStack = [testLibrary getDirtyEventStack];
    
    // test Date as timestamp
    unsigned long long testDate1 = 1487278800000;
    NSDictionary* propertiesLong = @{@"timestamp" : [NSNumber numberWithUnsignedLongLong:testDate1]};
    [testLibrary trackEvent: @"customTimestamp1" properties:propertiesLong];
    NSDictionary* resultsLong = [eventStack lastObject];
    XCTAssertTrue([[resultsLong objectForKey:@"action"] isEqualToString:@"trackEvent"], @"Invalid action");
    XCTAssertTrue([[resultsLong objectForKey:@"event"] isEqualToString:@"customTimestamp1"], @"Invalid event name");
    XCTAssertTrue([[resultsLong objectForKey:@"userTime"] unsignedLongLongValue] == testDate1, @"Invalid custom date");
    
    // test Date as Date
    NSDate* testDate2 = [NSDate dateWithTimeIntervalSince1970:1519851600000];
    NSDictionary* propertiesDate = @{@"timestamp" : testDate2};
    [testLibrary attachProperties:propertiesDate];
    NSDictionary* resultsDate = [eventStack lastObject];
    XCTAssertTrue([[resultsDate objectForKey:@"action"] isEqualToString:@"attachProperties"], @"Invalid action");
    XCTAssertTrue([[resultsDate objectForKey:@"userTime"] unsignedLongLongValue] == (unsigned long long)[testDate2 timeIntervalSince1970] * 1000.0, @"Invalid custom date");
    
    // test Date as wrong argument
    NSString* testDate3 = @"2018.04.10 12:00";
    NSDictionary* propertiesWrong = @{@"timestamp" : testDate3};
    [testLibrary trackEvent: @"customTimestamp3" properties:propertiesWrong];
    NSDictionary* resultsWrong = [eventStack lastObject];
    XCTAssertTrue([[resultsWrong objectForKey:@"action"] isEqualToString:@"trackEvent"], @"Invalid action");
    XCTAssertTrue([[resultsWrong objectForKey:@"event"] isEqualToString:@"customTimestamp3"], @"Invalid event name");
    XCTAssertTrue([resultsWrong objectForKey:@"userTime"] == nil, @"Invalid custom date");
    
}

@end
