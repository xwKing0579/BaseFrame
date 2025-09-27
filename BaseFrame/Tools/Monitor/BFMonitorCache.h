//
//  BFMonitorCache.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFMonitorCache : NSObject
+ (id)monitorData;
+ (void)cacheMonitorData:(id)monitorData;
+ (void)removeMonitorData;
@end

NS_ASSUME_NONNULL_END
