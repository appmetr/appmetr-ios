/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "RemoteCommandPacket.h"
#import "RemoteCommand.h"

@implementation RemoteCommandPacket

#pragma mark - Properties

@synthesize commands = mCommands;
@synthesize isLastCommandsBatch = mIsLastCommandsBatch;

#pragma mark - Initializing and deallocing

+ (id)packetWithSerializedObject:(NSDictionary *)serialized andDelegate:(id)delegate {
    RemoteCommandPacket *ret = [self alloc];
    @try {
        [ret initWithSerializedObject:serialized andDelegate:delegate];
    }
    @catch (NSException *exception) {
        [ret release];

        // re-throw
        @throw exception;
    }
    return [ret autorelease];
}

- (id)initWithSerializedObject:(NSDictionary *)serialized andDelegate:(id)delegate {
    self = [super init];
    if (self) {
        // every packet must have status OK
        NSAssert([[serialized objectForKey:@"status"] isEqualToString:@"OK"], @"Invalid status");

        NSArray *commandList = [serialized objectForKey:@"commands"];
        if (!commandList || ![commandList isKindOfClass:[NSArray class]]) {
            [NSException raise:@"invalidFormat" format:@"'Batch does not contain valid 'commands' key."];
        }

        mCommands = [[NSMutableArray alloc] initWithCapacity:[commandList count]];

        for (NSDictionary *serializedCommand in commandList) {
            @try {
                [mCommands addObject:[RemoteCommand commandWithSerializedObject:serializedCommand]];
            }
            @catch (NSException *exception) {
                if (![(id <RemoteCommandPacketDelegate>) delegate remoteCommandParsingError:exception]) {
                    // re-throw
                    @throw exception;
                }
            }
        }

        mIsLastCommandsBatch = [[serialized objectForKey:@"isLastCommandsBatch"] boolValue];
    }

    return self;
}

- (void)dealloc {
    [mCommands release];
    [super dealloc];
}

@end
