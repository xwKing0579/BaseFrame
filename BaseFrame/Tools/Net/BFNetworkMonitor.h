//
//  BFNetworkMonitor.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/29.
//

#import <Foundation/Foundation.h>
#import "BFNetworkModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface BFNetworkMonitor : NSObject

+ (NSArray <BFNetworkModel *>*)data;
+ (void)removeNetData;

@end

NS_ASSUME_NONNULL_END
