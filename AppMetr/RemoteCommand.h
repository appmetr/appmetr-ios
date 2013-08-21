/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface RemoteCommand : NSObject {
    NSString *mCommandID;
    NSString *mType;
    NSDate *mValidTo;
    NSDictionary *mProperties;
}

/** the unique identifier of this command */
@property(readonly, nonatomic) NSString *uniqueIdentifier;

/** the type of this command */
@property(readonly, nonatomic) NSString *type;

/** the date, the latest of which this command can run */
@property(readonly, nonatomic) NSDate *validTo;

/** the parameter of this command */
@property(readonly, nonatomic) NSDictionary *properties;

/**
 *  Creating the AppMetr remote command
 */
+ (id)commandWithSerializedObject:(NSDictionary *)serialized;

- (id)initWithSerializedObject:(NSDictionary *)serialized;

@end
