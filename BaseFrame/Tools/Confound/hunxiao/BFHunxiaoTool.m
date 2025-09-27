//
//  BFHunxiaoTool.m
//  BaseFrame
//
//  Created by 王祥伟 on 2025/4/10.
//

#import "BFHunxiaoTool.h"


@implementation BFHunxiaoTool

+ (BOOL)renameProjectAtPath:(NSString *)projectPath fromOldName:(NSString *)oldName toNewName:(NSString *)newName error:(NSError **)error {
    
    // 1. 验证路径是否存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:projectPath]) {
        if (error) {
            *error = [NSError errorWithDomain:@"XcodeProjectRenamer"
                                        code:1
                                    userInfo:@{NSLocalizedDescriptionKey: @"项目路径不存在"}];
        }
        return NO;
    }
    
    // 2. 重命名.xcodeproj文件
    NSString *oldProjectFilePath = [projectPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xcodeproj", oldName]];
    NSString *newProjectFilePath = [projectPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xcodeproj", newName]];
    
    if (![fileManager moveItemAtPath:oldProjectFilePath toPath:newProjectFilePath error:error]) {
        return NO;
    }
    
    // 3. 重命名.xcworkspace文件（如果存在）
    NSString *oldWorkspacePath = [projectPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xcworkspace", oldName]];
    if ([fileManager fileExistsAtPath:oldWorkspacePath]) {
        NSString *newWorkspacePath = [projectPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xcworkspace", newName]];
        if (![fileManager moveItemAtPath:oldWorkspacePath toPath:newWorkspacePath error:error]) {
            return NO;
        }
    }
    
    // 4. 修改.pbxproj文件中的引用
    NSString *pbxprojPath = [newProjectFilePath stringByAppendingPathComponent:@"project.pbxproj"];
    NSString *pbxprojContent = [NSString stringWithContentsOfFile:pbxprojPath
                                                        encoding:NSUTF8StringEncoding
                                                           error:error];
    if (!pbxprojContent) {
        return NO;
    }
    
    NSString *updatedPbxprojContent = [pbxprojContent stringByReplacingOccurrencesOfString:oldName withString:newName];
    if (![updatedPbxprojContent writeToFile:pbxprojPath
                                atomically:YES
                                  encoding:NSUTF8StringEncoding
                                     error:error]) {
        return NO;
    }
    
    // 5. 修改Scheme名称
    NSString *schemesPath = [newProjectFilePath stringByAppendingPathComponent:@"xcshareddata/xcschemes"];
    if ([fileManager fileExistsAtPath:schemesPath]) {
        NSArray *schemeFiles = [fileManager contentsOfDirectoryAtPath:schemesPath error:error];
        if (!schemeFiles) {
            return NO;
        }
        
        for (NSString *schemeFile in schemeFiles) {
            if ([schemeFile hasSuffix:@".xcscheme"]) {
                NSString *oldSchemePath = [schemesPath stringByAppendingPathComponent:schemeFile];
                NSString *newSchemeName = [schemeFile stringByReplacingOccurrencesOfString:oldName withString:newName];
                NSString *newSchemePath = [schemesPath stringByAppendingPathComponent:newSchemeName];
                
                if (![fileManager moveItemAtPath:oldSchemePath toPath:newSchemePath error:error]) {
                    return NO;
                }
                
                // 更新Scheme文件内容
                NSString *schemeContent = [NSString stringWithContentsOfFile:newSchemePath
                                                                    encoding:NSUTF8StringEncoding
                                                                       error:error];
                if (!schemeContent) {
                    return NO;
                }
                
                NSString *updatedSchemeContent = [schemeContent stringByReplacingOccurrencesOfString:oldName withString:newName];
                if (![updatedSchemeContent writeToFile:newSchemePath
                                           atomically:YES
                                             encoding:NSUTF8StringEncoding
                                                error:error]) {
                    return NO;
                }
            }
        }
    }
    
    // 6. 修改文件夹引用（可选）
    NSString *oldSourceDir = [projectPath stringByAppendingPathComponent:oldName];
    if ([fileManager fileExistsAtPath:oldSourceDir]) {
        NSString *newSourceDir = [projectPath stringByAppendingPathComponent:newName];
        if (![fileManager moveItemAtPath:oldSourceDir toPath:newSourceDir error:error]) {
            return NO;
        }
    }
    
    NSString *podfilePath = [projectPath stringByAppendingPathComponent:@"Podfile"];

     // 检查Podfile是否存在
     if (![fileManager fileExistsAtPath:podfilePath]) {
         // Podfile不存在不算错误
         return YES;
     }
     
     // 读取Podfile内容
     NSString *podfileContent = [NSString stringWithContentsOfFile:podfilePath encoding:NSUTF8StringEncoding error:error];
     if (!podfileContent) {
         return NO;
     }
     
     // 替换项目名称
     NSString *updatedPodfile = [podfileContent stringByReplacingOccurrencesOfString:oldName withString:newName];
     
     // 检查是否需要替换workspace名称
     NSString *workspacePattern = [NSString stringWithFormat:@"workspace\\s*['\"]%@['\"]", oldName];
     NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:workspacePattern options:0 error:error];
     if (!regex) {
         return NO;
     }
     
     updatedPodfile = [regex stringByReplacingMatchesInString:updatedPodfile
                                                   options:0
                                                     range:NSMakeRange(0, updatedPodfile.length)
                                              withTemplate:[NSString stringWithFormat:@"workspace '%@'", newName]];
     
     // 写回文件
     if (![updatedPodfile writeToFile:podfilePath atomically:YES encoding:NSUTF8StringEncoding error:error]) {
         return NO;
     }
    
    return YES;
}

+ (BOOL)renameMethodNameAtPath:(NSString *)projectPath wordType:(WordsType)wordType{
    NSArray *allMethodName = [BFGrabWordsTool scanMethodsInProjectAtPath:projectPath];
    NSArray *words = [BFGrabWordsTool getAllTxtWordsWithType:wordType];
    NSDictionary *dict = [BFGrabWordsTool replaceMethodNameWithOriginMethodList:allMethodName words:words];
    
    replaceStringsInFile(projectPath, dict);
    
    // 1. 遍历项目目录
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:projectPath];
    
    for (NSString *filePath in enumerator) {
        // 只处理.h和.m文件
        if (![filePath hasSuffix:@".h"] && ![filePath hasSuffix:@".m"] && ![filePath hasSuffix:@".mm"]) {
            continue;
        }
        
        // 过滤 Pods 目录下的文件
        if ([filePath containsString:@"/Pods/"] || [filePath hasPrefix:@"Pods/"]) {
            continue;
        }
        
        NSString *fullPath = [projectPath stringByAppendingPathComponent:filePath];
        NSError *error = nil;
        NSString *fileContent = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:&error];
        
        if (error) {
            NSLog(@"Error reading file %@: %@", fullPath, error);
            continue;
        }
        
        
        
    }
    
//    NSString *filePath = [NSString stringWithFormat:@"%@/%@_hunxiao.txt",kDocumentPath,projectPath.lastPathComponent];
//    NSError *error;
//    NSString *stringToSave = result.yy_modelToJSONString;
//    BOOL success = [stringToSave writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
//    if (!success) {
//        NSLog(@"写入文件失败: %@", error.localizedDescription);
//    } else {
//        NSLog(@"文件保存成功，路径: %@", filePath);
//    }
    return YES;
}














// 检查字符串是否符合替换条件（前后无字母）
BOOL shouldReplaceString(NSString *fullString, NSRange targetRange) {
    if (targetRange.location == NSNotFound) return NO;
    
    // 获取目标字符串的前一个字符和后一个字符
    unichar prevChar = (targetRange.location > 0) ? [fullString characterAtIndex:targetRange.location - 1] : 0;
    unichar nextChar = (targetRange.location + targetRange.length < fullString.length) ?
                      [fullString characterAtIndex:targetRange.location + targetRange.length] : 0;
    
    // 判断前后字符是否是非字母
    BOOL isPrevValid = !isalpha(prevChar);
    BOOL isNextValid = !isalpha(nextChar);
    
    return isPrevValid && isNextValid;
}

// 递归遍历目录，替换文件内容
void replaceStringsInDirectory(NSString *directoryPath, NSDictionary<NSString *, NSString *> *replaceDict) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray<NSString *> *contents = [fileManager contentsOfDirectoryAtPath:directoryPath error:nil];
    
    for (NSString *item in contents) {
        NSString *fullPath = [directoryPath stringByAppendingPathComponent:item];
        BOOL isDirectory;
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory]) {
            if (isDirectory) {
                // 跳过 Pods 目录
                if ([item isEqualToString:@"Pods"]) {
                    continue;
                }
                // 递归遍历子目录
                replaceStringsInDirectory(fullPath, replaceDict);
            } else {
                // 只处理 .h/.m/.swift/.mm 等代码文件
                if ([item hasSuffix:@".h"] || [item hasSuffix:@".m"] || [item hasSuffix:@".mm"] || [item hasSuffix:@".swift"]) {
                    replaceStringsInFile(fullPath, replaceDict);
                }
            }
        }
    }
}

// 替换单个文件的内容
void replaceStringsInFile(NSString *filePath, NSDictionary<NSString *, NSString *> *replaceDict) {
    NSError *error;
    NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (!fileContent || error) {
        NSLog(@"读取文件失败: %@", filePath);
        return;
    }
    
    BOOL hasChanges = NO;
    for (NSString *oldStr in replaceDict.allKeys) {
        NSString *newStr = replaceDict[oldStr];
        NSRange searchRange = NSMakeRange(0, fileContent.length);
        NSRange foundRange;
        
        while ((foundRange = [fileContent rangeOfString:oldStr options:0 range:searchRange]).location != NSNotFound) {
            // 检查是否符合替换条件
            if (shouldReplaceString(fileContent, foundRange)) {
                [fileContent replaceCharactersInRange:foundRange withString:newStr];
                hasChanges = YES;
                searchRange.location = foundRange.location + newStr.length;
                searchRange.length = fileContent.length - searchRange.location;
            } else {
                searchRange.location = foundRange.location + foundRange.length;
                searchRange.length = fileContent.length - searchRange.location;
            }
        }
    }
    
    // 如果有修改，写回文件
    if (hasChanges) {
        [fileContent writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            NSLog(@"写入文件失败: %@", filePath);
        } else {
            NSLog(@"已更新文件: %@", filePath);
        }
    }
}



@end
