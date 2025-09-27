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
//HLHeaderModel
+ (NSDictionary *)fileMapping100{
    return [self parseModuleMappingJSON:@"className_yueyi"];
}

+ (NSDictionary *)fileMapping102{
    return [self parseModuleMappingJSON:@"className_yueyi 2"];
}

+ (NSDictionary *)fileMapping101{
    NSArray *list = [self parseModuleArrayJSON:@"className_nvliao"].allObjects;
    return @{};
}

+ (void)customReplaceInDirectory:(NSString *)directory replaceDict:(NSDictionary *)replaceDict{
    NSString *string = [BFConfuseManager readObfuscationMappingFileAtPath:directory];
    if (string){
        NSData *jsonData = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
        [BFConfuseFile replaceInDirectory:directory replaceDict:dict];
    }else{
        [BFConfuseManager writeData:replaceDict toPath:directory fileName:@"混淆/文件名映射"];
        [BFConfuseFile replaceInDirectory:directory replaceDict:replaceDict];
    }
}

+ (void)randomReplaceInDirectory:(NSString *)directory replaceDict:(NSDictionary *)replaceDict{
    NSArray *list = [self getTotalControllersInDirectory:directory];
    NSArray *wordList = [BFConfuseManager searchAndProcessArray:list withPrefixes:nil];
    
    NSString *string = [BFConfuseManager readObfuscationMappingFileAtPath:directory];
    if (string){
        NSData *jsonData = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
        [BFConfuseFile replaceInDirectory:directory replaceDict:dict];
    }else{
        NSArray *replaceList = [BFWordsRackTool getWordsWithType:ReadingWordsType];
        NSDictionary *dict = [BFConfuseManager wordList:wordList prefix:@"YDS" replaceList:replaceList exceptList:@[@"Model"] replactDict:@{@"View":@"V",@"Controller":@"C",@"Table":@"T"}];
        [BFConfuseManager writeData:dict toPath:directory fileName:@"混淆/文件名映射"];
        [BFConfuseFile replaceInDirectory:directory replaceDict:dict];
    }
}

+ (NSArray *)getTotalControllersInDirectory:(NSString *)directory{
    NSArray *exceptDirs = @[@"Pods"];
    NSArray *includeFiles = @[@"h",@"swift"];
    NSString *pattern = @"(?<=@interface\\s)[A-Za-z_][A-Za-z0-9_]*(?=\\s*:)";
    NSArray *list = [BFConfuseManager searchDirectory:directory exceptDirs:exceptDirs includeFiles:includeFiles regexPattern:pattern returnPatten:YES error:nil];
    NSMutableArray *result = [NSMutableArray arrayWithArray:list];
    [result removeObjectsInArray:@[@"SceneDelegate",@"AppDelegate"]];
    return result;
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
                // 然后处理文件重命名
                [self renameFileIfNeeded:fullPath relativePath:relativePath replaceDict:replaceDict];
            }
        }
    }
}

// 新增：处理源代码文件内容替换
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
    [replaceDict enumerateKeysAndObjectsUsingBlock:^(NSString *oldName, NSString *newName, BOOL *stop) {
        // 使用单词边界确保完整匹配，大小写敏感
        NSString *pattern = [NSString stringWithFormat:@"\\b%@\\b", [NSRegularExpression escapedPatternForString:oldName]];
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:0
                                                                                 error:nil];
        if (regex) {
            NSUInteger replacements = [regex replaceMatchesInString:content
                                                            options:0
                                                              range:NSMakeRange(0, content.length)
                                                       withTemplate:newName];
            if (replacements > 0) {
                changesMade = YES;
                NSLog(@"在 %@ 中替换内容 %@ → %@ (%lu处)", filePath.lastPathComponent, oldName, newName, (unsigned long)replacements);
            }
        }
    }];
    
    if (changesMade) {
        if (![content writeToFile:filePath
                       atomically:YES
                         encoding:NSUTF8StringEncoding
                            error:&error]) {
            NSLog(@"写入失败: %@", error.localizedDescription);
        }
    }
}

// 保持原有的pbxproj文件处理方法
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
    [replaceDict enumerateKeysAndObjectsUsingBlock:^(NSString *oldName, NSString *newName, BOOL *stop) {
        NSString *pattern = [NSString stringWithFormat:@"(?<!\\w|\\+)%@(?=\\.(?:h|m|swift|mm)\\b)",[NSRegularExpression escapedPatternForString:oldName]];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:0
                                                                                 error:nil];
        if (!error) {
            NSUInteger replacements = [regex replaceMatchesInString:content
                                                            options:0
                                                              range:NSMakeRange(0, content.length)
                                                       withTemplate:newName];
            if (replacements > 0) {
                changesMade = YES;
                NSLog(@"替换 %@ → %@ (%lu处)", oldName, newName, (unsigned long)replacements);
            }
        }
    }];
    
    if (changesMade) {
        if (![content writeToFile:pbxprojPath
                       atomically:YES
                         encoding:NSUTF8StringEncoding
                            error:&error]) {
            NSLog(@"写入失败: %@", error.localizedDescription);
        }
    }
}

// 文件重命名方法（保持原有）
+ (void)renameFileIfNeeded:(NSString *)fullPath
              relativePath:(NSString *)relativePath
               replaceDict:(NSDictionary *)replaceDict {
    
    NSString *fileName = [relativePath lastPathComponent];
    NSString *fileNameWithoutExtension = [fileName stringByDeletingPathExtension];
    NSString *fileExtension = [fileName pathExtension];
    
    // 检查是否需要重命名（完全匹配，大小写敏感）
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
    }
}

// 判断是否应该处理该扩展名的文件
+ (BOOL)shouldProcessFileWithExtension:(NSString *)extension {
    // 修正：移除.pch前的点号
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
