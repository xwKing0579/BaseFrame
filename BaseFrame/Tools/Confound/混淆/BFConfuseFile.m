//
//  BFConfuseFile.m
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/2.
//

#import "BFConfuseFile.h"
#import "BFConfuseManager.h"
#import "BFWordsRackTool.h"

@implementation BFConfuseFile

+ (NSDictionary *)fileMapping{
    return [self parseModuleMappingJSON:@"className"];
}

+ (NSDictionary *)fileMapping1{
    return [self parseModuleMappingJSON:@"className_xixi"];
}

+ (NSDictionary *)fileMapping2{
    return [self parseModuleMappingJSON:@"className_wsg"];
}

+ (NSDictionary *)fileMapping3{
    return [self parseModuleMappingJSON:@"className_jingyuege"];
}

+ (NSDictionary *)fileMapping0{
    return [self parseModuleMappingJSON:@"className_spamCode"];
}


//QMUIConfigurationTemplate
//HLHeaderModel、HLUIHelper
+ (NSDictionary *)fileMapping100{
    return [self parseModuleMappingJSON:@"className_yueyi"];
}

+ (NSDictionary *)fileMapping102{
    return [self parseModuleMappingJSON:@"className_yueyi 2"];
}

+ (NSDictionary *)fileMapping103{
    return [self parseModuleMappingJSON:@"className_yueyi 3"];
}

+ (NSDictionary *)fileMapping101{
    NSArray *list = [self parseModuleArrayJSON:@"className_nvliao"].allObjects;
    return @{};
}

+ (void)replaceInDirectory:(NSString *)directory replaceDict:(NSDictionary *)replaceDict {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directory];
    
    for (NSString *relativePath in enumerator) {
        NSString *fullPath = [directory stringByAppendingPathComponent:relativePath];
        
        // 跳过Pods目录
        if ([relativePath containsString:@"Pods/"]) {
            [enumerator skipDescendants];
            continue;
        }
        
        BOOL isDirectory;
        [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
        
        // 只处理文件
        if (!isDirectory) {
            NSString *fileExtension = [relativePath pathExtension];
            
            // 处理.xcodeproj文件
            if ([fileExtension isEqualToString:@"pbxproj"]) {
                [self replaceInPbxprojFile:fullPath replaceDict:replaceDict];
            }
            // 处理其他指定类型的文件
            else if ([self shouldProcessFileWithExtension:fileExtension]) {
                // 先处理文件内容替换
                [self replaceInSourceFile:fullPath replaceDict:replaceDict];
                // 然后处理文件重命名（包括分类文件）
                [self renameFileIfNeeded:fullPath relativePath:relativePath replaceDict:replaceDict];
            }
        }
    }
}

// 修改后的文件重命名方法，支持分类文件名
+ (void)renameFileIfNeeded:(NSString *)fullPath
              relativePath:(NSString *)relativePath
               replaceDict:(NSDictionary *)replaceDict {
    
    NSString *fileName = [relativePath lastPathComponent];
    NSString *fileNameWithoutExtension = [fileName stringByDeletingPathExtension];
    NSString *fileExtension = [fileName pathExtension];
    
    // 精确匹配文件名（完全相等）
    if (replaceDict[fileNameWithoutExtension]) {
        NSString *newFileName = [NSString stringWithFormat:@"%@.%@",
                                 replaceDict[fileNameWithoutExtension],
                                 fileExtension];
        NSString *newFullPath = [[fullPath stringByDeletingLastPathComponent]
                                 stringByAppendingPathComponent:newFileName];
        
        NSError *error;
        if ([[NSFileManager defaultManager] moveItemAtPath:fullPath
                                                    toPath:newFullPath
                                                     error:&error]) {
            NSLog(@"🔄 重命名: %@ -> %@", fileName, newFileName);
        } else {
            NSLog(@"❌ 重命名失败 %@: %@", fileName, error.localizedDescription);
        }
    } else {
        // 处理分类文件名
        // 分类文件名格式：原类名+分类名 如: UIView+Category
        // 需要分别检查原类名部分和分类名部分
        
        NSRange plusRange = [fileNameWithoutExtension rangeOfString:@"+"];
        if (plusRange.location != NSNotFound) {
            // 提取原类名部分（+号之前的部分）
            NSString *originalClassName = [fileNameWithoutExtension substringToIndex:plusRange.location];
            NSString *categoryName = [fileNameWithoutExtension substringFromIndex:plusRange.location + 1];
            
            // 检查原类名和分类名是否在替换字典中（精确匹配）
            NSString *newOriginalClassName = replaceDict[originalClassName] ?: originalClassName;
            NSString *newCategoryName = replaceDict[categoryName] ?: categoryName;
            
            // 如果原类名或分类名有变化，则重命名文件
            if (![newOriginalClassName isEqualToString:originalClassName] ||
                ![newCategoryName isEqualToString:categoryName]) {
                
                // 构建新的分类文件名
                NSString *newFileNameWithoutExtension = [NSString stringWithFormat:@"%@+%@", newOriginalClassName, newCategoryName];
                NSString *newFileName = [NSString stringWithFormat:@"%@.%@", newFileNameWithoutExtension, fileExtension];
                NSString *newFullPath = [[fullPath stringByDeletingLastPathComponent]
                                         stringByAppendingPathComponent:newFileName];
                
                NSError *error;
                if ([[NSFileManager defaultManager] moveItemAtPath:fullPath
                                                            toPath:newFullPath
                                                             error:&error]) {
                    NSLog(@"🔄 重命名分类文件: %@ -> %@", fileName, newFileName);
                } else {
                    NSLog(@"❌ 分类文件重命名失败 %@: %@", fileName, error.localizedDescription);
                }
            }
        }
    }
}

// 改进的内容替换方法，支持精确匹配
+ (void)replaceInSourceFile:(NSString *)filePath replaceDict:(NSDictionary *)replaceDict {
    NSError *error = nil;
    NSMutableString *content = [NSMutableString stringWithContentsOfFile:filePath
                                                                encoding:NSUTF8StringEncoding
                                                                   error:&error];
    if (error) {
        NSLog(@"读取失败: %@", filePath.lastPathComponent);
        return;
    }
    
    __block BOOL changesMade = NO;
    
    // 按长度降序排序，先处理长的单词，避免部分替换问题
    NSArray *sortedKeys = [replaceDict keysSortedByValueUsingComparator:^NSComparisonResult(NSString *key1, NSString *key2) {
        return [@(key2.length) compare:@(key1.length)];
    }];
    
    for (NSString *oldName in sortedKeys) {
        NSString *newName = replaceDict[oldName];
        
        // 使用更精确的匹配模式，确保完全匹配
        // 匹配模式：单词边界或前面是非字母数字下划线字符
        NSString *pattern = [NSString stringWithFormat:@"(?:^|[^a-zA-Z0-9_])%@(?=$|[^a-zA-Z0-9_])",
                            [NSRegularExpression escapedPatternForString:oldName]];
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:0
                                                                                 error:nil];
        if (regex) {
            NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:content
                                                                      options:0
                                                                        range:NSMakeRange(0, content.length)];
            
            // 反向遍历避免范围变化问题
            for (NSInteger i = matches.count - 1; i >= 0; i--) {
                NSTextCheckingResult *match = matches[i];
                NSRange matchRange = match.range;
                
                // 检查是否是完整匹配（排除边界字符）
                NSString *matchedString = [content substringWithRange:matchRange];
                NSRange actualMatchRange = [matchedString rangeOfString:oldName];
                
                if (actualMatchRange.location != NSNotFound) {
                    // 计算实际要替换的范围
                    NSRange replaceRange = NSMakeRange(matchRange.location + actualMatchRange.location, oldName.length);
                    
                    // 执行替换
                    [content replaceCharactersInRange:replaceRange withString:newName];
                    changesMade = YES;
                    NSLog(@"在 %@ 中替换内容 %@ → %@", filePath.lastPathComponent, oldName, newName);
                }
            }
        }
    }
    
    if (changesMade) {
        if (![content writeToFile:filePath
                       atomically:YES
                         encoding:NSUTF8StringEncoding
                            error:&error]) {
            NSLog(@"写入失败: %@", error.localizedDescription);
        }
    }
}

// 改进的 .pbxproj 文件处理方法
+ (void)replaceInPbxprojFile:(NSString *)pbxprojPath replaceDict:(NSDictionary *)replaceDict {
    NSError *error = nil;
    NSMutableString *content = [NSMutableString stringWithContentsOfFile:pbxprojPath
                                                                encoding:NSUTF8StringEncoding
                                                                   error:&error];
    if (error) {
        NSLog(@"读取失败: %@", pbxprojPath.lastPathComponent);
        return;
    }
    
    __block BOOL changesMade = NO;
    
    // 按长度降序排序
    NSArray *sortedKeys = [replaceDict keysSortedByValueUsingComparator:^NSComparisonResult(NSString *key1, NSString *key2) {
        return [@(key2.length) compare:@(key1.length)];
    }];
    
    for (NSString *oldName in sortedKeys) {
        NSString *newName = replaceDict[oldName];
        
        // 精确匹配文件名模式
        // 匹配：文件名.扩展名 或 类名+分类名.扩展名
        NSString *pattern = [NSString stringWithFormat:@"\\b%@(?:\\.(?:h|m|mm|swift|pch)|\\+[^\\s\"]*\\.(?:h|m|mm|swift))\\b",
                            [NSRegularExpression escapedPatternForString:oldName]];
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:0
                                                                                 error:nil];
        if (regex) {
            NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:content
                                                                      options:0
                                                                        range:NSMakeRange(0, content.length)];
            
            // 反向遍历
            for (NSInteger i = matches.count - 1; i >= 0; i--) {
                NSTextCheckingResult *match = matches[i];
                NSString *matchedString = [content substringWithRange:match.range];
                NSString *replacedString = [self replaceFileNameInString:matchedString oldName:oldName newName:newName];
                
                if (![matchedString isEqualToString:replacedString]) {
                    [content replaceCharactersInRange:match.range withString:replacedString];
                    changesMade = YES;
                    NSLog(@"在 %@ 中替换项目引用: %@ → %@", pbxprojPath.lastPathComponent, matchedString, replacedString);
                }
            }
        }
    }
    
    if (changesMade) {
        if (![content writeToFile:pbxprojPath
                       atomically:YES
                         encoding:NSUTF8StringEncoding
                            error:&error]) {
            NSLog(@"写入失败: %@", error.localizedDescription);
        } else {
            NSLog(@"✅ 项目文件更新成功: %@", pbxprojPath.lastPathComponent);
        }
    }
}

// 辅助方法：替换文件名中的类名部分
+ (NSString *)replaceFileNameInString:(NSString *)fileNameString
                             oldName:(NSString *)oldName
                             newName:(NSString *)newName {
    
    NSString *fileExtension = [fileNameString pathExtension];
    NSString *fileNameWithoutExtension = [fileNameString stringByDeletingPathExtension];
    
    // 检查是否是分类文件
    NSRange plusRange = [fileNameWithoutExtension rangeOfString:@"+"];
    if (plusRange.location != NSNotFound) {
        // 分类文件：原类名+分类名
        NSString *originalClassName = [fileNameWithoutExtension substringToIndex:plusRange.location];
        NSString *categoryName = [fileNameWithoutExtension substringFromIndex:plusRange.location + 1];
        
        // 精确匹配替换
        NSString *newOriginalClassName = [originalClassName isEqualToString:oldName] ? newName : originalClassName;
        NSString *newCategoryName = [categoryName isEqualToString:oldName] ? newName : categoryName;
        
        return [NSString stringWithFormat:@"%@+%@.%@", newOriginalClassName, newCategoryName, fileExtension];
    } else {
        // 普通文件 - 精确匹配
        if ([fileNameWithoutExtension isEqualToString:oldName]) {
            return [NSString stringWithFormat:@"%@.%@", newName, fileExtension];
        }
    }
    
    return fileNameString;
}

+ (BOOL)shouldProcessFileWithExtension:(NSString *)extension {
    NSArray *allowedExtensions = @[@"h", @"m", @"mm", @"swift", @"pch"];
    return [allowedExtensions containsObject:extension.lowercaseString];
}





//===================================================================
+ (void)globalReplaceInDirectory:(NSString *)directory
                         oldName:(NSString *)oldName
                         newName:(NSString *)newName {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directory];
    
    // 支持的文件类型
    NSArray *supportedExtensions = @[@"h", @"m", @"mm", @"pbxproj", @"pch"];
    
    for (NSString *relativePath in enumerator) {
        NSString *fullPath = [directory stringByAppendingPathComponent:relativePath];
        
        if ([fullPath containsString:@"Pods"]) continue;
        
        
        // 跳过目录
        BOOL isDirectory;
        [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
        if (isDirectory) {
            continue;
        }
        
        NSString *fileExtension = [[relativePath pathExtension] lowercaseString];
        
        // 检查文件类型
        if (![supportedExtensions containsObject:fileExtension]) {
            continue;
        }
        
        // 1. 处理文件内容替换
        [self replaceContentInFile:fullPath oldName:oldName newName:newName];
        
        // 2. 处理文件名替换
        [self renameFileIfNeeded:fullPath oldName:oldName newName:newName];
        
    }
}

#pragma mark - 文件内容替换

+ (void)replaceContentInFile:(NSString *)filePath
                     oldName:(NSString *)oldName
                     newName:(NSString *)newName {
    NSError *error = nil;
    NSMutableString *content = [NSMutableString stringWithContentsOfFile:filePath
                                                                encoding:NSUTF8StringEncoding
                                                                   error:&error];
    if (error) {
        NSLog(@"⚠️ 读取失败: %@", filePath.lastPathComponent);
        return;
    }
    
    // 创建匹配三种模式的正则表达式（大小写敏感）
    NSString *basePattern = [NSString stringWithFormat:@"\\b%@\\b", [NSRegularExpression escapedPatternForString:oldName]];
    NSString *plusBasePattern = [NSString stringWithFormat:@"\\+%@\\b", [NSRegularExpression escapedPatternForString:oldName]];
    NSString *plusBaseDotPattern = [NSString stringWithFormat:@"\\+%@\\.", [NSRegularExpression escapedPatternForString:oldName]];
    
    NSString *combinedPattern = [NSString stringWithFormat:@"(%@)|(%@)|(%@)",
                                 basePattern, plusBasePattern, plusBaseDotPattern];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:combinedPattern
                                                                           options:0
                                                                             error:&error];
    if (error) {
        NSLog(@"❌ 正则表达式错误: %@", error.localizedDescription);
        return;
    }
    
    __block NSUInteger replacementCount = 0;
    
    // 获取所有匹配结果（从后往前处理）
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:content
                                                              options:0
                                                                range:NSMakeRange(0, content.length)];
    
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        NSRange matchedRange = match.range;
        NSString *matchedString = [content substringWithRange:matchedRange];
        
        // 确定替换内容
        NSString *replacement;
        if ([matchedString hasPrefix:@"+"] && [matchedString hasSuffix:@"."]) {
            replacement = [NSString stringWithFormat:@"+%@.", newName];
        } else if ([matchedString hasPrefix:@"+"]) {
            replacement = [NSString stringWithFormat:@"+%@", newName];
        } else {
            replacement = newName;
        }
        
        [content replaceCharactersInRange:matchedRange withString:replacement];
        replacementCount++;
    }
    
    if (replacementCount > 0) {
        if (![content writeToFile:filePath
                       atomically:YES
                         encoding:NSUTF8StringEncoding
                            error:&error]) {
            NSLog(@"❌ 写入失败: %@", error.localizedDescription);
        } else {
            NSLog(@"✅ %@: 替换 %@ → %@ (%lu处)",
                  filePath.lastPathComponent, oldName, newName, (unsigned long)replacementCount);
        }
    }
}

#pragma mark - 文件名替换

+ (void)renameFileIfNeeded:(NSString *)filePath
                   oldName:(NSString *)oldName
                   newName:(NSString *)newName {
    NSString *fileName = [filePath lastPathComponent];
    NSString *directory = [filePath stringByDeletingLastPathComponent];
    NSString *extension = [fileName pathExtension];
    NSString *fileNameWithoutExtension = [fileName stringByDeletingPathExtension];
    
    // 需要处理的四种情况
    NSDictionary *replaceRules = @{
        oldName: newName,                                // Base → NewBase
        [@"+" stringByAppendingString:oldName]:          // +Base → +NewBase
        [@"+" stringByAppendingString:newName],
        [oldName stringByAppendingString:@"."]:          // Base. → NewBase.
        [newName stringByAppendingString:@"."],
        [@"+" stringByAppendingString:oldName]:          // +Base. → +NewBase.
        [@"+" stringByAppendingString:newName]
    };
    
    // 处理 Category 形式的文件名 (NSObject+Base)
    if ([fileNameWithoutExtension containsString:@"+"]) {
        NSArray *components = [fileNameWithoutExtension componentsSeparatedByString:@"+"];
        if ([components.lastObject isEqualToString:oldName]) {
            NSString *newFileNameWithoutExtension = [NSString stringWithFormat:@"%@+%@",
                                                     components.firstObject, newName];
            NSString *newFileName = [newFileNameWithoutExtension stringByAppendingPathExtension:extension];
            
            [self performRename:filePath
                    newFilePath:[directory stringByAppendingPathComponent:newFileName]
                       fileName:fileName];
            return;
        }
    }
    
    // 处理普通替换规则
    __block BOOL shouldRename = NO;
    __block NSString *newFileName = nil;
    
    [replaceRules enumerateKeysAndObjectsUsingBlock:^(NSString *oldPattern, NSString *newPattern, BOOL *stop) {
        // 情况1：完整文件名匹配（无扩展名）
        if ([fileName isEqualToString:oldPattern]) {
            shouldRename = YES;
            newFileName = newPattern;
            *stop = YES;
        }
        // 情况2：文件名前缀匹配（带扩展名）
        else if ([fileNameWithoutExtension isEqualToString:oldPattern]) {
            shouldRename = YES;
            newFileName = [newPattern stringByAppendingPathExtension:extension];
            *stop = YES;
        }
        // 情况3：带点号的特殊情况
        else if ([fileNameWithoutExtension hasSuffix:oldPattern] &&
                 [fileNameWithoutExtension length] > [oldPattern length]) {
            shouldRename = YES;
            NSString *prefix = [fileNameWithoutExtension substringToIndex:
                                fileNameWithoutExtension.length - oldPattern.length];
            newFileName = [[prefix stringByAppendingString:newPattern]
                           stringByAppendingPathExtension:extension];
            *stop = YES;
        }
    }];
    
    if (shouldRename) {
        [self performRename:filePath
                newFilePath:[directory stringByAppendingPathComponent:newFileName]
                   fileName:fileName];
    }
}

+ (void)performRename:(NSString *)oldPath
          newFilePath:(NSString *)newPath
             fileName:(NSString *)fileName {
    NSError *error;
    if ([[NSFileManager defaultManager] moveItemAtPath:oldPath
                                                toPath:newPath
                                                 error:&error]) {
        NSLog(@"🔄 重命名成功: %@ → %@", fileName, [newPath lastPathComponent]);
    } else {
        NSLog(@"❌ 重命名失败 %@: %@", fileName, error.localizedDescription);
    }
}





@end
