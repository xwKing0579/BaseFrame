//
//  BFConfuseMethod.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFConfuseMethod : NSObject

//白名单
+ (NSArray *)sysMethodList;
//方法名替换
+ (void)safeReplaceContentInDirectory:(NSString *)directoryPath
                          excludeDirs:(NSArray<NSString *> *)excludeDirs
                         renameMapping:(NSDictionary<NSString *, NSString *> *)renameMapping;

//检索项目中方法名
+ (NSArray<NSString *> *)extractAllMethodNamesFromProject:(NSString *)projectPath;

//方法名只保留长的部分 eg: abc 和 abcd 保留 abcd
+ (NSArray<NSString *> *)filterArrayKeepingLongestStrings:(NSArray<NSString *> *)originalArray;

//对extractMethodNamesFromProjectPath获取的方法过滤
//只保留最多带一个参数的方法
+ (NSArray *)retainsFilterin:(NSArray *)methodList;

//检测set方法
+ (void)detectMultipleSettersInProject:(NSString *)projectPath
                         propertyNames:(NSArray *)propertyNames
                        excludeFolders:(NSArray *)excludeFolders;

//插入随机方法
+ (void)injectRandomCodeToExistingMethodsInPath:(NSString *)path ;


+ (NSDictionary *)mapMethodDict;
+ (NSDictionary *)mapMethodDict1;
+ (NSDictionary *)mapMethodDict2;
+ (NSDictionary *)mapMethodDict4;

+ (NSDictionary *)mapMethodDict100;
+ (NSDictionary *)mapMethodDict101;
+ (NSDictionary *)mapMethodDict102;
+ (NSDictionary *)mapMethodDict103;
@end

NS_ASSUME_NONNULL_END
