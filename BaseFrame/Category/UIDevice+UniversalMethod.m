//
//  UIDevice+UniversalMethod.m
//  PintarTunai
//
//  Created by Invincible handsome brother on 2024/10/31.
//

#import "UIDevice+UniversalMethod.h"


#import <sys/utsname.h>

#import <mach/mach.h>
#import <sys/sysctl.h>
#import <mach-o/arch.h>

#import <SystemConfiguration/CaptiveNetwork.h>

typedef struct {
    unsigned long long used_size;
    unsigned long long available_size;
    unsigned long long total_size;
}ram_usage;
@implementation UIDevice (UniversalMethod)

+ (NSString *)iphoneModel{
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding] ?: @"";
}



+ (NSString *)isConnectAgent{
    CFDictionaryRef dicRef = CFNetworkCopySystemProxySettings();
    const CFStringRef proxyCFstr = (const CFStringRef)CFDictionaryGetValue(dicRef, (const void *)kCFNetworkProxiesHTTPProxy);
    NSString *proxy = (__bridge NSString *)proxyCFstr;
    return proxy.length > 0 ? @"1" : @"0";
}

+ (NSString *)isConnectVPN{
    NSDictionary *proxySettings = (__bridge NSDictionary *)CFNetworkCopySystemProxySettings();
    NSArray *settings = [proxySettings[@"__SCOPED__"] allKeys];
    for (NSString *value in settings) {
        if ([value rangeOfString:@"tap"].location != NSNotFound ||
            [value rangeOfString:@"tun"].location != NSNotFound ||
            [value rangeOfString:@"ipsec"].location != NSNotFound ||
            [value rangeOfString:@"ppp"].location != NSNotFound) {
            return @"1";
        }
    }
    return @"0";
}

+ (unsigned long long)diskSize{
    NSError *error = nil;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error) return -1;
    int64_t space =  [[attrs objectForKey:NSFileSystemSize] longLongValue];
    return space;
}

+ (unsigned long long)diskResetSize{
    NSURL *url = [[NSURL alloc] initFileURLWithPath:NSHomeDirectory()];
    NSDictionary<NSURLResourceKey, id> *dict = [url resourceValuesForKeys:@[NSURLVolumeAvailableCapacityForImportantUsageKey] error:nil];
    long long freeSize = [dict[NSURLVolumeAvailableCapacityForImportantUsageKey] longLongValue];
    return freeSize;
}

+ (unsigned long long)ramSize {
    return [NSProcessInfo processInfo].physicalMemory;
}

+ (unsigned long long)ramUsage {
    ram_usage ram_usage = [self systemRamUsageStruct];
    return ram_usage.used_size;
}

+ (unsigned long long)ramResetSize {
    return self.ramSize - self.ramUsage;
}

+ (ram_usage)systemRamUsageStruct {
    vm_statistics64_data_t vmStats;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kr = host_statistics(mach_host_self(),HOST_VM_INFO,(host_info_t)&vmStats,&infoCount);
    
    ram_usage system_usage = {0, 0, 0};
    if (kr != KERN_SUCCESS) {
        return system_usage;
    }
    system_usage.used_size = (vmStats.active_count + vmStats.wire_count + vmStats.inactive_count) * vm_kernel_page_size;
    system_usage.available_size = (vmStats.free_count) * vm_kernel_page_size;
    system_usage.total_size = [NSProcessInfo processInfo].physicalMemory;
    return system_usage;
}

+ (NSString *)diskLen{
    return [NSString stringWithFormat:@"%lld",[UIDevice diskSize]];
}
+ (NSString *)diskRestLen{
    return [NSString stringWithFormat:@"%lld",[UIDevice diskResetSize]];
}

+ (NSString *)ramLen{
    return [NSString stringWithFormat:@"%lld",[UIDevice ramSize]];
}
+ (NSString *)ramRestLen{
    return [NSString stringWithFormat:@"%lld",[UIDevice ramResetSize]];
}

+ (NSString *)isSimuLator{
    return (TARGET_IPHONE_SIMULATOR == 1 && TARGET_OS_IPHONE == 1) ? @"1" : @"0";
}

+ (NSString *)isJailbreakMachine {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"cydia://"]]) {
        return @"1";
    }
    return @"0";
}


@end
