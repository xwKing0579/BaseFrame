//
//  BFConfusePBXUUID.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/7/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFConfusePBXUUID : NSObject
/// 混淆指定路径下的所有 project.pbxproj 文件
/// @param projectPath 项目路径（可以是目录或 .xcodeproj 包）
+ (void)obfuscateUUIDsInProjectAtPath:(NSString *)projectPath;

/// 混淆单个 project.pbxproj 文件
/// @param filePath 完整的 project.pbxproj 文件路径
+ (void)obfuscateUUIDsInPBXFile:(NSString *)filePath;
@end

NS_ASSUME_NONNULL_END
