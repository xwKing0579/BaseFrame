//
//  BFConfuseDirectory.m
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/2.
//

#import "BFConfuseDirectory.h"
#import "BFConfuseManager.h"
@implementation BFConfuseDirectory

+ (NSDictionary *)dict{
    return [self parseModuleMappingJSON:@"directory"];
}

+ (NSDictionary *)dict1{
    return [self parseModuleMappingJSON:@"directory_xixi"];
}

+ (NSDictionary *)dict2{
    return [self parseModuleMappingJSON:@"directory_jingyuege"];
}

+ (NSDictionary *)dict103{
    return [self parseModuleMappingJSON:@"directory_yueyi 3"];
}

+ (void)processProjectAtPath:(NSString *)projectPath
               renameMapping:(NSDictionary<NSString *, NSString *> *)mapping {
    
    // 1. 首先处理目录重命名
    [self renameDirectoriesInProject:projectPath withMapping:mapping];
    
    // 2. 处理.pbxproj文件内容
    NSString *pbxprojPath = [self findPbxprojPathInProject:projectPath];
    if (pbxprojPath) {
        [self updatePbxprojFile:pbxprojPath withMapping:mapping];
    } else {
        NSLog(@"⚠️ Warning: No .pbxproj file found in project");
    }
}

#pragma mark - 目录重命名

+ (void)renameDirectoriesInProject:(NSString *)projectPath
                     withMapping:(NSDictionary<NSString *, NSString *> *)mapping {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:projectPath];
    
    // 先收集所有需要重命名的目录（避免嵌套修改问题）
    NSMutableArray *directoriesToRename = [NSMutableArray array];
    
    for (NSString *relativePath in enumerator) {
        NSString *fullPath = [projectPath stringByAppendingPathComponent:relativePath];
        
        BOOL isDirectory;
        [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
        
        if (isDirectory) {
            NSString *directoryName = [relativePath lastPathComponent];
            
            // 检查目录名是否需要替换（完全匹配，包括大小写）
            __block NSString *newDirectoryName = directoryName;
            [mapping enumerateKeysAndObjectsUsingBlock:^(NSString *target, NSString *replacement, BOOL *stop) {
                // 使用完全相等比较而不是containsString
                if ([directoryName isEqualToString:target]) {
                    newDirectoryName = replacement;
                    *stop = YES; // 找到匹配后停止检查其他键
                }
            }];
            
            if (![newDirectoryName isEqualToString:directoryName]) {
                [directoriesToRename addObject:@{
                    @"oldPath": fullPath,
                    @"newName": newDirectoryName
                }];
            }
        }
    }
    
    // 执行重命名（从最深层的目录开始，避免路径问题）
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"oldPath"
                                                                    ascending:NO];
    NSArray *sortedDirectories = [directoriesToRename sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    for (NSDictionary *dirInfo in sortedDirectories) {
        NSString *oldPath = dirInfo[@"oldPath"];
        NSString *newName = dirInfo[@"newName"];
        
        NSString *parentPath = [oldPath stringByDeletingLastPathComponent];
        NSString *newPath = [parentPath stringByAppendingPathComponent:newName];
        
        NSError *error = nil;
        if ([fileManager moveItemAtPath:oldPath toPath:newPath error:&error]) {
            NSLog(@"✅ Renamed directory: %@ -> %@", [oldPath lastPathComponent], newName);
        } else {
            NSLog(@"❌ Failed to rename directory %@: %@", [oldPath lastPathComponent], error.localizedDescription);
        }
    }
}

#pragma mark - .pbxproj文件处理

+ (NSString *)findPbxprojPathInProject:(NSString *)projectPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:projectPath];
    
    for (NSString *path in enumerator) {
        if ([path hasSuffix:@".xcodeproj"] && ![path containsString:@"/"]) {
            NSString *xcodeprojPath = [projectPath stringByAppendingPathComponent:path];
            NSString *pbxprojPath = [xcodeprojPath stringByAppendingPathComponent:@"project.pbxproj"];
            
            if ([fileManager fileExistsAtPath:pbxprojPath]) {
                return pbxprojPath;
            }
        }
    }
    return nil;
}

+ (void)updatePbxprojFile:(NSString *)pbxprojPath
             withMapping:(NSDictionary<NSString *, NSString *> *)mapping {
    
    NSError *error = nil;
    NSMutableString *content = [NSMutableString stringWithContentsOfFile:pbxprojPath
                                                               encoding:NSUTF8StringEncoding
                                                                  error:&error];
    if (error) {
        NSLog(@"❌ Error reading .pbxproj file: %@", error.localizedDescription);
        return;
    }
    
    __block BOOL changesMade = NO;
    [mapping enumerateKeysAndObjectsUsingBlock:^(NSString *targetWord, NSString *replacement, BOOL *stop) {
        // 严格匹配原始大小写
        NSString *escapedTarget = [NSRegularExpression escapedPatternForString:targetWord];
        
        // 最终正则表达式：
        // 前面不能是: 字母(a-zA-Z)、数字(0-9)或加号(+)
        // 后面不能是: 字母或数字
        NSString *pattern = [NSString stringWithFormat:@"(?<![a-zA-Z0-9+])%@(?![a-zA-Z0-9])", escapedTarget];
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                             options:0
                                                                               error:nil];
        if (error) {
            NSLog(@"❌ Error creating regex for '%@': %@", targetWord, error.localizedDescription);
            *stop = YES;
            return;
        }
        
        NSUInteger replacements = [regex replaceMatchesInString:content
                                                       options:0
                                                         range:NSMakeRange(0, content.length)
                                                  withTemplate:replacement];
        
        if (replacements > 0) {
            NSLog(@"✏️ Replaced '%@' with '%@' %lu times in .pbxproj",
                  targetWord, replacement, (unsigned long)replacements);
            changesMade = YES;
        }
    }];
    
    if (changesMade) {
        if (![content writeToFile:pbxprojPath
                      atomically:YES
                        encoding:NSUTF8StringEncoding
                           error:&error]) {
            NSLog(@"❌ Error writing to .pbxproj file: %@", error.localizedDescription);
        } else {
            NSLog(@"✅ Successfully updated .pbxproj file");
        }
    } else {
        NSLog(@"ℹ️ No replacements made in .pbxproj file");
    }
}


+ (void)calculateAndPrintDirectorySizes:(NSString *)projectPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 验证路径是否存在
    BOOL isDirectory = NO;
    if (![fileManager fileExistsAtPath:projectPath isDirectory:&isDirectory] || !isDirectory) {
        NSLog(@"❌ 无效的项目路径: %@", projectPath);
        return;
    }
    
    NSLog(@"📁 开始分析项目目录: %@", projectPath);
    NSLog(@"==========================================");
    
    // 获取所有子目录
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:projectPath];
    NSMutableDictionary *directorySizes = [NSMutableDictionary dictionary];
    
    // 先收集所有目录路径
    NSMutableSet *directories = [NSMutableSet set];
    [directories addObject:projectPath]; // 包含根目录
    
    NSString *relativePath;
    while ((relativePath = [enumerator nextObject]) != nil) {
        NSString *fullPath = [projectPath stringByAppendingPathComponent:relativePath];
        
        BOOL isDir = NO;
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDir] && isDir) {
            [directories addObject:fullPath];
        }
    }
    
    // 计算每个目录的大小
    for (NSString *directory in directories) {
        unsigned long long size = [self calculateDirectorySize:directory];
        directorySizes[directory] = @(size);
    }
    
    // 按大小排序并打印
    NSArray *sortedDirectories = [directorySizes keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *size1, NSNumber *size2) {
        return [size2 compare:size1]; // 从大到小排序
    }];
    
    // 打印结果
    for (NSString *directory in sortedDirectories) {
        unsigned long long size = [directorySizes[directory] unsignedLongLongValue];
        NSString *relativeDir = [directory substringFromIndex:projectPath.length];
        if (relativeDir.length == 0) {
            relativeDir = @"/ (根目录)";
        }
        
        [self printDirectoryInfo:relativeDir size:size];
    }
    
    // 打印总计
    unsigned long long totalSize = [self calculateDirectorySize:projectPath];
    NSLog(@"==========================================");
    NSLog(@"📊 项目总大小: %@", [self formattedSize:totalSize]);
}

+ (unsigned long long)calculateDirectorySize:(NSString *)directoryPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directoryPath];
    
    unsigned long long totalSize = 0;
    NSString *filePath;
    
    while ((filePath = [enumerator nextObject]) != nil) {
        @autoreleasepool {
            NSString *fullPath = [directoryPath stringByAppendingPathComponent:filePath];
            
            // 跳过符号链接
            NSDictionary<NSFileAttributeKey, id> *attributes = [fileManager attributesOfItemAtPath:fullPath error:nil];
            if (attributes[NSFileType] == NSFileTypeSymbolicLink) {
                continue;
            }
            
            // 如果是文件，计算大小
            if (attributes[NSFileType] == NSFileTypeRegular) {
                totalSize += [attributes[NSFileSize] unsignedLongLongValue];
            }
        }
    }
    
    return totalSize;
}

+ (void)printDirectoryInfo:(NSString *)directoryName size:(unsigned long long)size {
    if (size < 1000000) return;
    NSString *sizeStr = [self formattedSize:size];
    NSString *indentation = @"";
    
    // 根据目录深度添加缩进
    NSUInteger depth = [[directoryName componentsSeparatedByString:@"/"] count] - 1;
    for (NSUInteger i = 0; i < depth && i < 10; i++) {
        indentation = [indentation stringByAppendingString:@"  "];
    }
    
    // 添加图标
    NSString *icon = depth == 0 ? @"📁" : @"📂";
    
    NSLog(@"%@%@ %@: %@", indentation, icon, [directoryName lastPathComponent], sizeStr);
}

+ (NSString *)formattedSize:(unsigned long long)bytes {
    double size = (double)bytes;
    NSArray *units = @[@"B", @"KB", @"MB", @"GB", @"TB"];
    int unitIndex = 0;
    
    while (size >= 1024.0 && unitIndex < units.count - 1) {
        size /= 1024.0;
        unitIndex++;
    }
    
    return [NSString stringWithFormat:@"%.2f %@", size, units[unitIndex]];
}


@end
