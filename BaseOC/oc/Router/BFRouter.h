//
//  BFRouter.h
//  OCProject
//
//  Created by 王祥伟 on 2023/11/29.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const kBFRouterPathURLName;
FOUNDATION_EXTERN NSString *const kBFRouterPathJumpStyle;
FOUNDATION_EXTERN NSString *const kBFRouterPathNoAnimation;
FOUNDATION_EXTERN NSString *const kBFRouterPathBackRoot;

///测试路由
///ocproject://oc.com/native/index_2
///ocproject://oc.com/native/BFCrashViewController
@interface BFRouter : NSObject

+ (__kindof UIViewController *)jumpUrl:(NSString *)url;
+ (__kindof UIViewController *)jumpUrl:(NSString *)url params:(NSDictionary * _Nullable )params;

+ (void)back;
+ (void)backRoot;
+ (void)backUrl:(NSString * _Nullable)url; ///home/noanimation/index_1

///自定义页面参数
+ (NSDictionary *)classValue;
@end

@interface NSString (Router)
- (NSString *)present;
- (NSString *)noAnimation;
- (NSString *)baseNavigation;
@end

NS_ASSUME_NONNULL_END
