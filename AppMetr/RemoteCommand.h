/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface RemoteCommand : NSObject {
    NSString *mCommandID;
    NSString *mStatus;
    NSString *mType;
    NSDate *mValidTo;
    NSDictionary *mProperties;
}

/** unique identifier of this command */
@property(readonly, nonatomic) NSString *uniqueIdentifier;

/** command status */
@property(readonly, nonatomic) NSString *status;

/** command type */
@property(readonly, nonatomic) NSString *type;

/** date, the latest of which command can run */
@property(readonly, nonatomic) NSDate *validTo;

/** properties of command */
@property(readonly, nonatomic) NSDictionary *properties;

/**
 *  Creating the AppMetr remote command
 */
+ (id)commandWithSerializedObject:(NSDictionary *)serialized;

- (id)initWithSerializedObject:(NSDictionary *)serialized;

@end
