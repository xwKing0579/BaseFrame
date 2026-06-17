//
//  BFConfuseProject.m
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/2.
//

#import "BFConfuseProject.h"

@implementation BFConfuseProject

+ (void)renameProjectAtPath:(NSString *)projectPath
                   oldName:(NSString *)oldName
                   newName:(NSString *)newName {
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 1. 验证参数
    if (oldName.length == 0 || newName.length == 0) {
        NSLog(@"Error: 项目名不能为空");
        return;
    }
    
    if (![fm fileExistsAtPath:projectPath]) {
        NSLog(@"Error: 项目路径不存在: %@", projectPath);
        return;
    }
    
    // 2. 备份当前目录
    NSString *originalDir = fm.currentDirectoryPath;
    
    // 3. 进入项目目录
    [fm changeCurrentDirectoryPath:projectPath];
    NSLog(@"开始重命名项目: %@ -> %@", oldName, newName);
    
    // 4. 执行重命名步骤（按顺序很重要！）
    [self renameDirectories:oldName newName:newName];       // 先重命名目录
    [self renameProjectFiles:oldName newName:newName];     // 再重命名项目文件
    [self replaceTextInFiles:oldName newName:newName];     // 然后替换内容
    [self updateSchemeFiles:oldName newName:newName];      // 更新scheme
    [self handleBridgingHeader:oldName newName:newName];   // 专门处理桥接文件
    [self handleEntitlements:oldName newName:newName];     // 专门处理授权文件
    [self handleCocoaPods:oldName newName:newName];       // 处理CocoaPods
    
    // 5. 恢复原始目录
    [fm changeCurrentDirectoryPath:originalDir];
    
    NSLog(@"✅ 项目重命名完成！");
    NSLog(@"请手动执行: cd \"%@\" && pod install (如果使用CocoaPods)", projectPath);
}

#pragma mark - 新增：专门处理Bridging Header
+ (void)handleBridgingHeader:(NSString *)oldName newName:(NSString *)newName {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *currentDir = fm.currentDirectoryPath;
    
    // 1. 构建新旧文件名
    NSString *oldHeaderName = [NSString stringWithFormat:@"%@-Bridging-Header.h", oldName];
    NSString *newHeaderName = [NSString stringWithFormat:@"%@-Bridging-Header.h", newName];
    
    // 2. 递归查找所有可能的桥接文件路径
    NSArray *searchPaths = @[
        currentDir, // 项目根目录
        [currentDir stringByAppendingPathComponent:oldName], // 旧项目目录
        [currentDir stringByAppendingPathComponent:newName]  // 新项目目录（可能已重命名）
    ];
    
    for (NSString *searchPath in searchPaths) {
        NSString *oldHeaderPath = [searchPath stringByAppendingPathComponent:oldHeaderName];
        NSString *newHeaderPath = [searchPath stringByAppendingPathComponent:newHeaderName];
        
        // 3. 检查文件是否存在
        if ([fm fileExistsAtPath:oldHeaderPath]) {
            // 4. 重命名文件
            NSError *renameError;
            if ([fm moveItemAtPath:oldHeaderPath toPath:newHeaderPath error:&renameError]) {
                NSLog(@"✅ 成功重命名桥接文件: %@ -> %@", oldHeaderName, newHeaderName);
                
                // 5. 更新文件内容
                [self replaceBridgingHeaderContent:newHeaderPath oldName:oldName newName:newName];
            } else {
                NSLog(@"⚠️ 重命名失败: %@", renameError.localizedDescription);
            }
            break; // 找到后立即退出循环
        }
    }
}

// 专门处理桥接文件内容替换
+ (void)replaceBridgingHeaderContent:(NSString *)filePath
                           oldName:(NSString *)oldName
                           newName:(NSString *)newName {
    NSError *error;
    NSMutableString *content = [NSMutableString stringWithContentsOfFile:filePath
                                                               encoding:NSUTF8StringEncoding
                                                                  error:&error];
    if (!content) {
        NSLog(@"⚠️ 读取桥接文件失败: %@", error.localizedDescription);
        return;
    }
    
    // 需要替换的关键模式
    NSArray *replacePatterns = @[
        [NSString stringWithFormat:@"%@-Swift.h", oldName],  // Swift头文件引用
        [NSString stringWithFormat:@"%@_Swift.h", oldName],  // 旧版格式
        oldName                                              // 其他可能引用
    ];
    
    BOOL changed = NO;
    for (NSString *pattern in replacePatterns) {
        NSRange range = [content rangeOfString:pattern];
        if (range.location != NSNotFound) {
            NSString *newPattern = [pattern stringByReplacingOccurrencesOfString:oldName
                                                                      withString:newName];
            [content replaceOccurrencesOfString:pattern
                                     withString:newPattern
                                        options:NSLiteralSearch
                                          range:NSMakeRange(0, content.length)];
            changed = YES;
        }
    }
    
    if (changed) {
        if ([content writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            NSLog(@"✏️ 更新桥接文件内容: %@", filePath.lastPathComponent);
        } else {
            NSLog(@"⚠️ 写入桥接文件失败: %@", error.localizedDescription);
        }
    }
}

#pragma mark - 新增：专门处理Entitlements文件
+ (void)handleEntitlements:(NSString *)oldName newName:(NSString *)newName {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 查找所有.entitlements文件
    NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:fm.currentDirectoryPath];
    for (NSString *file in enumerator) {
        if ([file.pathExtension isEqualToString:@"entitlements"]) {
            NSString *fullPath = [fm.currentDirectoryPath stringByAppendingPathComponent:file];
            
            // 如果文件名包含旧项目名则重命名
            if ([file.lastPathComponent containsString:oldName]) {
                NSString *newFileName = [file.lastPathComponent stringByReplacingOccurrencesOfString:oldName
                                                                                         withString:newName];
                NSString *newPath = [[file stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFileName];
                newPath = [fm.currentDirectoryPath stringByAppendingPathComponent:newPath];
                
                [fm moveItemAtPath:fullPath toPath:newPath error:nil];
                NSLog(@"↻ 重命名授权文件: %@ -> %@", file.lastPathComponent, newFileName);
                fullPath = newPath; // 更新为新的路径
            }
            
            // 更新文件内容
            [self replaceContentInFile:fullPath oldName:oldName newName:newName];
        }
    }
}

#pragma mark - 辅助方法：替换单个文件内容
+ (void)replaceContentInFile:(NSString *)filePath
                    oldName:(NSString *)oldName
                    newName:(NSString *)newName {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:filePath]) return;
    
    NSError *error;
    NSMutableString *content = [NSMutableString stringWithContentsOfFile:filePath
                                                               encoding:NSUTF8StringEncoding
                                                                  error:&error];
    if (content && !error) {
        NSString *pattern = [NSString stringWithFormat:@"\\b%@\\b", oldName];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                             options:0
                                                                               error:nil];
        NSUInteger count = [regex replaceMatchesInString:content
                                                options:0
                                                  range:NSMakeRange(0, content.length)
                                           withTemplate:newName];
        
        if (count > 0) {
            [content writeToFile:filePath
                      atomically:YES
                        encoding:NSUTF8StringEncoding
                           error:nil];
            NSLog(@"✏️ 更新文件: %@ (%lu处替换)", filePath.lastPathComponent, (unsigned long)count);
        }
    }
}



#pragma mark - 目录重命名
+ (void)renameDirectories:(NSString *)oldName newName:(NSString *)newName {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *currentDir = fm.currentDirectoryPath;
    
    // 需要跳过的目录
    NSArray *excludedDirs = @[@".git", @".svn", @"Pods", @".bundle", @"DerivedData"];
    
    // 先收集所有需要重命名的目录（深度优先）
    NSMutableArray *dirsToRename = [NSMutableArray array];
    NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:currentDir];
    
    for (NSString *relativePath in enumerator) {
        NSString *fullPath = [currentDir stringByAppendingPathComponent:relativePath];
        
        // 检查是否是目录且需要重命名
        BOOL isDir = NO;
        if ([fm fileExistsAtPath:fullPath isDirectory:&isDir] && isDir) {
            NSString *dirName = relativePath.lastPathComponent;
            
            // 跳过排除目录
            if ([excludedDirs containsObject:dirName]) {
                [enumerator skipDescendants];
                continue;
            }
            
            // 匹配目标目录名
            if ([dirName isEqualToString:oldName]) {
                [dirsToRename addObject:fullPath];
            }
        }
    }
    
    // 按路径深度排序（从深到浅）
    [dirsToRename sortUsingComparator:^NSComparisonResult(NSString *path1, NSString *path2) {
        return [@(path1.pathComponents.count) compare:@(path2.pathComponents.count)];
    }];
    
    // 执行重命名
    for (NSString *oldPath in dirsToRename) {
        NSString *parentDir = [oldPath stringByDeletingLastPathComponent];
        NSString *newPath = [parentDir stringByAppendingPathComponent:newName];
        
        if (![fm fileExistsAtPath:newPath]) {
            NSError *error;
            if ([fm moveItemAtPath:oldPath toPath:newPath error:&error]) {
                NSLog(@"↻ 重命名目录: %@ -> %@", oldPath.lastPathComponent, newName);
            } else {
                NSLog(@"⚠️ 目录重命名失败: %@", error.localizedDescription);
            }
        }
    }
}

#pragma mark - 项目文件重命名
+ (void)renameProjectFiles:(NSString *)oldName newName:(NSString *)newName {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 1. 重命名.xcodeproj
    NSString *oldProj = [NSString stringWithFormat:@"%@.xcodeproj", oldName];
    NSString *newProj = [NSString stringWithFormat:@"%@.xcodeproj", newName];
    
    if ([fm fileExistsAtPath:oldProj]) {
        [fm moveItemAtPath:oldProj toPath:newProj error:nil];
        NSLog(@"↻ 重命名项目文件: %@ -> %@", oldProj, newProj);
    }
    
    // 2. 重命名.xcworkspace
    NSString *oldWorkspace = [NSString stringWithFormat:@"%@.xcworkspace", oldName];
    NSString *newWorkspace = [NSString stringWithFormat:@"%@.xcworkspace", newName];
    
    if ([fm fileExistsAtPath:oldWorkspace]) {
        [fm moveItemAtPath:oldWorkspace toPath:newWorkspace error:nil];
        NSLog(@"↻ 重命名工作区: %@ -> %@", oldWorkspace, newWorkspace);
    }
}

#pragma mark - 文件内容替换
+ (void)replaceTextInFiles:(NSString *)oldName newName:(NSString *)newName {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *currentDir = fm.currentDirectoryPath;
    
    // 需要处理的文件类型
    NSArray *fileExtensions = @[@"h", @"m", @"mm", @"swift", @"xib", @"storyboard",
                              @"plist", @"pbxproj", @"entitlements", @"pch"];
    
    // 遍历所有文件
    NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:currentDir];
    for (NSString *relativePath in enumerator) {
        NSString *fullPath = [currentDir stringByAppendingPathComponent:relativePath];
        
        // 检查文件扩展名
        if ([fileExtensions containsObject:relativePath.pathExtension.lowercaseString]) {
            NSError *error;
            NSMutableString *content = [NSMutableString stringWithContentsOfFile:fullPath
                                                                      encoding:NSUTF8StringEncoding
                                                                         error:&error];
            if (content && !error) {
                // 执行替换（使用正则确保完整单词匹配）
                NSString *pattern = [NSString stringWithFormat:@"\\b%@\\b", oldName];
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                     options:0
                                                                                       error:nil];
                NSUInteger count = [regex replaceMatchesInString:content
                                                         options:0
                                                           range:NSMakeRange(0, content.length)
                                                    withTemplate:newName];
                
                if (count > 0) {
                    [content writeToFile:fullPath
                             atomically:YES
                               encoding:NSUTF8StringEncoding
                                  error:nil];
                    NSLog(@"✏️ 更新文件: %@ (%lu处替换)", relativePath, (unsigned long)count);
                }
            }
        }
    }
}

#pragma mark - Scheme 文件更新
+ (void)updateSchemeFiles:(NSString *)oldName newName:(NSString *)newName {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 1. 查找所有.xcscheme文件
    NSString *projPath = [NSString stringWithFormat:@"%@.xcodeproj", newName];
    NSString *schemesPath = [projPath stringByAppendingPathComponent:@"xcshareddata/xcschemes"];
    
    if (![fm fileExistsAtPath:schemesPath]) {
        NSLog(@"ℹ️ 未找到scheme目录: %@", schemesPath);
        return;
    }
    
    NSError *error = nil;
    NSArray *schemeFiles = [fm contentsOfDirectoryAtPath:schemesPath error:&error];
    if (error) {
        NSLog(@"❌ 读取scheme目录失败: %@", error.localizedDescription);
        return;
    }
    
    for (NSString *schemeFile in schemeFiles) {
        if (![schemeFile.pathExtension isEqualToString:@"xcscheme"]) {
            continue;
        }
        
        NSString *fullPath = [schemesPath stringByAppendingPathComponent:schemeFile];
        
        // 1. 处理文件内容替换（严格大小写匹配）
        [self updateSchemeContent:fullPath oldName:oldName newName:newName];
        
        // 2. 处理文件名替换（严格完全匹配）
        [self renameSchemeFile:fullPath oldName:oldName newName:newName];
    }
}

#pragma mark - 私有辅助方法

// 更新Scheme文件内容（严格大小写匹配）
+ (void)updateSchemeContent:(NSString *)filePath
                   oldName:(NSString *)oldName
                   newName:(NSString *)newName {
    
    NSError *error = nil;
    NSMutableString *content = [NSMutableString stringWithContentsOfFile:filePath
                                                               encoding:NSUTF8StringEncoding
                                                                  error:&error];
    if (error) {
        NSLog(@"❌ 读取Scheme文件失败: %@", filePath.lastPathComponent);
        return;
    }
    
    // 构建严格匹配的正则表达式（完全匹配且大小写敏感）
    NSString *pattern = [NSString stringWithFormat:@"\\b%@\\b", [NSRegularExpression escapedPatternForString:oldName]];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                         options:0
                                                                           error:&error];
    if (error) {
        NSLog(@"❌ 正则表达式创建失败: %@", error.localizedDescription);
        return;
    }
    
    NSUInteger replacements = [regex replaceMatchesInString:content
                                                   options:0
                                                     range:NSMakeRange(0, content.length)
                                              withTemplate:newName];
    
    if (replacements > 0) {
        if (![content writeToFile:filePath
                      atomically:YES
                        encoding:NSUTF8StringEncoding
                           error:&error]) {
            NSLog(@"❌ 写入Scheme文件失败: %@", filePath.lastPathComponent);
        } else {
            NSLog(@"✅ 在 %@ 中替换了 %lu 处 %@ -> %@",
                  filePath.lastPathComponent,
                  (unsigned long)replacements,
                  oldName,
                  newName);
        }
    }
}

// 重命名Scheme文件（严格完全匹配）
+ (void)renameSchemeFile:(NSString *)filePath
                oldName:(NSString *)oldName
                newName:(NSString *)newName {
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *fileName = filePath.lastPathComponent;
    NSString *fileNameWithoutExtension = [fileName stringByDeletingPathExtension];
    
    // 只有当文件名完全匹配时才重命名（大小写敏感）
    if ([fileNameWithoutExtension isEqualToString:oldName]) {
        NSString *newFileName = [fileName stringByReplacingOccurrencesOfString:oldName
                                                                   withString:newName];
        NSString *newFilePath = [[filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFileName];
        
        NSError *error = nil;
        if ([fm moveItemAtPath:filePath toPath:newFilePath error:&error]) {
            NSLog(@"🔄 重命名Scheme文件: %@ -> %@", fileName, newFileName);
        } else {
            NSLog(@"❌ 重命名Scheme文件失败: %@", fileName);
        }
    }
}

#pragma mark - CocoaPods 处理
+ (void)handleCocoaPods:(NSString *)oldName newName:(NSString *)newName {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 1. 更新Podfile
    if ([fm fileExistsAtPath:@"Podfile"]) {
        NSError *error;
        NSMutableString *podfile = [NSMutableString stringWithContentsOfFile:@"Podfile"
                                                                   encoding:NSUTF8StringEncoding
                                                                      error:&error];
        if (podfile && !error) {
            // 替换target名称
            NSString *targetPattern = [NSString stringWithFormat:@"target '%@'", oldName];
            NSString *newTarget = [NSString stringWithFormat:@"target '%@'", newName];
            [podfile replaceOccurrencesOfString:targetPattern
                                     withString:newTarget
                                        options:NSLiteralSearch
                                          range:NSMakeRange(0, podfile.length)];
            
            // 替换project名称（如果有）
            NSString *projectPattern = [NSString stringWithFormat:@"project '%@'", oldName];
            NSString *newProject = [NSString stringWithFormat:@"project '%@'", newName];
            [podfile replaceOccurrencesOfString:projectPattern
                                     withString:newProject
                                        options:NSLiteralSearch
                                          range:NSMakeRange(0, podfile.length)];
            
            [podfile writeToFile:@"Podfile"
                      atomically:YES
                        encoding:NSUTF8StringEncoding
                           error:nil];
            
            NSLog(@"✏️ 已更新Podfile");
            
            // 2. 删除Pods相关目录
            [self removePodsRelatedFiles];
        }
    }
}

+ (void)removePodsRelatedFiles {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *filesToRemove = @[@"Pods", @"Podfile.lock", @"Manifest.lock"];
    
    for (NSString *file in filesToRemove) {
        if ([fm fileExistsAtPath:file]) {
            [fm removeItemAtPath:file error:nil];
            NSLog(@"🗑️ 已删除: %@", file);
        }
    }
}




@end
