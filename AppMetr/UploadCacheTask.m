/**
 * Copyright (c) 2019 AppMetr.
 * All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "UploadCacheTask.h"
#import "SessionData.h"
#import "CJSONDeserializer.h"

NSString *const kAppmetrBackgroundSessionIdentifier = @"com.appmetr.BackgroundSession";

@interface UploadCacheTask() <NSURLSessionDataDelegate>

+(void)load;
@property (readonly, getter=backgroundSession) NSURLSession* backgroundSession;

@end

@implementation UploadCacheTask

static NSMutableDictionary<NSNumber*, NSString*>* appmetrUploadTasks;

@synthesize sessionData, logging;

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appmetrUploadTasks = [[NSMutableDictionary alloc] init];
    });
}

-(instancetype)initWithSession:(SessionData *)session
{
    if ( (self = [super init]) )
    {
        self.sessionData = session;
        self.logging = NO;
    }
    return self;
}

-(void)uploadWithAddress:(NSString*)address
{
    if(self.sessionData == nil) {
        NSLog(@"Session data is null. Upload canceled");
        return;
    }
    
    NSArray* fileList;
    NSArray* uploadList;
    @synchronized (self.sessionData) {
        fileList = [self.sessionData.fileList mutableCopy];
        uploadList = [self.sessionData.uploadList mutableCopy];
    }
    
    for (NSString* filePath in fileList) {
        [self processFile:filePath withAddress:address];
    }
    for(NSData* uploadData in uploadList) {
        [self processData:uploadData withAddress:address];
    }
}

-(void)processFile:(NSString*)fileName withAddress:(NSString*)address
{
    // check if task already exists
    if([appmetrUploadTasks.allValues containsObject:fileName])
        return;
    
    NSError* error = nil;
    if (self.logging) {
        NSLog(@"uploadData: Batches: %@", [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:&error]);
    }
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
        NSLog(@"File not exists: %@. Skipping", fileName);
        if(self.sessionData != nil) {
            @synchronized (self.sessionData) {
                [self.sessionData.fileList removeObject:fileName];
                [self.sessionData saveFileList];
            }
        }
        return;
    }
    
    NSURL *url = [NSURL URLWithString:address];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    NSURLSessionDataTask* task = [self.backgroundSession uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:fileName]];
    appmetrUploadTasks[[self getIdForTask:task]] = fileName;
    [task resume];
}

-(void)processData:(NSData*)uploadData withAddress:(NSString*)address
{
    if(uploadData == nil || uploadData.length == 0) return;
    NSURL *url = [NSURL URLWithString:address];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [[[NSURLSession sharedSession] uploadTaskWithRequest:request fromData:uploadData completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error) {
            NSLog(@"Failed to upload batch directly: %@", error.localizedDescription);
            return;
        }
        if (self.logging && data != nil) {
            NSString *responseText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"Request parameters: '%@' Response: '%@'", [request.URL absoluteString], responseText);
            [responseText release];
        }
        @try {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            // is HTTP error?
            if(statusCode >= 400) {
                NSLog(@"Server error code %d", (int)statusCode);
            } else if(data == nil) {
                NSLog(@"Server returned empty response");
            } else {
                NSError *jsonError = nil;
                NSDictionary *serverResponse = [[AMCJSONDeserializer deserializer] deserializeAsDictionary:data error:&jsonError];
                if (jsonError) {
                    NSLog(@"Failed to parse server response: %@", jsonError.localizedDescription);
                } else {
                    NSString* status = [[serverResponse objectForKey:@"response"] objectForKey:@"status"];
                    if([status isEqualToString:@"OK"]) {
                        if(self.sessionData != nil) {
                            @synchronized (self.sessionData) {
                                [self.sessionData.uploadList removeObject:uploadData];
                            }
                        }
                    }
                }
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Fail to parse server response. Invalid JSON: %@", exception.description);
        }
        
    }] resume];
}

- (NSURLSession *)backgroundSession {
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *sessionConfiguration;
        if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
            sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kAppmetrBackgroundSessionIdentifier];
        else
            sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:kAppmetrBackgroundSessionIdentifier];
        sessionConfiguration.sessionSendsLaunchEvents = NO;
        sessionConfiguration.allowsCellularAccess = YES;
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 1;
        session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    });
    return session;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    if(![dataTask.response isKindOfClass:[NSHTTPURLResponse class]])
        return;
    
    if (self.logging && data != nil) {
        NSString *responseText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Request parameters: '%@' Response: '%@'", [dataTask.originalRequest.URL absoluteString], responseText);
        [responseText release];
    }
    
    @try {
        NSInteger statusCode = [(NSHTTPURLResponse *) dataTask.response statusCode];
        // is HTTP error?
        if(statusCode >= 400) {
            NSLog(@"Server error code %d", (int)statusCode);
        } else if(data == nil) {
            NSLog(@"Server returned empty response");
        } else {
            NSError *jsonError = nil;
            NSDictionary *serverResponse = [[AMCJSONDeserializer deserializer] deserializeAsDictionary:data error:&jsonError];
            if (jsonError) {
                NSLog(@"Failed to parse server response: %@", jsonError.localizedDescription);
            } else {
                NSString* status = [[serverResponse objectForKey:@"response"] objectForKey:@"status"];
                if([status isEqualToString:@"OK"]) {
                    NSString* fileName = [self fileNameForTask:dataTask];
                    if(fileName != nil && fileName.length > 0) {
                        NSError *fileError = nil;
                        [[NSFileManager defaultManager] removeItemAtPath:fileName error:&fileError];
                        if (fileError) {
                            NSLog(@"Failed to delete file. Reason: %@", fileError.localizedDescription);
                        }
                        if(self.sessionData != nil) {
                            @synchronized (self.sessionData) {
                                [self.sessionData.fileList removeObject:fileName];
                                [self.sessionData saveFileList];
                            }
                        }
                    }
                }
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Fail to parse server response. Invalid JSON: %@", exception.description);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    if (error) {
        NSLog(@"Network error: %@", error.localizedDescription);
    }
    [appmetrUploadTasks removeObjectForKey:[self getIdForTask:task]];
}

#pragma mark - Private functions

- (NSNumber*)getIdForTask:(NSURLSessionTask*)task
{
    return [NSNumber numberWithUnsignedLong:task.taskIdentifier];
}

- (NSString*)fileNameForTask:(NSURLSessionTask*)task
{
    id taskId = [self getIdForTask:task];
    if([appmetrUploadTasks objectForKey:taskId])
        return appmetrUploadTasks[taskId];
    else
        return nil;
}

@end
