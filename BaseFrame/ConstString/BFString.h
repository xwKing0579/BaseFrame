//
//  BFString.h
//  OCProject
//
//  Created by 王祥伟 on 2024/3/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFString : NSObject

///基类
+ (NSString *)vc_base;
+ (NSString *)vc_base_table;
+ (NSString *)vc_base_tabbar;
+ (NSString *)vc_base_navigation;

+ (NSString *)vc_tabbar;

//公用头
+ (NSString *)prefix_app;
+ (NSString *)prefix_viewController;

@end

@interface NSString (SelectorName)

- (Class)toClass;

///vc别名
- (NSString *)abbr;

///首字母大写
- (NSString *)prefixCapital;

@end
NS_ASSUME_NONNULL_END
