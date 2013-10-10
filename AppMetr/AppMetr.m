/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "AppMetr.h"

// Global variables
AppMetr *gSharedAppMetrMobile = nil;

#pragma mark - Class implementation

@implementation AppMetr

#pragma mark - Manage shared instance

+ (AppMetr *)sharedInstance {
    if (!gSharedAppMetrMobile) {
        gSharedAppMetrMobile = [[AppMetr alloc] init];
    }

    return gSharedAppMetrMobile;
}

#pragma mark - Setting up

+ (void)setupWithToken:(NSString *)token {
    [AppMetr setupWithToken:token delegate:nil];
}

+ (void)setupWithToken:(NSString *)token delegate:(id)delegate {
    [AppMetr setupWithToken:token delegate:delegate commandsThread:[NSThread currentThread]];
}

+ (void)setupWithToken:(NSString *)token delegate:(id)delegate commandsThread:(NSThread *)thread {
    AppMetr *instance = [AppMetr sharedInstance];
    [instance setupWithToken:token delegate:delegate commandsThread:thread];
}

+ (void)setupSizeLimitOfCacheFile:(NSUInteger)limit {
    [[AppMetr sharedInstance] setupSizeLimitOfCacheFile:limit];
}

+ (void)setupWithUserID:(NSString *)userID {
    [[AppMetr sharedInstance] setupWithUserID:userID];
}

#pragma mark - Class (lazy)methods

+ (void)attachProperties {
    [[AppMetr sharedInstance] attachProperties:nil];
}

+ (void)attachProperties:(NSDictionary *)properties {
    [[AppMetr sharedInstance] attachProperties:properties];
}

+ (void)trackSession {
    [[AppMetr sharedInstance] trackSession];
}

+ (void)trackSessionWithProperties:(NSDictionary *)properties {
    [[AppMetr sharedInstance] trackSessionWithProperties:properties];
}

+ (void)trackLevel:(int)level {
    [[AppMetr sharedInstance] trackLevel:level];
}

+ (void)trackLevel:(int)level properties:(NSDictionary *)properties {
    [[AppMetr sharedInstance] trackLevel:level properties:properties];
}

+ (void)trackEvent:(NSString *)trackEvent {
    [[AppMetr sharedInstance] trackEvent:trackEvent];
}

+ (void)trackEvent:(NSString *)event properties:(NSDictionary *)properties {
    [[AppMetr sharedInstance] trackEvent:event properties:properties];
}

+ (void)trackPayment:(NSDictionary *)payment {
    [[AppMetr sharedInstance] trackPayment:payment];
}

+ (void)trackPayment:(NSDictionary *)payment properties:(NSDictionary *)properties {
    [[AppMetr sharedInstance] trackPayment:payment properties:properties];
}

+ (void)trackGameState:(NSString *)state properties:(NSDictionary *)properties {
    [[AppMetr sharedInstance] trackGameState:state properties:properties];
}

+ (void)trackInstallURL:(NSURL *)url {
    [[AppMetr sharedInstance] trackInstallURL:url];
}

+ (void)trackOptions:(NSDictionary *)options forCommand:(NSString *)commandId {
    [[AppMetr sharedInstance] trackOptions:options forCommand:commandId];
}

+ (void)trackOptions:(NSDictionary *)options forCommand:(NSString *)commandId errorCode:(NSString *)code errorMessage:(NSString *)message {
    [[AppMetr sharedInstance] trackOptions:options forCommand:commandId errorCode:code errorMessage:message];
}

+ (void)trackExperimentStart:(NSString *)experiment group:(NSString *)group {
    [[AppMetr sharedInstance] trackExperimentStart:experiment group:group];
}

+ (void)trackExperimentEnd:(NSString *)experiment {
    [[AppMetr sharedInstance] trackExperimentEnd:experiment];
}

+ (void)identify:(NSString *)userId {
    [[AppMetr sharedInstance] identify:userId];
}

+ (void)pullCommands {
    [[AppMetr sharedInstance] pullCommands];
}

+ (void)flush {
    [[AppMetr sharedInstance] flushAndUploadAllEvents];
}

+ (NSString *)userIdentifier {
    return [[AppMetr sharedInstance] userIdentifier];
}

+ (void)setCommandThread:(NSThread *)thread {
    [[AppMetr sharedInstance] setCommandThread:thread];
}

+ (void)setDebugLoggingEnabled:(BOOL)debugLoggingEnabled {
    [[AppMetr sharedInstance] setDebugLoggingEnabled:debugLoggingEnabled];
}

+ (BOOL)isDebugLoggingEnabled {
    return [[AppMetr sharedInstance] isDebugLoggingEnabled];
}

+ (NSString *)instanceIdentifier {
    return [[AppMetr sharedInstance] instanceIdentifier];
}

@end
