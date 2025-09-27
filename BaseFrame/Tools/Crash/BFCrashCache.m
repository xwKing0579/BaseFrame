//
//  BFCrashCache.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/13.
//

#import "BFCrashCache.h"
#import <YYCache/YYCache.h>

static YYCache *_crashCache;
static NSString *const BFCrashDataCachePathKey = @"BFCrashDataCachePathKey";
@implementation BFCrashCache

+ (void)initialize {
    _crashCache = [YYCache cacheWithName:@"BFCrashCacheKey"];
}

+ (id)crashData{
    return [_crashCache objectForKey:BFCrashDataCachePathKey];
}

+ (void)cacheCrashData:(id)crashData{
    [_crashCache setObject:crashData forKey:BFCrashDataCachePathKey];
}

+ (void)removeCrashData{
    [_crashCache removeAllObjects];
}

@end
