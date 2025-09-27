//
//  BFFluencyMonitor.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/20.
//

#import <Foundation/Foundation.h>
#import "BFMonitorModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface BFFluencyMonitor : NSObject

+ (void)start;
+ (void)stop;

+ (BOOL)isOn;

@end

NS_ASSUME_NONNULL_END
