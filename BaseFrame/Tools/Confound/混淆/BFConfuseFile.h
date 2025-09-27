//
//  BFConfuseFile.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFConfuseFile : NSObject

//搜索所有类名
+ (NSArray *)getTotalControllersInDirectory:(NSString *)directory;

/**
 在指定目录中重命名文件（严格匹配）
 
 @param directory 要处理的目录路径
 @param replaceDict 替换字典 @{@"OldName": @"NewName"}
 */
+ (void)customReplaceInDirectory:(NSString *)directory replaceDict:(NSDictionary *)replaceDict;

+ (void)randomReplaceInDirectory:(NSString *)directory replaceDict:(NSDictionary *)replaceDict;



//类别替换
+ (void)globalReplaceInDirectory:(NSString *)directory oldName:(NSString *)oldName newName:(NSString *)newName;


+ (NSDictionary *)fileMapping;
+ (NSDictionary *)fileMapping0;
+ (NSDictionary *)fileMapping1;
+ (NSDictionary *)fileMapping2;
+ (NSDictionary *)fileMapping3;

+ (NSDictionary *)fileMapping100;
+ (NSDictionary *)fileMapping101;
+ (NSDictionary *)fileMapping102;
@end

NS_ASSUME_NONNULL_END
