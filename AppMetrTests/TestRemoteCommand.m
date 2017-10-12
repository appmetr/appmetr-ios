/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "TestRemoteCommand.h"
#import "CJSONDeserializer.h"
#import "RemoteCommand.h"

@implementation TestRemoteCommand

- (void)testFirstObject {
    NSString *data = @"{ \"status\":\"OK\", \"commandId\" : \"cmd20120824112718\", \"sendDate\":0, \"type\" : \"promo.realMoneyPurchaseBonus\", "
            "\"conditions\": { \"validTo\":1345790143}, "
            "\"properties\": { \"prop1\" : 10, \"prop4\" : {\"sub1\":1, \"sub2\":2}}}";

    NSDictionary *json = [[AMCJSONDeserializer deserializer] deserialize:[data dataUsingEncoding:NSUTF8StringEncoding] error:nil];

    RemoteCommand *command = [RemoteCommand commandWithSerializedObject:json];

    XCTAssertEqualObjects(@"cmd20120824112718", command.uniqueIdentifier, @"Invalid commandID cmd20120824112718");
    XCTAssertEqualObjects(@"promo.realMoneyPurchaseBonus", command.type, @"Invalid type");

    XCTAssertEqualWithAccuracy([[NSDate dateWithTimeIntervalSinceNow:(1345790143 / 1000)] timeIntervalSince1970],
    (NSTimeInterval) [command.validTo timeIntervalSince1970], 1, @"Invalid validTo");

    XCTAssertNotNil(command.properties, @"Invalid properties");

    // test properties
    XCTAssertNotNil([[command.properties objectForKey:@"properties"] objectForKey:@"prop1"], @"Invalid prop1");
    XCTAssertNotNil([[command.properties objectForKey:@"properties"] objectForKey:@"prop4"], @"Invalid prop4");
}

- (void)testSecondObject {
    NSString *data = @"{ \"status\":\"OK\", \"commandId\" : \"cmd30120824112718\", \"sendDate\":0, \"type\":\"promo.spentCurrencyDiscount\", "
            "\"conditions\": {\"validTo\":1445792143}}";

    NSDictionary *json = [[AMCJSONDeserializer deserializer] deserialize:[data dataUsingEncoding:NSUTF8StringEncoding] error:nil];

    RemoteCommand *command = [RemoteCommand commandWithSerializedObject:json];


    XCTAssertEqualObjects(@"cmd30120824112718", command.uniqueIdentifier, @"Invalid commandID");
    XCTAssertEqualObjects(@"promo.spentCurrencyDiscount", command.type, @"Invalid type");
    XCTAssertEqualWithAccuracy([[NSDate dateWithTimeIntervalSinceNow:(1445792143 / 1000)] timeIntervalSince1970],
    (NSTimeInterval) [command.validTo timeIntervalSince1970], 1, @"Invalid validTo");
    XCTAssertNil([command.properties objectForKey:@"properties"], @"Invalid properties");
}

- (void)testInvalidCommandId {
    NSString *data = @"{\"status\": \"OK\", \"type\": \"promo.spentCurrencyDiscount\", \"sendDate\": 0, \"conditions\": {\"validTo\": 1345790143}}";
    NSDictionary *json = [[AMCJSONDeserializer deserializer] deserialize:[data dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    
    XCTAssertThrows([RemoteCommand commandWithSerializedObject:json], @"Invalid command") ;
    
    NSString *message = @"";
    @try {
        [RemoteCommand commandWithSerializedObject:json];
    }
    @catch (NSException *exception) {
        message = exception.description;
    }
    
    XCTAssertTrue(([message rangeOfString:@"commandId"].location != NSNotFound), @"Invalid error: %@", message);
}

- (void)testInvalidStatus {
    NSString *data = @"{\"commandId\": \"cmd30120824112718\", \"type\": \"promo.spentCurrencyDiscount\", \"sendDate\": 0, \"conditions\": {\"validTo\": 1345790143}}";
    NSDictionary *json = [[AMCJSONDeserializer deserializer] deserialize:[data dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    
    XCTAssertThrows([RemoteCommand commandWithSerializedObject:json], @"Invalid command") ;
    
    NSString *message = @"";
    @try {
        [RemoteCommand commandWithSerializedObject:json];
    }
    @catch (NSException *exception) {
        message = exception.description;
    }
    
    XCTAssertTrue(([message rangeOfString:@"status"].location != NSNotFound), @"Invalid error: %@", message);
}

- (void)testInvalidType {
    NSString *data = @"{\"commandId\": \"cmd30120824112718\", \"status\": \"OK\", \"sendDate\": 0, \"conditions\": {\"validTo\": 1445792143}}";
    NSDictionary *json = [[AMCJSONDeserializer deserializer] deserialize:[data dataUsingEncoding:NSUTF8StringEncoding] error:nil];

    XCTAssertThrows([RemoteCommand commandWithSerializedObject:json], @"Invalid command") ;

    NSString *message = @"";
    @try {
        [RemoteCommand commandWithSerializedObject:json];
    }
    @catch (NSException *exception) {
        message = exception.description;
    }

    XCTAssertTrue(([message rangeOfString:@"type"].location != NSNotFound), @"Invalid error: %@", message);
}

- (void)testInvalidConditions {
    NSString *data = @"{\"commandId\": \"cmd30120824112718\", \"status\": \"OK\", \"type\": \"promo.spentCurrencyDiscount\", \"sendDate\": 0}";
    NSDictionary *json = [[AMCJSONDeserializer deserializer] deserialize:[data dataUsingEncoding:NSUTF8StringEncoding] error:nil];

    XCTAssertThrows([RemoteCommand commandWithSerializedObject:json], @"Invalid command") ;

    NSString *message = @"";
    @try {
        [RemoteCommand commandWithSerializedObject:json];
    }
    @catch (NSException *exception) {
        message = exception.description;
    }

    XCTAssertTrue(([message rangeOfString:@"conditions"].location != NSNotFound), @"Invalid error: %@", message);
}

- (void)testInvalidValidTo {
    NSString *data = @"{\"commandId\": \"cmd30120824112718\", \"status\": \"OK\", \"type\": \"promo.spentCurrencyDiscount\", \"sendDate\": 0, \"conditions\": {}}";
    NSDictionary *json = [[AMCJSONDeserializer deserializer] deserialize:[data dataUsingEncoding:NSUTF8StringEncoding] error:nil];

    XCTAssertThrows([RemoteCommand commandWithSerializedObject:json], @"Invalid command") ;

    NSString *message = @"";
    @try {
        [RemoteCommand commandWithSerializedObject:json];
    }
    @catch (NSException *exception) {
        message = exception.description;
    }

    XCTAssertTrue(([message rangeOfString:@"validTo"].location != NSNotFound), @"Invalid error: %@", message);
}

- (void)testInvalidSendDate {
    NSString *data = @"{\"commandId\": \"cmd30120824112718\", \"status\": \"OK\", \"type\": \"promo.spentCurrencyDiscount\", \"conditions\": {\"validTo\": 1345790143}}";
    NSDictionary *json = [[AMCJSONDeserializer deserializer] deserialize:[data dataUsingEncoding:NSUTF8StringEncoding] error:nil];

    XCTAssertThrows([RemoteCommand commandWithSerializedObject:json], @"Invalid command") ;

    NSString *message = @"";
    @try {
        [RemoteCommand commandWithSerializedObject:json];
    }
    @catch (NSException *exception) {
        message = exception.description;
    }

    XCTAssertTrue(([message rangeOfString:@"sendDate"].location != NSNotFound), @"Invalid error: %@", message);
}

@end
