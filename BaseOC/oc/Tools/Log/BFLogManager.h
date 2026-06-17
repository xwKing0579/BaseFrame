//
//  BFLogManager.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/19.
//

#import <Foundation/Foundation.h>
#import "BFLogModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface BFLogManager : NSObject

+ (instancetype)sharedManager;

+ (void)start;
+ (void)stop;

+ (BOOL)isOn;
- (void)addLog:(NSString *)log;

+ (NSArray<BFLogModel *> *)data;
+ (void)removeData;
@end

NS_ASSUME_NONNULL_END
