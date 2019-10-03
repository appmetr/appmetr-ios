/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "AppMetr.h"
#import "CJSONDeserializer.h"
#import "TrackingManager.h"
#import "AMBase64Util.h"

NSString *const kAppmetrPropertyTimestamp = @"timestamp";
NSString *const kAppmetrPropertyUsertime = @"userTime";


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
    [[AppMetr sharedManager] setupWithToken:token];
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

+ (void)attachEntityAttributesForName:(NSString*)name value:(NSString*)value withProperies:(NSDictionary*)properties {
    [[AppMetr sharedManager] attachEntityAttributesForName:name value:value withProperies:properties];
}

+ (void)flush {
    [[AppMetr sharedManager] flushAndUploadAllEvents];
}

+ (void)flushLocal {
    [[AppMetr sharedManager] flushAllEvents];
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

+ (NSString *)deviceKey {
    return [[AppMetr sharedManager] deviceKey];
}

+ (NSDictionary *)stringToDictionary:(NSString *)json {
    NSError *deserializeError = nil;
    NSDictionary *result = [[AMCJSONDeserializer deserializer] deserializeAsDictionary:[json dataUsingEncoding:NSUTF8StringEncoding] error:&deserializeError];

    if (deserializeError) {
        NSLog(@"JSON deserializer error: %@", deserializeError.description);
    }

    return result;
}

+ (NSArray *)stringToArray:(NSString *)json {
    NSError *deserializeError = nil;
    NSArray *result = [[AMCJSONDeserializer deserializer] deserializeAsArray:[json dataUsingEncoding:NSUTF8StringEncoding] error:&deserializeError];

    if (deserializeError) {
        NSLog(@"JSON deserializer error: %@", deserializeError.description);
    }

    return result;
}

@end
