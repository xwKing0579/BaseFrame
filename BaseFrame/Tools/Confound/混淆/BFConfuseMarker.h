//
//  BFConfuseMarker.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFConfuseMarker : NSObject

//删除所有注释
+ (void)deleteCommentsInDirectory:(NSString *)directory ignoreDirNames:(NSArray<NSString *> *)ignoreDirNames;

/// 清理指定目录下所有.h/.m/.mm文件中的属性声明行尾注释（排除Pods目录）
/// @param rootPath 项目根目录路径
+ (void)cleanSemicolonCommentsInProject:(NSString *)rootPath;

//添加随机注释
+ (void)addCommentsToProjectAtPath:(NSString *)projectPath;



@end

@interface BFSmartCommentGenerator : NSObject

// 动词数组
+ (NSArray *)actionVerbs;
// 名词数组
+ (NSArray *)operationNouns;
// 修饰词数组
+ (NSArray *)modifiers;

+ (NSString *)generateCallbackNote;
+ (NSString *)generateReturnDescription;

// 生成方法描述
+ (NSString *)generateMethodDescription:(NSString *)methodName;
// 生成参数描述
+ (NSString *)generateParamDescriptionForParam:(NSString *)paramName;
// 生成智能注释
+ (NSString *)generateSmartCommentForMethod:(NSString *)methodName params:(NSArray *)paramTypes;
@end
NS_ASSUME_NONNULL_END
