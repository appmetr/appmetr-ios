/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "AppMetr.h"
#import "CJSONDeserializer.h"
#import "TrackingManager.h"
#import "AMBase64Util.h"

// Global variables
TrackingManager *gSharedManager = nil;

#pragma mark - Class implementation

@implementation AppMetr

#pragma mark - Manage shared instance

+ (TrackingManager *)sharedManager {
    if (!gSharedManager) {
        gSharedManager = [[TrackingManager alloc] init];
    }

    return gSharedManager;
}

#pragma mark - Setting up

+ (void)setupWithToken:(NSString *)token {
    [AppMetr setupWithToken:token delegate:nil];
}

+ (void)setupWithToken:(NSString *)token delegate:(id)delegate {
    [AppMetr setupWithToken:token delegate:delegate commandsThread:[NSThread currentThread]];
}

+ (void)setupWithToken:(NSString *)token delegate:(id)delegate commandsThread:(NSThread *)thread {
    [[AppMetr sharedManager] setupWithToken:token delegate:delegate commandsThread:thread];
}

+ (void)setupSizeLimitOfCacheFile:(NSUInteger)limit {
    [[AppMetr sharedManager] setupSizeLimitOfCacheFile:limit];
}

#pragma mark - Class (lazy)methods

+ (void)attachProperties {
    [[AppMetr sharedManager] attachProperties:nil];
}

+ (void)attachProperties:(NSDictionary *)properties {
    [[AppMetr sharedManager] attachProperties:properties];
}

+ (void)trackSession {
    [[AppMetr sharedManager] trackSession];
}

+ (void)trackSessionWithProperties:(NSDictionary *)properties {
    [[AppMetr sharedManager] trackSessionWithProperties:properties];
}

+ (void)trackLevel:(int)level {
    [[AppMetr sharedManager] trackLevel:level];
}

+ (void)trackLevel:(int)level properties:(NSDictionary *)properties {
    [[AppMetr sharedManager] trackLevel:level properties:properties];
}

+ (void)trackEvent:(NSString *)trackEvent {
    [[AppMetr sharedManager] trackEvent:trackEvent];
}

+ (void)trackEvent:(NSString *)event properties:(NSDictionary *)properties {
    [[AppMetr sharedManager] trackEvent:event properties:properties];
}

+ (void)trackPayment:(NSDictionary *)payment {
    [[AppMetr sharedManager] trackPayment:payment];
}

+ (void)trackPayment:(NSDictionary *)payment properties:(NSDictionary *)properties {
    [[AppMetr sharedManager] trackPayment:payment properties:properties];
}

+ (void)trackAdsEvent:(NSString *)event {
    [[AppMetr sharedManager] trackAdsEvent:event];
}

+ (void)trackInstallURL:(NSURL *)url {
    [[AppMetr sharedManager] trackInstallURL:url];
}

+ (void)trackOptions:(NSArray *)options forCommand:(NSString *)commandId {
    [[AppMetr sharedManager] trackOptions:options forCommand:commandId];
}

+ (void)trackOptions:(NSArray *)options forCommand:(NSString *)commandId errorCode:(NSString *)code errorMessage:(NSString *)message {
    [[AppMetr sharedManager] trackOptions:options forCommand:commandId errorCode:code errorMessage:message];
}

+ (void)trackExperimentStart:(NSString *)experiment group:(NSString *)group {
    [[AppMetr sharedManager] trackExperimentStart:experiment group:group];
}

+ (void)trackExperimentEnd:(NSString *)experiment {
    [[AppMetr sharedManager] trackExperimentEnd:experiment];
}

+ (void)trackState:(NSDictionary *)state {
    [[AppMetr sharedManager] trackState:state];
}

+ (void)identify:(NSString *)userId {
    [[AppMetr sharedManager] identify:userId];
}

+ (BOOL)verifyPayment:(SKPaymentTransaction *)transaction privateKey:(NSString *)privateKey {
    return [[AppMetr sharedManager] verifyPaymentWithProductId:transaction.payment.productIdentifier
                                                 transactionId:transaction.transactionIdentifier
                                                       receipt:[AMBase64Util encode:[transaction transactionReceipt]]
                                                    privateKey:privateKey];
}

+ (BOOL)verifyPaymentWithProductId:(NSString *)productId transactionId:(NSString *)transactionId receipt:(NSString *)base64EncodedReceipt privateKey:(NSString *)privateKey {
    return [[AppMetr sharedManager] verifyPaymentWithProductId:productId
                                                 transactionId:transactionId
                                                       receipt:base64EncodedReceipt
                                                    privateKey:privateKey];
}

+ (void)pullCommands {
    [[AppMetr sharedManager] pullCommands];
}

+ (void)flush {
    [[AppMetr sharedManager] flushAndUploadAllEvents];
}

+ (void)setCommandThread:(NSThread *)thread {
    [[AppMetr sharedManager] setCommandThread:thread];
}

+ (void)setDebugLoggingEnabled:(BOOL)debugLoggingEnabled {
    [[AppMetr sharedManager] setDebugLoggingEnabled:debugLoggingEnabled];
}

+ (BOOL)isDebugLoggingEnabled {
    return [[AppMetr sharedManager] isDebugLoggingEnabled];
}

+ (NSString *)instanceIdentifier {
    return [[AppMetr sharedManager] instanceIdentifier];
}

+ (NSDictionary *)stringToDictionary:(NSString *)json {
    NSError *deserializeError = nil;
    NSDictionary *result = [[AMCJSONDeserializer deserializer] deserializeAsDictionary:[json dataUsingEncoding:NSUTF8StringEncoding] error:&deserializeError];

    if (deserializeError) {
        NSLog(@"JSON deserializer error: %@", deserializeError.description);
        [NSException raise:NSGenericException
                    format:@"%@", deserializeError.description];
    }

    return result;
}

+ (NSArray *)stringToArray:(NSString *)json {
    NSError *deserializeError = nil;
    NSArray *result = [[AMCJSONDeserializer deserializer] deserializeAsArray:[json dataUsingEncoding:NSUTF8StringEncoding] error:&deserializeError];

    if (deserializeError) {
        NSLog(@"JSON deserializer error: %@", deserializeError.description);
        [NSException raise:NSGenericException
                    format:@"%@", deserializeError.description];
    }

    return result;
}

@end
