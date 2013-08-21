/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "TestRemoteCommandPacket.h"
#import "CJSONDeserializer.h"
#import "RemoteCommandPacket.h"

@implementation TestRemoteCommandPacket

- (void)testParsing {
    NSString *data1 = @"{\"status\":\"OK\", \"commands\":["
            "{\"commandId\":\"cmd20120824112718\",\"type\":\"promo.realMoneyPurchaseBonus\", \"sendDate\":0,"
            "\"conditions\":{\"validTo\":1345790143},"
            "\"properties\":{\"prop1\":10, \"prop2\":[1,2,3], \"prop3\":true, \"prop4\" : {\"sub1\":1, \"sub2\":2}}},"
            "{\"commandId\":\"cmd30120824112718\",\"type\":\"promo.spentCurrencyDiscount\",\"sendDate\":0,\"conditions\": {\"validTo\":1345792143}}],"
            "\"isLastCommandsBatch\":true}";

    NSDictionary *json1 = [[CJSONDeserializer deserializer] deserialize:[data1 dataUsingEncoding:NSUTF8StringEncoding] error:nil];


    RemoteCommandPacket *packet1 = [RemoteCommandPacket packetWithSerializedObject:json1 andDelegate:nil];

    STAssertEquals((NSUInteger) 2, [packet1.commands count], @"Invalid commands");
    STAssertTrue(packet1.isLastCommandsBatch, @"Invalid isLastCommandsBatch");

    NSString *data2 = @"{\"status\":\"OK\", \"commands\":["
            "{\"commandId\":\"cmd20120824112718\",\"type\":\"promo.realMoneyPurchaseBonus\",\"sendDate\":0,"
            "\"conditions\":{\"validTo\":1345790143},"
            "\"properties\":{\"prop1\":10, \"prop2\":[1,2,3], \"prop3\":true, \"prop4\" : {\"sub1\":1, \"sub2\":2}}}],"
            "\"isLastCommandsBatch\":false}";

    NSDictionary *json2 = [[CJSONDeserializer deserializer] deserialize:[data2 dataUsingEncoding:NSUTF8StringEncoding] error:nil];

    RemoteCommandPacket *packet2 = [RemoteCommandPacket packetWithSerializedObject:json2 andDelegate:nil];
    STAssertEquals((NSUInteger) 1, [packet2.commands count], @"Invalid commands");
    STAssertFalse(packet2.isLastCommandsBatch, @"Invalid isLastCommandsBatch");
}

- (void)testArrayError {
    NSString *data = @"{\"status\":\"OK\",\"isLastCommandsBatch\":true,\"commands\":"
            "[{\"conditions\":{\"validTo\":1348839789157},\"status\":\"not_sent\","
            "\"commandId\":\"00000001348839956434#00000000005523218873\",\"sendDate\":0,\"properties\":{},\"modifyDate\":1348839956434,"
            "\"createDate\":1348839956434,\"type\":\"enableBuiltInPromos\"}]}";

    NSDictionary *json = [[CJSONDeserializer deserializer] deserialize:[data dataUsingEncoding:NSUTF8StringEncoding] error:nil];


    RemoteCommandPacket *packet = [RemoteCommandPacket packetWithSerializedObject:json andDelegate:nil];

    STAssertEquals((NSUInteger) 1, [packet.commands count], @"Invalid commands");
    STAssertTrue(packet.isLastCommandsBatch, @"Invalid isLastCommandsBatch");
}

@end
