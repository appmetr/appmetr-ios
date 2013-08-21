/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "TestRemoteCommand.h"
#import "CJSONDeserializer.h"
#import "RemoteCommand.h"

@implementation TestRemoteCommand

- (void)testFirstObject {
    NSString *data = @"{ \"commandId\" : \"cmd20120824112718\", \"sendDate\":0, \"type\" : \"promo.realMoneyPurchaseBonus\", "
            "\"conditions\": { \"validTo\":1345790143}, "
            "\"properties\": { \"prop1\" : 10, \"prop4\" : {\"sub1\":1, \"sub2\":2}}}";

    NSDictionary *json = [[CJSONDeserializer deserializer] deserialize:[data dataUsingEncoding:NSUTF8StringEncoding] error:nil];

    RemoteCommand *command = [RemoteCommand commandWithSerializedObject:json];

    STAssertEqualObjects(@"cmd20120824112718", command.uniqueIdentifier, @"Invalid commandID cmd20120824112718");
    STAssertEqualObjects(@"promo.realMoneyPurchaseBonus", command.type, @"Invalid type");

    STAssertEqualsWithAccuracy([[NSDate dateWithTimeIntervalSinceNow:(1345790143 / 1000)] timeIntervalSince1970],
    (NSTimeInterval) [command.validTo timeIntervalSince1970], 1, @"Invalid validTo");

    STAssertNotNil(command.properties, @"Invalid properties");

    // test properties
    STAssertNotNil([[command.properties objectForKey:@"properties"] objectForKey:@"prop1"], @"Invalid prop1");
    STAssertNotNil([[command.properties objectForKey:@"properties"] objectForKey:@"prop4"], @"Invalid prop4");
}

- (void)testSecondObject {
    NSString *data = @"{ \"commandId\" : \"cmd30120824112718\", \"sendDate\":0, \"type\":\"promo.spentCurrencyDiscount\", "
            "\"conditions\": {\"validTo\":1445792143}}";

    NSDictionary *json = [[CJSONDeserializer deserializer] deserialize:[data dataUsingEncoding:NSUTF8StringEncoding] error:nil];

    RemoteCommand *command = [RemoteCommand commandWithSerializedObject:json];


    STAssertEqualObjects(@"cmd30120824112718", command.uniqueIdentifier, @"Invalid commandID");
    STAssertEqualObjects(@"promo.spentCurrencyDiscount", command.type, @"Invalid type");
    STAssertEqualsWithAccuracy([[NSDate dateWithTimeIntervalSinceNow:(1445792143 / 1000)] timeIntervalSince1970],
    (NSTimeInterval) [command.validTo timeIntervalSince1970], 1, @"Invalid validTo");
    STAssertNil([command.properties objectForKey:@"properties"], @"Invalid properties");
}

- (void)testInvalidType {
    NSString *data = @"{\"commandId\" : \"cmd30120824112718\", \"conditions\": {\"validTo\":1445792143}}";
    NSDictionary *json = [[CJSONDeserializer deserializer] deserialize:[data dataUsingEncoding:NSUTF8StringEncoding] error:nil];

    STAssertThrows([RemoteCommand commandWithSerializedObject:json], @"Invalid command") ;

    NSString *message = @"";
    @try {
        [RemoteCommand commandWithSerializedObject:json];
    }
    @catch (NSException *exception) {
        message = exception.description;
    }

    STAssertTrue(([message rangeOfString:@"type"].location != NSNotFound), @"Invalid error: %@", message);
}

- (void)testInvalidCondition {
    NSString *data = @"{\"commandId\" : \"cmd30120824112718\", \"sendDate\":0, \"type\":\"promo.spentCurrencyDiscount\"}";
    NSDictionary *json = [[CJSONDeserializer deserializer] deserialize:[data dataUsingEncoding:NSUTF8StringEncoding] error:nil];

    STAssertThrows([RemoteCommand commandWithSerializedObject:json], @"Invalid command") ;

    NSString *message = @"";
    @try {
        [RemoteCommand commandWithSerializedObject:json];
    }
    @catch (NSException *exception) {
        message = exception.description;
    }

    STAssertTrue(([message rangeOfString:@"conditions"].location != NSNotFound), @"Invalid error: %@", message);
}

- (void)testInvalidValidTo {
    NSString *data = @"{\"commandId\" : \"cmd30120824112718\", \"sendDate\":0, \"type\":\"promo.spentCurrencyDiscount\",\"conditions\":{}}";
    NSDictionary *json = [[CJSONDeserializer deserializer] deserialize:[data dataUsingEncoding:NSUTF8StringEncoding] error:nil];

    STAssertThrows([RemoteCommand commandWithSerializedObject:json], @"Invalid command") ;

    NSString *message = @"";
    @try {
        [RemoteCommand commandWithSerializedObject:json];
    }
    @catch (NSException *exception) {
        message = exception.description;
    }

    STAssertTrue(([message rangeOfString:@"validTo"].location != NSNotFound), @"Invalid error: %@", message);
}

- (void)testInvalidSendDate {
    NSString *data = @"{\"commandId\" : \"cmd30120824112718\", \"type\":\"promo.spentCurrencyDiscount\",\"conditions\":{}}";
    NSDictionary *json = [[CJSONDeserializer deserializer] deserialize:[data dataUsingEncoding:NSUTF8StringEncoding] error:nil];

    STAssertThrows([RemoteCommand commandWithSerializedObject:json], @"Invalid command") ;

    NSString *message = @"";
    @try {
        [RemoteCommand commandWithSerializedObject:json];
    }
    @catch (NSException *exception) {
        message = exception.description;
    }

    STAssertTrue(([message rangeOfString:@"sendDate"].location != NSNotFound), @"Invalid error: %@", message);
}

@end
