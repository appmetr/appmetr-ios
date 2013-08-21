/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "RemoteCommand.h"

#pragma mark - Private category
@interface RemoteCommand ()
- (void)validateParameter:(id <NSObject>)parameter name:(NSString *)name requiredClass:(Class)requiredClass;
@end

@implementation RemoteCommand

#pragma mark - Properties

@synthesize uniqueIdentifier = mCommandID;
@synthesize type = mType;
@synthesize validTo = mValidTo;
@synthesize properties = mProperties;

#pragma mark - Constructor & destructor

+ (id)commandWithSerializedObject:(NSDictionary *)serialized; {
    RemoteCommand *ret = [self alloc];
    @try {
        [ret initWithSerializedObject:serialized];
    }
    @catch (NSException *exception) {
        [ret release], ret = nil;
        // re-throw
        @throw exception;
    }

    return [ret autorelease];
}

- (id)initWithSerializedObject:(NSDictionary *)serialized {
    self = [super init];
    if (self) {
        if (![serialized isKindOfClass:[NSDictionary class]]) {
            [NSException raise:@"invalidFormat" format:@"command is not an object"];
        }

        mCommandID = [[serialized objectForKey:@"commandId"] retain];
        if (!mCommandID || ![mCommandID isKindOfClass:[NSString class]]) {
            [NSException raise:@"invalidFormat" format:@"Batch does not contain valid 'commandId'"];
        }

        mType = [[serialized objectForKey:@"type"] retain];
        [self validateParameter:mType name:@"type" requiredClass:[NSString class]];

        NSNumber *sendDateValue = [serialized objectForKey:@"sendDate"];
        [self validateParameter:sendDateValue name:@"sendDate" requiredClass:[NSNumber class]];

        NSDictionary *conditions = [serialized objectForKey:@"conditions"];
        [self validateParameter:conditions name:@"conditions" requiredClass:[NSDictionary class]];

        NSNumber *validToValue = [[serialized objectForKey:@"conditions"] objectForKey:@"validTo"];
        [self validateParameter:validToValue name:@"validTo" requiredClass:[NSNumber class]];

        unsigned long long sendDate = [sendDateValue unsignedLongLongValue] / 1000;
        unsigned long long validTo = [validToValue unsignedLongLongValue] / 1000;

        mValidTo = [[NSDate alloc] initWithTimeIntervalSinceNow:(validTo - sendDate)];

        // attach command object instead of properties
        mProperties = [serialized retain];
    }

    return self;
}

- (void)dealloc {
    [mCommandID release];
    [mType release];
    [mValidTo release];
    [mProperties release];

    [super dealloc];
}

#pragma mark - Private methods

- (void)validateParameter:(id <NSObject>)parameter name:(NSString *)name requiredClass:(Class)requiredClass {
    if (!parameter || ![parameter isKindOfClass:requiredClass]) {
        [NSException raise:@"invalidFormat"
                    format:@"Batch does not contain valid '%@' for command: %@", name, mCommandID];
    }
}

@end
