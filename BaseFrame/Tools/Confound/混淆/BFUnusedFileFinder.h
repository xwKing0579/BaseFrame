//
//  BFUnusedFileFinder.h
//  BaseFrame
//
//  Created by King on 2025/10/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFUnusedFileFinder : NSObject
// 一句话查找未使用的文件
+ (NSArray<NSString *> *)findUnusedFilesInProject:(NSString *)projectPath;

// 一句话查找未使用的文件（带排除目录）
+ (NSArray<NSString *> *)findUnusedFilesInProject:(NSString *)projectPath excludeDirectories:(NSArray<NSString *> *)excludedDirs;

// 一句话查找未使用的第三方库
+ (NSArray<NSString *> *)findUnusedLibrariesInProject:(NSString *)projectPath;
@end

NS_ASSUME_NONNULL_END
