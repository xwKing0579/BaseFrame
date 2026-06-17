//
//  BFUIHierarchyManager.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/25.
//

#import <Foundation/Foundation.h>
#import "BFUIHierarchyModel.h"
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXTERN NSString *const kTPUIHierarchyNotification;

@interface BFUIHierarchyManager : NSObject
+ (void)start;
+ (void)stop;

+ (BOOL)isOn;

+ (BFUIHierarchyModel *)viewUIHierarchy:(id)obj;
+ (BFUIHierarchyModel *)viewControllers;

@end

NS_ASSUME_NONNULL_END
