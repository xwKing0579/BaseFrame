//
//  BFConfuseProperty.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFConfuseProperty : NSObject
/// 扫描项目并直接返回找到的属性名数组
/// @param projectPath 项目根路径
/// @return 按字母排序的属性名数组
+ (NSArray<NSString *> *)scanProjectAtPath:(NSString *)projectPath;


//属性名替换
+ (void)safeReplaceContentInDirectory:(NSString *)directoryPath
                        renameMapping:(NSDictionary<NSString *, NSString *> *)renameMapping;


/// 在指定目录下为所有 Model 文件添加随机属性和随机顺序
/// @param directory 要扫描的目录路径
/// @param propertyNames 可选的属性名称池
/// @param averageCount 每个文件平均要添加的属性数量
+ (void)insertRandomPropertiesInDirectory:(NSString *)directory
                               namePool:(NSArray<NSString *> *)propertyNames
                           averageCount:(NSInteger)averageCount;

//替换的属性名称
+ (NSDictionary *)mapPropertyDict;
+ (NSDictionary *)mapPropertyDict1;
+ (NSDictionary *)mapPropertyDict2;
+ (NSDictionary *)mapPropertyDict4;


@end

NS_ASSUME_NONNULL_END
