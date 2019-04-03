/**
 * Copyright (c) 2019 AppMetr.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>

@class SessionData;

NS_ASSUME_NONNULL_BEGIN

@interface UploadCacheTask : NSObject

@property (readwrite, assign) SessionData* sessionData;
@property (readwrite) BOOL logging;
-(instancetype)initWithSession:(SessionData*)session;
-(void)uploadWithAddress:(NSString*)address;

@end

NS_ASSUME_NONNULL_END
