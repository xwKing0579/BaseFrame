//
//  BFCrashManager.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/12.
//

#import <Foundation/Foundation.h>
#import "BFCrashModel.h"
#import "BFCrashCache.h"
NS_ASSUME_NONNULL_BEGIN

@interface BFCrashManager : NSObject

+ (void)start;
+ (void)stop;

+ (BOOL)isOn;
@end

NS_ASSUME_NONNULL_END
