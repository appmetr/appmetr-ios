/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>

@protocol RemoteCommandPacketDelegate <NSObject>
/**
 * Called on invalid remote commands
 */
- (BOOL)remoteCommandParsingError:(NSException *)exception;

@end

@interface RemoteCommandPacket : NSObject {
    NSMutableArray *mCommands;
    BOOL mIsLastCommandsBatch;
}

/** The list of command from server */
@property(readonly, nonatomic) NSArray *commands;

/** flag means this latest batch of commands */
@property(readonly, nonatomic) BOOL isLastCommandsBatch;

/**
 * Creating RemoteCommandPacket from JSON object
 */
+ (id)packetWithSerializedObject:(NSDictionary *)serialized andDelegate:(id)delegate;

- (id)initWithSerializedObject:(NSDictionary *)serialized andDelegate:(id)delegate;

@end
