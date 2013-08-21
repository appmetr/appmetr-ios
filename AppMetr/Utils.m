/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "Utils.h"
#import "Constants.h"
#import "CJSONDeserializer.h"
#import "PAM_OpenUDID.h"
#import "JSONException.h"
#import "ServerError.h"
#import "UIDeviceUtil.h"

#import <zlib.h>

#import <UIKit/UIDevice.h>
#import <AdSupport/AdSupport.h>

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#import <CommonCrypto/CommonDigest.h>

NSString *const kMethodTrack = @"server.track";
NSString *const kMethodGetCommands = @"server.getCommands";

#define INSTANCE_INDETIFIER_TOKEN_LENGTH (8)

@implementation Utils

#pragma mark - Payment validation

+ (void)validatePayment:(NSDictionary *)payment key:(NSString *)key valueType:(Class)valueClass mandatory:(BOOL)mandatory {
    id value = [payment objectForKey:key];
    if (mandatory && !value) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Invalid payment data format. Missing mandatory argument '%@'.", key];
    }

    if (value && ![value isKindOfClass:valueClass]) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Invalid payment data. Invalid value of argument '%@'.", key];
    }
}

+ (void)validatePayment:(NSDictionary *)payment {
    [self validatePayment:payment
                      key:@"psUserSpentCurrencyCode"
                valueType:[NSString class]
                mandatory:YES];

    [self validatePayment:payment
                      key:@"psUserSpentCurrencyAmount"
                valueType:[NSNumber class]
                mandatory:YES];


    [self validatePayment:payment
                      key:@"psReceivedCurrencyCode"
                valueType:[NSString class]
                mandatory:NO];

    [self validatePayment:payment
                      key:@"psReceivedCurrencyAmount"
                valueType:[NSNumber class]
                mandatory:NO];

    [self validatePayment:payment
                      key:@"orderId"
                valueType:[NSString class]
                mandatory:NO];

    [self validatePayment:payment
                      key:@"processor"
                valueType:[NSString class]
                mandatory:NO];

    [self validatePayment:payment
                      key:@"transactionId"
                valueType:[NSString class]
                mandatory:NO];

    [self validatePayment:payment
                      key:@"appCurrencyCode"
                valueType:[NSString class]
                mandatory:NO];

    [self validatePayment:payment
                      key:@"appCurrencyAmount"
                valueType:[NSNumber class]
                mandatory:NO];
}

#pragma mark - Web

+ (NSString *)requestParametersForMethod:(NSString *)method
                                 address:(NSString *)address
                                   token:(NSString *)token
                          userIdentifier:(NSString *)userIdentifier {
    UIDevice *currentDevice = [UIDevice currentDevice];
    NSString *requestParameters;
    requestParameters = [NSString stringWithFormat:@"?timestamp=%llu&method=%@&token=%@&userId=%@&mobMac=%@"
                                                           "&mobOpenUDID=%@&mobDeviceType=%@&mobOSVer=%@&mobLibVer=%@",
                                                   [Utils timestamp], method,
                                                   [token stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                                   [userIdentifier stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                                   [Utils stringWithDeviceMACAddress],
                                                   [PAM_OpenUDID value], [UIDeviceUtil hardwareString],
                                                   [currentDevice systemVersion], kAppMetrVersionString];

#if ENABLDE_DEVICE_UNIQUE_IDENTIFIER
	// add device uniqueIdentifier
	if([currentDevice respondsToSelector:@selector(uniqueIdentifier)])
	{
		NSString *uniqueIdentifier = [currentDevice performSelector:@selector(uniqueIdentifier)];
		requestParameters = [requestParameters stringByAppendingFormat:@"&mobUDID=%@", uniqueIdentifier];
	}
#endif

    if ([currentDevice respondsToSelector:@selector(identifierForVendor)]) {
        NSString *identifierForVendor = [[currentDevice performSelector:@selector(identifierForVendor)] UUIDString];
        requestParameters = [requestParameters stringByAppendingFormat:@"&mobVendorId=%@", identifierForVendor];
    }

    Class classASIdentifierManager = NSClassFromString(@"ASIdentifierManager");
    if (classASIdentifierManager != nil) {
        NSString *advertisingIdentifier = [[[classASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        requestParameters = [requestParameters stringByAppendingFormat:@"&mobAdvId=%@", advertisingIdentifier];
    }

    NSString *fullAddress = [[address stringByAppendingString:requestParameters]
            stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    return fullAddress;
}

+ (BOOL)sendRequest:(NSString *)address
              token:(NSString *)token
     userIdentifier:(NSString *)userIdentifier
            batches:(NSData *)batches
            logging:(BOOL)logging {
    NSString *contentLength = [NSString stringWithFormat:@"%u", batches.length];
    NSString *fullAddress = [Utils requestParametersForMethod:kMethodTrack
                                                      address:address
                                                        token:token
                                               userIdentifier:userIdentifier];
    NSURL *url = [NSURL URLWithString:fullAddress];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:batches];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request setValue:contentLength forHTTPHeaderField:@"Content-Length"];

    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response error:&error];
    if (error) {
        NSLog(@"Network error: %@", error.localizedDescription);
        return NO;
    }

    if (logging) {
        NSString *responseText = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSLog(@"Request parameters: '%@' Responce: '%@'", fullAddress, responseText);
        [responseText release];
    }

    NSDictionary *serverResponse;
    @try {
        NSInteger statusCode = [(NSHTTPURLResponse *) response statusCode];
        // is HTTP error?
        if (statusCode < 400) {
            NSError *jsonError = nil;
            serverResponse = [[CJSONDeserializer deserializer] deserializeAsDictionary:responseData
                                                                                 error:&jsonError];

            if (jsonError) {
                NSLog(@"Failed to parse server response: %@", jsonError.localizedDescription);
                return NO;
            }
        }
        else {
            NSLog(@"Server error code %d", statusCode);
            return NO;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Fail to parse server response. Invalid JSON: %@", exception.description);
        return NO;
    }


    return [[[serverResponse objectForKey:@"response"] objectForKey:@"status"] isEqualToString:@"OK"];
}

+ (NSDictionary *)sendQueryRemoteCommand:(NSString *)address
                                   token:(NSString *)token
                          userIdentifier:(NSString *)userIdentifier
                   lastCommandIdentifier:(NSString *)lastCommandID
                                 logging:(BOOL)logging {
    NSString *fullAddress = [Utils requestParametersForMethod:kMethodGetCommands
                                                      address:address
                                                        token:token
                                               userIdentifier:userIdentifier];

    if (lastCommandID) {
        fullAddress = [fullAddress stringByAppendingFormat:@"&lastCommandId=%@",
                                                           [lastCommandID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }

    NSURL *url = [NSURL URLWithString:fullAddress];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:30];
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response error:&error];
    if (error) {
        NSLog(@"Network error: %@", error.localizedDescription);
        return nil;
    }

    if (logging) {
        NSString *responseText = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSLog(@"Request parameters: '%@' Responce: '%@'", fullAddress, responseText);
        [responseText release];
    }

    NSInteger statusCode = [(NSHTTPURLResponse *) response statusCode];
    // is HTTP error?
    if (statusCode >= 400) {
        [ServerError raiseWithStatusCore:statusCode];
    }

    NSString *contentType = [[(NSHTTPURLResponse *) response allHeaderFields] objectForKey:@"Content-Type"];
    if (!contentType || ![contentType isKindOfClass:[NSString class]] ||
            [contentType rangeOfString:@"application/json"].location == NSNotFound) {
        [NSException raise:@"Server Error" format:@"Invalid Content-type"];
    }

    NSError *jsonError = nil;
    NSDictionary *serverResponse = [[CJSONDeserializer deserializer] deserializeAsDictionary:responseData
                                                                                       error:&jsonError];
    if (jsonError) {
        [JSONException raiseWithError:jsonError];
    }
    return serverResponse;
}

+ (unsigned long long)timestamp {
    return (unsigned long long) ([[NSDate date] timeIntervalSince1970] * 1000.0);
}

#pragma mark - Unique identifier

+ (NSString *)createUniqueDeviceIdentifier {
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return [(NSString *) string autorelease];
}

+ (NSString *)uniqueIdentifier {
    // User ID is very important. DO NOT CHANGE IT!!!
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *ret = [preferences objectForKey:kPreferencesUniqueIdentifierKeyName];
    if (!ret || ![ret isKindOfClass:[NSString class]]) {
        // create the new UUID and write it to NSUserDefaults
        ret = [Utils createUniqueDeviceIdentifier];
        [preferences setObject:ret forKey:kPreferencesUniqueIdentifierKeyName];
        [preferences synchronize];
    }

    return ret;
}

+ (NSString *)stringWithDeviceMACAddress {

    int mib[6];
    size_t len;
    char *buf;
    unsigned char *ptr;
    struct if_msghdr *ifm;
    struct sockaddr_dl *sdl;

    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;

    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error\n");
        return NULL;
    }

    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }

    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!\n");
        return NULL;
    }

    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        free(buf);
        return NULL;
    }

    ifm = (struct if_msghdr *) buf;
    sdl = (struct sockaddr_dl *) (ifm + 1);
    ptr = (unsigned char *) LLADDR(sdl);
    NSString *ret = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X",
                                               *ptr, *(ptr + 1), *(ptr + 2), *(ptr + 3), *(ptr + 4), *(ptr + 5)];
    free(buf);

    return ret;
}

+ (NSData *)compressData:(NSData *)data {
    const uLong destinationLength = 0xff;
    void *compressedBuffer = malloc(destinationLength);

    NSMutableData *ret = [NSMutableData data];

    z_stream strm;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.next_in = (Bytef *) data.bytes;
    strm.avail_in = data.length;
    strm.next_out = compressedBuffer;
    strm.avail_out = destinationLength;

    assert(Z_OK == deflateInit2(&strm, Z_BEST_COMPRESSION, Z_DEFLATED, -15, MAX_MEM_LEVEL, Z_DEFAULT_STRATEGY));

    while (strm.avail_in != 0) {
        int res = deflate(&strm, Z_NO_FLUSH);
        assert(res == Z_OK);
        if (strm.avail_out == 0) {
            [ret appendBytes:compressedBuffer length:destinationLength];
            strm.next_out = compressedBuffer;
            strm.avail_out = destinationLength;
        }
    }

    int deflate_res = Z_OK;
    while (deflate_res == Z_OK) {
        if (strm.avail_out == 0) {
            [ret appendBytes:compressedBuffer length:destinationLength];
            strm.next_out = compressedBuffer;
            strm.avail_out = destinationLength;
        }
        deflate_res = deflate(&strm, Z_FINISH);
    }

    assert(deflate_res == Z_STREAM_END);
    [ret appendBytes:compressedBuffer length:(destinationLength - strm.avail_out)];
    deflateEnd(&strm);

    char dummy = 0;
    [ret appendBytes:&dummy length:1];

    free(compressedBuffer);
    return ret;
}

+ (NSString *)createInstanceIdentifier {
    UIDevice *currentDevice = [UIDevice currentDevice];
    if ([currentDevice respondsToSelector:@selector(identifierForVendor)]) {
        return [[currentDevice performSelector:@selector(identifierForVendor)] performSelector:@selector(UUIDString)];
    }
    return [Utils stringWithDeviceMACAddress];
}

+ (NSString *)instanceIdentifier {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *ret = [preferences objectForKey:kPreferencesUniqueInstanceIdentifierKeyName];
    if (!ret) {
        // create the new instance identifier and write them to NSUserDefaults
        ret = [Utils createInstanceIdentifier];
        [preferences setObject:ret forKey:kPreferencesUniqueInstanceIdentifierKeyName];
        [preferences synchronize];
    }

    return ret;
}

+ (NSString *)instanceIdentifierForToken:(NSString *)token {
    NSUInteger length = MIN([token length], INSTANCE_INDETIFIER_TOKEN_LENGTH);
    NSString *shortToken = nil;
    if (length) {
        shortToken = [token substringWithRange:NSMakeRange(0, length)];
    }

    NSString *instanceIdentifier = [Utils instanceIdentifier];
    if (shortToken) {
        return [shortToken stringByAppendingFormat:@":%@", instanceIdentifier];
    }

    return [NSString stringWithFormat:@":%@", instanceIdentifier];
}

+ (NSString *)md5:(NSString *)input {
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5(cStr, strlen(cStr), digest);

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];

    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }

    return output;

}

@end
