//
//  BFMonitorCache.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/20.
//

#import "BFMonitorCache.h"
#import <YYCache/YYCache.h>

static YYCache *_monitorCache;
static NSString *const BFMonitorDataCachePathKey = @"BFMonitorDataCachePathKey";
@implementation BFMonitorCache

+ (void)initialize {
    _monitorCache = [YYCache cacheWithName:@"BFMonitorCacheKey"];
}

+ (id)monitorData{
    return [_monitorCache objectForKey:BFMonitorDataCachePathKey];
}

+ (void)cacheMonitorData:(id)monitorData{
    [_monitorCache setObject:monitorData forKey:BFMonitorDataCachePathKey];
}

+ (void)removeMonitorData{
    [_monitorCache removeAllObjects];
}
@end
