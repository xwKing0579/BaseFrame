//
//  BFConfuseManager.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFConfuseManager : NSObject

/**
 搜索目录中的文件内容

 @param directory 要搜索的目录路径
 @param exceptDirs 需要排除的目录名称数组
 @param includeFiles 包含的文件扩展名数组 (如 @[@"h", @"m"])
 @param pattern 要匹配的正则表达式
 @param error 错误信息
 @return 返回匹配的文件路径数组
 */
+ (NSArray *)searchDirectory:(NSString *)directory
                  exceptDirs:(NSArray *)exceptDirs
                 includeFiles:(NSArray *)includeFiles
                  regexPattern:(NSString *)pattern
                returnPatten:(BOOL)returnPatten
                     error:(NSError **)error;


/**
 检索并处理字符串数组
 
 @param array 原始字符串数组
 @param prefix 只搜索自定义开头字符串（可为nil表示不限制）
 @return 处理后的数组（abcd在前、去重）
 */
+ (NSArray *)searchAndProcessArray:(NSArray *)array withPrefixes:(NSArray<NSString *> *)prefixes;


/**
 将驼峰命名字符串分解为单词组件
 
 @param input 输入字符串 (如 "DEUserSettingTableViewCell")
 @return 分解后的单词数组 (如 @["User", "Setting", "Table", "View", "Cell"])
 */
+ (NSArray<NSString *> *)splitClassName:(NSString *)className;
+ (NSArray<NSString *> *)splitClassNameList:(NSArray *)nameList;


/**
 替换字符串中的单词
 
 @param word 原始字符串 (如 "IPAMyBookListModel")
 @param prefix 前缀 (如 "IPA")
 @param replaceList 替换单词库 (如 @[@"Mine", @"artice", @"string", @"string2"])
 @param exceptList 白名单单词 (如 @[@"Model"])
 @param replaceDict 指定替换字典 (如 @{@"Book": @"Cat"})
 @return 替换后的字符串 (如 "IPAMyCatListModel")
 */
+ (NSString *)word:(NSString *)word prefix:(NSString *)prefix replaceList:(NSArray *)replaceList exceptList:(NSArray *)exceptList replactDict:(NSDictionary *)replacrDict;
+ (NSDictionary *)wordList:(NSArray *)wordList prefix:(NSString *)prefix replaceList:(NSArray *)replaceList exceptList:(NSArray *)exceptList replactDict:(NSDictionary *)replacrDict;

//判断是否映射字典
+ (NSString *)readObfuscationMappingFileAtPath:(NSString *)basePath;
+ (NSString *)readObfuscationMappingFileAtPath:(NSString *)basePath name:(NSString *)name;

//写入到指定路径的文本
+ (void)writeData:(id)data toPath:(NSString *)path fileName:(NSString *)fileName;

//删除指定目录下所有以~结尾的文件
+ (void)deleteTildeFilesInDirectory:(NSString *)directory;


/// 执行字符串替换（主入口）
/// @param sourceDir 源代码目录
/// @param jsonPath 替换规则JSON路径
/// @param excludeDirs 排除目录名数组（如@[@"Pods"]）
+ (void)replaceInDirectory:(NSString *)sourceDir withJSONRuleFile:(NSString *)jsonPath excludeDirs:(NSArray<NSString *> *)excludeDirs;




/// 检测指定路径下所有文件（除Pods外）是否包含字符串数组中的内容
/// @param directoryPath 要检测的目录路径
/// @param targetStrings 要检测的字符串数组
/// @return 包含所有匹配字符串的数组
+ (NSArray<NSString *> *)detectStringsInDirectory:(NSString *)directoryPath
                                  targetStrings:(NSArray<NSString *> *)targetStrings;

@end

NS_ASSUME_NONNULL_END
