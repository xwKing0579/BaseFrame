//
//  BFConstantString.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFConstantString : NSObject

//中文字符串替换
+ (void)replaceStringsInProjectAtPath:(NSString *)projectPath;

//常量字符串替换
+ (void)safeReplaceContentInDirectory:(NSString *)directoryPath
                        renameMapping:(NSDictionary<NSString *, NSString *> *)renameMapping;

+ (NSDictionary *)mapConstantStringDict;
+ (NSDictionary *)mapConstantStringDict1;
+ (NSDictionary *)mapConstantStringDict4;
@end

NS_ASSUME_NONNULL_END
