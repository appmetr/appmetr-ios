/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "UIDeviceUtil.h"
#include <sys/sysctl.h>

@implementation UIDeviceUtil

+ (NSString *)hardwareString {
    size_t size = 100;
    char *hw_machine = malloc(size);
    int name[] = {CTL_HW, HW_MACHINE};
    sysctl(name, 2, hw_machine, &size, NULL, 0);
    NSString *hardware = [NSString stringWithUTF8String:hw_machine];
    free(hw_machine);
    return hardware;
}

+ (NSString *)hardwareDescription {
    NSString *hardware = [UIDeviceUtil hardwareString];
    if ([hardware isEqualToString:@"iPhone1,1"]) return @"iPhone_2G";
    if ([hardware isEqualToString:@"iPhone1,2"]) return @"iPhone_3G";
    if ([hardware isEqualToString:@"iPhone2,1"]) return @"iPhone_3GS";
    if ([hardware isEqualToString:@"iPhone3,1"]) return @"iPhone_4";
    if ([hardware isEqualToString:@"iPhone3,2"]) return @"iPhone_4";
    if ([hardware isEqualToString:@"iPhone3,3"]) return @"iPhone_4_(CDMA)";
    if ([hardware isEqualToString:@"iPhone4,1"]) return @"iPhone_4S";
    if ([hardware isEqualToString:@"iPhone5,1"]) return @"iPhone_5";
    if ([hardware isEqualToString:@"iPhone5,2"]) return @"iPhone_5_(GSM+CDMA)";

    if ([hardware isEqualToString:@"iPod1,1"]) return @"iPod_Touch_(1_Gen)";
    if ([hardware isEqualToString:@"iPod2,1"]) return @"iPod_Touch_(2_Gen)";
    if ([hardware isEqualToString:@"iPod3,1"]) return @"iPod_Touch_(3_Gen)";
    if ([hardware isEqualToString:@"iPod4,1"]) return @"iPod_Touch_(4_Gen)";
    if ([hardware isEqualToString:@"iPod5,1"]) return @"iPod_Touch_(5_Gen)";

    if ([hardware isEqualToString:@"iPad1,1"]) return @"iPad";
    if ([hardware isEqualToString:@"iPad1,2"]) return @"iPad_3G";
    if ([hardware isEqualToString:@"iPad2,1"]) return @"iPad_2_(WiFi)";
    if ([hardware isEqualToString:@"iPad2,2"]) return @"iPad_2";
    if ([hardware isEqualToString:@"iPad2,3"]) return @"iPad_2_(CDMA)";
    if ([hardware isEqualToString:@"iPad2,4"]) return @"iPad_2";
    if ([hardware isEqualToString:@"iPad2,5"]) return @"iPad_Mini_(WiFi)";
    if ([hardware isEqualToString:@"iPad2,6"]) return @"iPad_Mini";
    if ([hardware isEqualToString:@"iPad2,7"]) return @"iPad_Mini_(GSM+CDMA)";
    if ([hardware isEqualToString:@"iPad3,1"]) return @"iPad_3_(WiFi)";
    if ([hardware isEqualToString:@"iPad3,2"]) return @"iPad_3_(GSM+CDMA)";
    if ([hardware isEqualToString:@"iPad3,3"]) return @"iPad_3";
    if ([hardware isEqualToString:@"iPad3,4"]) return @"iPad_4_(WiFi)";
    if ([hardware isEqualToString:@"iPad3,5"]) return @"iPad_4";
    if ([hardware isEqualToString:@"iPad3,6"]) return @"iPad_4_(GSM+CDMA)";

    if ([hardware isEqualToString:@"i386"]) return @"Simulator";
    if ([hardware isEqualToString:@"x86_64"]) return @"Simulator";

    return hardware;
}
@end
