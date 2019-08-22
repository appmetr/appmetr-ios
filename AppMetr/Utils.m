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
#import "MurmurHash3.h"

#import <zlib.h>

#import <UIKit/UIDevice.h>
#import <AdSupport/AdSupport.h>

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#import <CommonCrypto/CommonDigest.h>

NSString *const kMethodGetCommands = @"server.getCommands";
NSString *const kMethodVerifyPayment = @"server.verifyPayment";

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
    requestParameters = [NSString stringWithFormat:@"?timestamp=%llu&method=%@&token=%@&userId=%@&mobLibVer=%@",
                                                   [Utils timestamp], method,
                                                   [token stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                                   [userIdentifier stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                                   kAppMetrVersionString];

    requestParameters = [requestParameters stringByAppendingString:[self getDeviceKeyForDevice:currentDevice useHashes:NO]];
    {
        NSString *value = [currentDevice systemVersion];
        if (value != NULL)
            requestParameters = [requestParameters stringByAppendingFormat:@"&mobOSVer=%@", value];
    }
    

    NSString *fullAddress = [[address stringByAppendingString:requestParameters]
            stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    return fullAddress;
}

+ (NSString *)getDeviceKeyForDevice:(UIDevice*)device useHashes:(BOOL)useHashes
{
    NSString* requestParameters = @"";
    {
        NSString *value = [PAM_OpenUDID value];
        if (value != NULL)
            requestParameters = [requestParameters stringByAppendingFormat:@"&mobOpenUDID=%@", useHashes ? [self getHashForStr:value] : value];
    }
    {
        NSString *value = [UIDeviceUtil hardwareString];
        if (value != NULL)
            requestParameters = [requestParameters stringByAppendingFormat:@"&mobDeviceType=%@", value];
    }
    
    //ntrf: only use MAC-address if it's available and valid
    {
        NSString *value = [Utils stringWithDeviceMACAddress];
        if (value != NULL)
            requestParameters = [requestParameters stringByAppendingFormat:@"&mobMac=%@", useHashes ? [self getHashForStr:value] : value];
    }
    
#if ENABLDE_DEVICE_UNIQUE_IDENTIFIER
    // add device uniqueIdentifier
    if([device respondsToSelector:@selector(uniqueIdentifier)])
    {
        NSString *uniqueIdentifier = [currentDevice performSelector:@selector(uniqueIdentifier)];
        requestParameters = [requestParameters stringByAppendingFormat:@"&mobUDID=%@", useHashes ? [self getHashForStr:uniqueIdentifier] : uniqueIdentifier];
    }
#endif
    
    if ([device respondsToSelector:@selector(identifierForVendor)]) {
        NSString *identifierForVendor = [[device performSelector:@selector(identifierForVendor)] UUIDString];
        requestParameters = [requestParameters stringByAppendingFormat:@"&mobVendorId=%@", useHashes ? [self getHashForStr:identifierForVendor] : identifierForVendor];
    }
    
    Class classASIdentifierManager = NSClassFromString(@"ASIdentifierManager");
    if (classASIdentifierManager != nil) {
        NSString *advertisingIdentifier = [[[classASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        requestParameters = [requestParameters stringByAppendingFormat:@"&mobAdvId=%@", useHashes ? [self getHashForStr:advertisingIdentifier] : advertisingIdentifier];
        
        if(!useHashes) {
            BOOL advertisingTrackingEnabled = [[classASIdentifierManager sharedManager] isAdvertisingTrackingEnabled];
            requestParameters = [requestParameters stringByAppendingFormat:@"&mobAdvIdEnabled=%@", advertisingTrackingEnabled == YES ? @"true" : @"false"];
        }
    }
    return requestParameters;
}

+ (NSDictionary *)sendVerifyPaymentRequest:(NSString *)address
                                     token:(NSString *)token
                            userIdentifier:(NSString *)userIdentifier
                                  purchase:(NSString *)purchase
                                   receipt:(NSString *)receipt
                                      salt:(NSString *)salt
                                   logging:(BOOL)logging {

    NSString *fullAddress = [Utils requestParametersForMethod:kMethodVerifyPayment
                                                      address:address
                                                        token:token
                                               userIdentifier:userIdentifier];

    fullAddress = [fullAddress stringByAppendingFormat:@"&purchase=%@&receipt=%@&salt=%@",
                                                       [purchase stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                                       [receipt stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                                       [salt stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    return [self sendRequest:fullAddress logging:logging];;
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

+ (NSString *)deviceKeyForToken:(NSString*)token {
    NSString* deviceInfo = [NSString stringWithFormat:@"token=%@", [token lowercaseString]];
    deviceInfo = [deviceInfo stringByAppendingString:[self getDeviceKeyForDevice:[UIDevice currentDevice] useHashes:YES]];
    NSCharacterSet* characterSet = [NSCharacterSet characterSetWithCharactersInString:@"&"];
    deviceInfo = [deviceInfo stringByTrimmingCharactersInSet:characterSet];
    return [deviceInfo stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
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

    if ((*ptr & 0x02) == 0x02) {    //ntrf: local MAC-address - doesn't globaly identify user
        free(buf);
        return NULL;
    }

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
    strm.avail_in = (unsigned int)data.length;
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
    CC_MD5(cStr, (unsigned int)strlen(cStr), digest);

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];

    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }

    return output;

}

//"private" methods
+ (NSDictionary *)sendRequest:(NSString *)fullAddress
                      logging:(BOOL)logging {
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
        NSLog(@"Request parameters: '%@' Response: '%@'", fullAddress, responseText);
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
        NSLog(@"Server error: Invalid Content-type");
    }

    NSError *jsonError = nil;
    NSDictionary *serverResponse = [[AMCJSONDeserializer deserializer] deserializeAsDictionary:responseData
                                                                                       error:&jsonError];
    if (jsonError) {
        [JSONException raiseWithError:jsonError];
    }
    return serverResponse;
}

+ (BOOL)convertDateToLong:(NSMutableDictionary*)data
{
    BOOL changed = NO;
    for(id key in data.allKeys) {
        id value = [data objectForKey:key];
        if([value isKindOfClass:[NSDate class]]) {
            id timestamp = [NSNumber numberWithUnsignedLongLong:(unsigned long long) ([(NSDate*)value timeIntervalSince1970] * 1000.0)];
            [data setObject:timestamp forKey:key];
            changed = YES;
        } else if([value isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary* mutableValue = [(NSDictionary*)value mutableCopy];
            if([self convertDateToLong:mutableValue]) {
                [data setObject:mutableValue forKey:key];
                changed = YES;
            }
            [mutableValue release];
        }
    }
    return changed;
}

+ (NSString*)getHashForStr:(NSString*)data
{
    if(data == nil || data.length == 0)
        return data;
    const char* dataBytes = [[data lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding];
    uint64_t result[2];
    MurmurHash3_x64_128(dataBytes, (int)strlen(dataBytes), 0, result);
    char resultStr[33];
    sprintf(resultStr, "%016" PRIx64 "%016" PRIx64, __builtin_bswap64((uint64_t)result[0]), __builtin_bswap64((uint64_t)result[1]));
    return [NSString stringWithUTF8String:resultStr];
}

@end
