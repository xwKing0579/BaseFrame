//
//  BFNetworkMonitor.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/29.
//

#import "BFNetworkMonitor.h"
#import "BFURLProtocol.h"
NSString *const kTPNetworkConfigKey = @"kTPNetworkConfigKey";

@interface BFNetworkMonitor() <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@end

@implementation BFNetworkMonitor

+ (void)load{
#ifdef DEBUG
    [self start];
#endif
}

+ (void)start{
    [[NSUserDefaults standardUserDefaults] setValue:@(YES) forKey:kTPNetworkConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [NSURLProtocol registerClass:[BFURLProtocol class]];
}

+ (void)stop{
    [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:kTPNetworkConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [NSURLProtocol unregisterClass:[BFURLProtocol class]];
}

+ (BOOL)isOn{
    return [[[NSUserDefaults standardUserDefaults] valueForKey:kTPNetworkConfigKey] boolValue];
}

+ (NSArray <BFNetworkModel *>*)data{
    return [NSObject performTarget:@"BFURLProtocol".classString action:@"dataList"];
}

+ (void)removeNetData{
    [NSObject performTarget:@"BFURLProtocol".classString action:@"removeNetData"];
}

@end
