/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "TestAppMetr.h"
#import "../AppMetr/AppMetr.h"
#import "AppMetr+DirtyHack.h"
#import "Base64.h"
#import "CJSONDeserializer.h"
#import "RemoteCommandPacket.h"

@protocol AppMetrTesting <NSObject>
- (BOOL)hasProcessedCommandWithID:(NSString *)commandID;

- (void)processPacket:(RemoteCommandPacket *)packet;

- (NSMutableArray *)getRemoteCommandList;

- (NSMutableArray *)getProcessedCommandList;
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

    AppMetr *testLibrary = [[AppMetr alloc] initAndStopThread];
    NSArray *eventStack = [testLibrary getDirtyEventStack];

    [testLibrary performSelector:@selector(trackEvent:)
                      withObject:[self anyProperties]];

    STAssertTrue([eventStack count] == 1, @"Invalid event stack size");

    NSDictionary *event = [eventStack lastObject];
    STAssertTrue([event isKindOfClass:[NSDictionary class]], @"Invalid event class");

    unsigned long long time = [[event objectForKey:@"timestamp"] unsignedLongLongValue];
    unsigned long long currentTime = (unsigned long long) ([[NSDate date] timeIntervalSince1970] * 1000.0);
    STAssertTrue((time >= startTime && time <= currentTime), @"Invalid value of timestamp");

    [testLibrary release];
}

- (void)testEventStack {
    AppMetr *testLibrary = [[AppMetr alloc] initAndStopThread];
    NSArray *eventStack = [testLibrary getDirtyEventStack];

    //Attach properties
    [testLibrary attachProperties:[self anyProperties]];
    STAssertTrue([eventStack count] == 1, @"[attachProperties:] failed") ;

    //Track session
    [testLibrary trackSession];
    STAssertTrue([eventStack count] == 2, @"[trackSession] failed") ;

    [testLibrary trackSessionWithProperties:[self anyProperties]];
    STAssertTrue([eventStack count] == 3, @"[trackSessionWithProperties:] failed") ;

    //Track level
    [testLibrary trackLevel:1];
    STAssertTrue([eventStack count] == 4, @"[trackLevel:] failed");

    [testLibrary trackLevel:2
                 properties:[self anyProperties]];
    STAssertTrue([eventStack count] == 5, @"[trackLevel:properties] failed");

    //Track event
    [testLibrary trackEvent:@"event1"];
    STAssertTrue([eventStack count] == 6, @"[trackEvent:] failed");

    [testLibrary trackEvent:@"event2"];
    STAssertTrue([eventStack count] == 7, @"[trackEvent:value] failed");

    [testLibrary trackEvent:@"event3"
                 properties:[self anyProperties]];
    STAssertTrue([eventStack count] == 8, @"[trackEvent:value:properties] failed");


    //Track payment
    [testLibrary trackPayment:[self anyPayment]];
    STAssertTrue([eventStack count] == 9, @"[trackPayment:] failed");

    [testLibrary trackPayment:[self anyPayment]
                   properties:[self anyProperties]];
    STAssertTrue([eventStack count] == 10, @"[trackPayment:properties] failed");

    [testLibrary release];
}


- (void)testAttachProperties {
    AppMetr *testLibrary = [[AppMetr alloc] initAndStopThread];
    NSArray *eventStack = [testLibrary getDirtyEventStack];

    [testLibrary attachProperties:[self anyProperties]];
    NSDictionary *event = [eventStack lastObject];

    NSString *actionName = [event objectForKey:@"action"];
    STAssertTrue([actionName isEqualToString:@"attachProperties"], @"Invalid action");
    STAssertTrue([event objectForKey:@"timestamp"] != nil, @"Missing timestamp");

    NSString *propertyValue = [[event objectForKey:@"properties"] objectForKey:@"prop-key"];
    STAssertTrue([propertyValue isEqualToString:@"prop-value"], @"Invalie property value");

    [testLibrary release];
}

- (void)testTrackSession {
    AppMetr *testLibrary = [[AppMetr alloc] initAndStopThread];
    NSArray *eventStack = [testLibrary getDirtyEventStack];

    // test 1
    [testLibrary trackSession];
    NSDictionary *session1 = [eventStack lastObject];

    NSString *actionName = [session1 objectForKey:@"action"];
    STAssertTrue([actionName isEqualToString:@"trackSession"], @"Invalid action");
    STAssertTrue([session1 objectForKey:@"timestamp"] != nil, @"Missing timestamp");


    // test 2
    [testLibrary trackSessionWithProperties:[self anyProperties]];
    NSDictionary *session2 = [eventStack lastObject];

    actionName = [session2 objectForKey:@"action"];
    STAssertTrue([actionName isEqualToString:@"trackSession"], @"Invalid action");
    STAssertTrue([session2 objectForKey:@"timestamp"] != nil, @"Missing timestamp");

    NSString *propertyValue = [[session2 objectForKey:@"properties"] objectForKey:@"prop-key"];
    STAssertTrue([propertyValue isEqualToString:@"prop-value"], @"Invalie property value");

    [testLibrary release];
}

- (void)testTrackLevel {
    AppMetr *testLibrary = [[AppMetr alloc] initAndStopThread];
    NSArray *eventStack = [testLibrary getDirtyEventStack];

    // test 1
    [testLibrary trackLevel:81];
    NSDictionary *action1 = [eventStack lastObject];

    NSString *actionName = [action1 objectForKey:@"action"];
    STAssertTrue([actionName isEqualToString:@"trackLevel"], @"Invalid action");
    STAssertTrue([action1 objectForKey:@"timestamp"] != nil, @"Missing timestamp");

    NSNumber *level1 = [action1 objectForKey:@"level"];
    STAssertTrue([level1 intValue] == 81, @"Invalid level");


    // test 2
    [testLibrary trackLevel:98
                 properties:[self anyProperties]];
    NSDictionary *action2 = [eventStack lastObject];

    actionName = [action2 objectForKey:@"action"];
    STAssertTrue([actionName isEqualToString:@"trackLevel"], @"Invalid action");
    STAssertTrue([action2 objectForKey:@"timestamp"] != nil, @"Missing timestamp");

    NSNumber *level2 = [action2 objectForKey:@"level"];
    STAssertTrue([level2 intValue] == 98, @"Invalid level");

    NSString *propertyValue = [[action2 objectForKey:@"properties"] objectForKey:@"prop-key"];
    STAssertTrue([propertyValue isEqualToString:@"prop-value"], @"Invalie property value");

    [testLibrary release];
}

- (void)testTrackEvent {
    AppMetr *testLibrary = [[AppMetr alloc] initAndStopThread];
    NSArray *eventStack = [testLibrary getDirtyEventStack];

    // test 1
    [testLibrary trackEvent:@"event1"];

    NSDictionary *action1 = [eventStack lastObject];
    NSString *actionName = [action1 objectForKey:@"action"];
    NSString *eventName = [action1 objectForKey:@"event"];

    STAssertTrue([actionName isEqualToString:@"trackEvent"], @"Invalid action");
    STAssertNotNil([action1 objectForKey:@"timestamp"], @"Missing timestamp");
    STAssertTrue([eventName isEqualToString:@"event1"], @"Invalid event name");

    // test 2
    [testLibrary trackEvent:@"event2"];

    NSDictionary *action2 = [eventStack lastObject];
    actionName = [action2 objectForKey:@"action"];
    eventName = [action2 objectForKey:@"event"];

    STAssertTrue([actionName isEqualToString:@"trackEvent"], @"Invalid action");
    STAssertNotNil([action2 objectForKey:@"timestamp"], @"Missing timestamp");
    STAssertTrue([eventName isEqualToString:@"event2"], @"Invalid event name");

    // test 3
    [testLibrary trackEvent:@"event3" properties:[self anyProperties]];

    NSDictionary *action3 = [eventStack lastObject];
    actionName = [action3 objectForKey:@"action"];
    eventName = [action3 objectForKey:@"event"];

    STAssertTrue([actionName isEqualToString:@"trackEvent"], @"Invalid action");
    STAssertNotNil([action3 objectForKey:@"timestamp"], @"Missing timestamp");
    STAssertTrue([eventName isEqualToString:@"event3"], @"Invalid event name");

    NSString *propertyValue = [[action3 objectForKey:@"properties"] objectForKey:@"prop-key"];
    STAssertTrue([propertyValue isEqualToString:@"prop-value"], @"Invalie property value");

    [testLibrary release];
}

- (void)testTrackPayment {
    AppMetr *testLibrary = [[AppMetr alloc] initAndStopThread];
    NSArray *eventStack = [testLibrary getDirtyEventStack];

    // test 1
    [testLibrary trackPayment:[self anyPayment]];
    NSDictionary *action1 = [eventStack lastObject];
    NSString *actionName = [action1 objectForKey:@"action"];
    NSString *processor = [action1 objectForKey:@"processor"];

    STAssertTrue([actionName isEqualToString:@"trackPayment"], @"Invalid action");
    STAssertTrue([action1 objectForKey:@"timestamp"] != nil, @"Missing timestamp");
    STAssertTrue([processor isEqualToString:@"mm"], @"Invalid payment");


    // test 2
    [testLibrary trackPayment:[self anyPayment]
                   properties:[self anyProperties]];
    NSDictionary *action2 = [eventStack lastObject];
    actionName = [action2 objectForKey:@"action"];
    processor = [action2 objectForKey:@"processor"];

    STAssertTrue([actionName isEqualToString:@"trackPayment"], @"Invalid action");
    STAssertTrue([action2 objectForKey:@"timestamp"] != nil, @"Missing timestamp");
    STAssertTrue([processor isEqualToString:@"mm"], @"Invalid payment");

    NSString *propertyValue = [[action2 objectForKey:@"properties"] objectForKey:@"prop-key"];
    STAssertTrue([propertyValue isEqualToString:@"prop-value"], @"Invalie property value");

    [testLibrary release];
}

- (void)_testCreateBatchData {
    AppMetr *testLibrary = [[AppMetr alloc] initAndStopThread];

    [testLibrary trackEvent:@"event1"];

    NSDate *testDate = [NSDate dateWithTimeIntervalSinceNow:100500];
    NSDictionary *properties = [NSDictionary dictionaryWithObject:testDate
                                                           forKey:@"test-date"];
    [testLibrary trackEvent:@"event2"
                 properties:properties];

    NSString *encodeBatchData = nil;
    STAssertNoThrow(encodeBatchData = [testLibrary dirtyCreateBatchData], @"Failed to create batch data");
    NSData *decodedData = [Base64 decode:encodeBatchData];

    NSError *error = nil;
    NSDictionary *bathes = [[CJSONDeserializer deserializer] deserializeAsDictionary:decodedData
                                                                               error:&error];
    STAssertNil(error, @"JSON Deserializer failed: %@", [error localizedDescription]);

    NSNumber *batchId = [bathes objectForKey:@"batchId"];
    STAssertEquals([batchId unsignedIntValue] + 1, [testLibrary dirtySessionData].batchIndex, @"Invalid batch ID");

    NSArray *eventList = [bathes objectForKey:@"batch"];
    STAssertTrue([eventList count] == 2, @"Invalid size of event list");

    NSString *firstEventName = [[eventList objectAtIndex:0] objectForKey:@"event"];
    STAssertTrue([firstEventName isEqualToString:@"event1"], @"First event is invalid");

    NSDictionary *secondEvent = [eventList objectAtIndex:1];
    NSString *secondEventName = [secondEvent objectForKey:@"event"];
    STAssertTrue([secondEventName isEqualToString:@"event2"], @"Second event is invalid");

    NSNumber *referenceDate = [[secondEvent objectForKey:@"properties"] objectForKey:@"test-date"];

    STAssertEquals((unsigned long long) ([testDate timeIntervalSince1970] * 1000.0), [referenceDate unsignedLongLongValue],
    @"Wrong date value");

    [testLibrary release];
}

- (void)_testBatchFiles {
    AppMetr *testLibrary = [[AppMetr alloc] initAndStopThread];
    [testLibrary dirtyFlushData];
    [testLibrary dirtyCloseStreams];

    [testLibrary trackEvent:@"testBatchFiles"];

    [testLibrary dirtyFlushData];
    [testLibrary dirtyCloseStreams];

    NSString *batchFile = [[testLibrary dirtySessionData].fileList lastObject];

    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:batchFile encoding:NSUTF8StringEncoding error:&error];
    STAssertNil(error, @"Error while reading batch file: %@", [error localizedDescription]);

    NSData *decodedData = [Base64 decode:content];

    error = nil;
    NSDictionary *batches = [[CJSONDeserializer deserializer] deserializeAsDictionary:decodedData
                                                                                error:&error];
    STAssertNil(error, @"JSON Deserializer failed: %@", [error localizedDescription]);

    NSArray *eventList = [batches objectForKey:@"batch"];
    STAssertEquals((NSUInteger) 1, [eventList count],
    @"Invalid size of event list. Expected 1, got is %u", [eventList count]);

    NSString *eventName = [[eventList objectAtIndex:0] objectForKey:@"event"];
    STAssertTrue([eventName isEqualToString:@"testBatchFiles"],
    @"Invalid event, expected 'testBatchFiles' but got '%@'", eventName);

    [testLibrary release];
}

// FIXME: recalculate batch size
- (void)_testAmountOfBatchFiles {
    AppMetr *testLibrary = [[AppMetr alloc] initAndStopThread];
    [testLibrary dirtyFlushData];
    [testLibrary dirtyCloseStreams];
    [[testLibrary dirtySessionData].fileList removeAllObjects];

    [testLibrary setupSizeLimitOfCacheFile:300];

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

    STAssertEquals((NSUInteger) 2, [testLibrary dirtySessionData].fileList.count,
    @"Wrong file numbers. Experted 2, but got %u", [testLibrary dirtySessionData].fileList.count);

    [testLibrary dirtyCloseStreams];

    STAssertEquals((NSUInteger) 3, [testLibrary dirtySessionData].fileList.count,
    @"Wrong file numbers. Experted 3, but got %u", [testLibrary dirtySessionData].fileList.count);

    [testLibrary release];
}

- (void)testUploadData {
    AppMetr *testLibrary = [[AppMetr alloc] initAndStopThread];
    [[testLibrary dirtySessionData].fileList removeAllObjects];

    [testLibrary trackEvent:@"event1"];
    [testLibrary dirtyFlushData];
    [testLibrary dirtyCloseStreams];

    STAssertEquals((NSUInteger) 1, [testLibrary dirtyUploadData], @"Failed to upload data");

    [testLibrary trackEvent:@"event2"];
    [testLibrary dirtyFlushData];
    [testLibrary dirtyCloseStreams];

    [testLibrary trackEvent:@"event3"];
    [testLibrary dirtyFlushData];
    [testLibrary dirtyCloseStreams];

    STAssertEquals((NSUInteger) 2, [testLibrary dirtyUploadData], @"Failed to upload data");

    [testLibrary release];
}

- (void)testGameState {
    AppMetr *testLibrary = [[AppMetr alloc] initAndStopThread];
    [[testLibrary dirtySessionData].fileList removeAllObjects];

    [testLibrary trackGameState:@"TestState" properties:[self anyProperties]];
    [testLibrary dirtyFlushData];
    [testLibrary dirtyCloseStreams];

    STAssertEquals((NSUInteger) 1, [testLibrary dirtyUploadData], @"Failed to upload data");

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
    NSString *res = [Base64 encode:data];

    STAssertTrue([res isEqualToString:BASE_TEST_RESULT], @"Base64 not URL safe");
}

- (void)testTrackInstallURL {
    AppMetr *testLibrary = [[AppMetr alloc] initAndStopThread];
    [[testLibrary dirtySessionData].fileList removeAllObjects];

    [testLibrary trackInstallURL:[NSURL URLWithString:@"http://AppMetr.mobile/unit/test"]];

    STAssertEquals((NSUInteger) 0, [[testLibrary dirtySessionData].fileList count], @"Invalid number of files");
}

- (void)testTrackCommand {
    AppMetr *testLibrary = [[AppMetr alloc] initAndStopThread];

    [testLibrary performSelector:@selector(trackCommand:) withObject:@"test-1"];
    STAssertEquals((NSUInteger) 1, [[testLibrary getDirtyEventStack] count], @"Failed to add trackCommand(success)");


    [testLibrary performSelector:@selector(trackCommand:skipReason:) withObject:@"test-2" withObject:@"unit-test"];
    STAssertEquals((NSUInteger) 2, [[testLibrary getDirtyEventStack] count], @"Failed to add trackCommand(skip)");

    @try {
        [NSException raise:@"unit-test" format:@"just-unit-test"];
    }
    @catch (NSException *exception) {
        [testLibrary performSelector:@selector(trackCommand:exception:) withObject:@"test-3" withObject:exception];
        STAssertEquals((NSUInteger) 3, [[testLibrary getDirtyEventStack] count], @"Failed to add trackCommand(fail)");
    }

    [((NSMutableArray *) [testLibrary getDirtyEventStack]) removeAllObjects];
}

- (void)testTrackCommandBatch {
    AppMetr *testLibrary = [[AppMetr alloc] initAndStopThread];

    NSMethodSignature *signature;
    signature = [AppMetr instanceMethodSignatureForSelector:@selector(trackCommandBatchWithLastCommandID:error:description:)];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];

    [invocation setTarget:testLibrary];
    [invocation setSelector:@selector(trackCommandBatchWithLastCommandID:error:description:)];

    NSString *commandID = @"test-batch-1";
    NSString *errorName = @"unit-test";
    NSString *errorDescription = @"igrone, just init test";

    [invocation setArgument:&commandID atIndex:2];
    [invocation setArgument:&errorName atIndex:3];
    [invocation setArgument:&errorDescription atIndex:4];

    [invocation invoke];
    STAssertEquals((NSUInteger) 1, [[testLibrary getDirtyEventStack] count], @"Failed to add testTrackCommandBatch");

    [((NSMutableArray *) [testLibrary getDirtyEventStack]) removeAllObjects];
}

- (void)testCommandList {
    AppMetr *testLibrary1 = [[AppMetr alloc] initAndStopThread];

    [testLibrary1 performSelector:@selector(setProcessedCommandWithID:) withObject:@"test-cmd-1"];
    STAssertTrue([(id <AppMetrTesting>) testLibrary1 hasProcessedCommandWithID:@"test-cmd-1"], @"Command test-cmd-1 does not exist");

    AppMetr *testLibrary2 = [[AppMetr alloc] initAndStopThread];
    STAssertTrue([(id <AppMetrTesting>) testLibrary2 hasProcessedCommandWithID:@"test-cmd-1"], @"Command test-cmd-1 does not exist");

    [testLibrary1 performSelector:@selector(setProcessedCommandWithID:) withObject:@"test-cmd-2"];
    AppMetr *testLibrary3 = [[AppMetr alloc] initAndStopThread];
    STAssertTrue([(id <AppMetrTesting>) testLibrary3 hasProcessedCommandWithID:@"test-cmd-2"], @"Command test-cmd-2 does not exist");
    STAssertFalse([(id <AppMetrTesting>) testLibrary2 hasProcessedCommandWithID:@"test-cmd-2"], @"Command test-cmd-2 already exist");
}

- (void)_testRemoteCommandPacket {
    AppMetr *testLibrary = [[AppMetr alloc] initAndStopThread];
    NSDate *now = [NSDate date];

    NSString *data = [NSString stringWithFormat:@"{\"status\":\"OK\", \"commands\":["
                                                        "{\"commandId\":\"cmd20120824112718\",\"type\":\"promo.realMoneyPurchaseBonus\", \"sendDate\":0,"
                                                        "\"conditions\":{\"validTo\":%llu},"
                                                        "\"properties\":{\"prop1\":10, \"prop2\":[1,2,3], \"prop3\":true, \"prop4\" : {\"sub1\":1, \"sub2\":2}}},"
                                                        "{\"commandId\":\"cmd30120824112718\",\"type\":\"promo.spentCurrencyDiscount\",\"sendDate\":0, \"conditions\": {\"validTo\":%llu}}],"
                                                        "\"isLastCommandsBatch\":true}",
                                                (unsigned long long) (([now timeIntervalSinceNow] * 1000) + 100000),
                                                (unsigned long long) (([now timeIntervalSinceNow] * 1000) + 100000)];
    NSDictionary *json = [[CJSONDeserializer deserializer] deserialize:[data dataUsingEncoding:NSUTF8StringEncoding] error:nil];

    STAssertNoThrow([(id <AppMetrTesting>) testLibrary processPacket:[RemoteCommandPacket packetWithSerializedObject:json andDelegate:nil]], @"Failed to process packet.");

    [testLibrary processRemoteCommands];
    STAssertEquals((NSUInteger) 2, [[(id <AppMetrTesting>) testLibrary getProcessedCommandList] count], @"Invalid numbers o commands");
    STAssertEquals((NSUInteger) 0, [[testLibrary getDirtyEventStack] count], @"Event list must be empty");
}

- (void)_testRemoteCommandWithInvalidTime {
    AppMetr *testLibrary = [[AppMetr alloc] initAndStopThread];
    NSDate *now = [NSDate date];

    NSString *data = [NSString stringWithFormat:@"{\"status\":\"OK\", \"commands\":["
                                                        "{\"commandId\":\"cmd20120824112718\",\"type\":\"promo.realMoneyPurchaseBonus\", \"sendDate\":0,"
                                                        "\"conditions\":{\"validTo\":%llu},"
                                                        "\"properties\":{\"prop1\":10, \"prop2\":[1,2,3], \"prop3\":true, \"prop4\" : {\"sub1\":1, \"sub2\":2}}},"
                                                        "{\"commandId\":\"cmd30120824112718\",\"type\":\"promo.spentCurrencyDiscount\",\"sendDate\":0, \"conditions\": {\"validTo\":%llu}}],"
                                                        "\"isLastCommandsBatch\":true}",
                                                (unsigned long long) (([now timeIntervalSinceNow] * 1000) + 100000),
                                                (unsigned long long) (([now timeIntervalSinceNow] * 1000) - 100000)];
    NSDictionary *json = [[CJSONDeserializer deserializer] deserialize:[data dataUsingEncoding:NSUTF8StringEncoding] error:nil];

    STAssertNoThrow([(id <AppMetrTesting>) testLibrary processPacket:[RemoteCommandPacket packetWithSerializedObject:json andDelegate:nil]], @"Failed to process packet.");

    [testLibrary processRemoteCommands];
    STAssertEquals((NSUInteger) 1, [[(id <AppMetrTesting>) testLibrary getProcessedCommandList] count], @"Invalid numbers o commands");
    STAssertEquals((NSUInteger) 1, [[testLibrary getDirtyEventStack] count], @"Invalid event list empty");
}

- (void)_testRemoteCommandWithDuplicateItems {
    AppMetr *testLibrary = [[AppMetr alloc] initAndStopThread];
    NSDate *now = [NSDate date];

    NSString *data = [NSString stringWithFormat:@"{\"status\":\"OK\", \"commands\":["
                                                        "{\"commandId\":\"cmd20120824112718\",\"type\":\"promo.realMoneyPurchaseBonus\", \"sendDate\":0,"
                                                        "\"conditions\":{\"validTo\":%llu},"
                                                        "\"properties\":{\"prop1\":10, \"prop2\":[1,2,3], \"prop3\":true, \"prop4\" : {\"sub1\":1, \"sub2\":2}}},"
                                                        "{\"commandId\":\"cmd30120824112718\",\"type\":\"promo.spentCurrencyDiscount\",\"sendDate\":0, \"conditions\": {\"validTo\":%llu}}],"
                                                        "\"isLastCommandsBatch\":true}",
                                                (unsigned long long) (([now timeIntervalSinceNow] * 1000) + 100000),
                                                (unsigned long long) (([now timeIntervalSinceNow] * 1000) - 100000)];
    NSDictionary *json = [[CJSONDeserializer deserializer] deserialize:[data dataUsingEncoding:NSUTF8StringEncoding] error:nil];

    STAssertNoThrow([(id <AppMetrTesting>) testLibrary processPacket:[RemoteCommandPacket packetWithSerializedObject:json andDelegate:nil]], @"Failed to process packet.");
    STAssertNoThrow([(id <AppMetrTesting>) testLibrary processPacket:[RemoteCommandPacket packetWithSerializedObject:json andDelegate:nil]], @"Failed to process packet.");

    STAssertEquals((NSUInteger) 1, [[(id <AppMetrTesting>) testLibrary getProcessedCommandList] count], @"Invalid numbers o commands");
    STAssertEquals((NSUInteger) 3, [[testLibrary getDirtyEventStack] count], @"Invalid event list empty");
}

- (void)testSendQueryRemoteCommands {
    @autoreleasepool {
        AppMetr *testLibrary = [[AppMetr alloc] initAndStopThread];

        [testLibrary performSelector:@selector(sentQueryRemoteCommandList)];
        STAssertEquals((NSUInteger) 0, [[(id <AppMetrTesting>) testLibrary getProcessedCommandList] count], @"Command list is not empty");
    }
}

- (void)testUserIdentifier {
    @autoreleasepool {
        [[AppMetr alloc] initAndStopThread];
        STAssertNotNil([AppMetr userIdentifier], @"Invalid user identifier");
    }
}

@end
