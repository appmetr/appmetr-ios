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

@end
