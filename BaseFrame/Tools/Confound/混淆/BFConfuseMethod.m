//
//  BFConfuseMethod.m
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/2.
//

#import "BFConfuseMethod.h"
#import "BFConfuseProperty.h"
#import "BFConfuseManager.h"
static NSArray *_propertyList = @[];
@implementation BFConfuseMethod

+ (NSDictionary *)mapMethodDict{
    return [self parseModuleMappingJSON:@"method"];
}

+ (NSDictionary *)mapMethodDict2{
    return [self parseModuleMappingJSON:@"method_wsg"];
}

+ (NSDictionary *)mapMethodDict1{
    return [self parseModuleMappingJSON:@"method_xixi"];
}

+ (NSDictionary *)mapMethodDict4{
    return [self parseModuleMappingJSON:@"method_jingyuege"];
}


+ (NSDictionary *)mapMethodDict100{
    return [self parseModuleMappingJSON:@"method_yueyi"];
}

+ (NSDictionary *)mapMethodDict102{
    return [self parseModuleMappingJSON:@"method_yueyi 2"];
}

+ (NSDictionary *)mapMethodDict101{
    NSArray *list = [self parseModuleArrayJSON:@"method_yueyi 2"].allObjects;
    NSMutableArray *array = [NSMutableArray array];
    

    for (NSString *obj in list) {
        if (![[self sysMethodList] containsObject:obj] && ![obj hasSuffix:@"Button"] && ![obj hasSuffix:@"Btn"] && ![obj hasSuffix:@"View"] && ![obj hasSuffix:@"Label"] && ![obj hasSuffix:@"ImageView"] && ![obj hasSuffix:@"ImgView"] && ![obj hasSuffix:@"Control"]){
            [array addObject:obj];
        }
    }
    
    NSArray *sortedArray = [array sortedArrayUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
        if (str1.length < str2.length) {
            return NSOrderedAscending;
        } else if (str1.length > str2.length) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    NSLog(@"%@",[sortedArray filterRepeatItems]);
    return @{};
}

+ (NSArray<NSString *> *)extractAllMethodNamesFromProject:(NSString *)projectPath {
    NSMutableSet<NSString *> *methodNames = [NSMutableSet set];
    
    NSArray<NSString *> *excludeDirs = @[@"Pods",@"Package",@"Debug",@"DBSDKModule",@"ThirdParty",@".git",@".build",@"DerivedData"];
    NSArray<NSString *> *filePaths = [self findAllSourceFilesInPath:projectPath excludeDirs:excludeDirs];
    
    NSLog(@"Found %lu source files to analyze", (unsigned long)filePaths.count);
    
    for (NSString *filePath in filePaths) {
        @autoreleasepool {
            NSError *error;
            NSString *fileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
            if (!error && fileContent.length > 0) {
                if ([filePath hasSuffix:@".swift"]) {
                    [self parseSwiftFile:fileContent intoSet:methodNames];
                } else if ([filePath hasSuffix:@".m"] || [filePath hasSuffix:@".h"] || [filePath hasSuffix:@".mm"]) {
                    [self parseObjCFile:fileContent intoSet:methodNames];
                }
            }
        }
    }
    
    return [[methodNames allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

+ (void)parseObjCFile:(NSString *)content intoSet:(NSMutableSet<NSString *> *)set {
    // Objective-C方法模式：只匹配冒号前的方法名部分
    NSString *pattern = @"[-+]\\s*\\([^\\)]+\\)\\s*([A-Za-z_][A-Za-z0-9_]*)(?=:|\\s|;|\\(|\\{)";
    
    NSError *regexError;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&regexError];
    if (regexError) {
        NSLog(@"Regex error: %@", regexError);
        return;
    }
    
    [regex enumerateMatchesInString:content options:0 range:NSMakeRange(0, content.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        if (result.range.location == NSNotFound) return;
        
        NSRange methodNameRange = [result rangeAtIndex:1];
        if (methodNameRange.location == NSNotFound) return;
        
        NSString *methodName = [content substringWithRange:methodNameRange];
        methodName = [methodName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // 过滤系统方法
        if (![self isSystemMethod:methodName] && methodName.length > 6) {
            [set addObject:methodName];
        }
    }];
}

+ (void)parseSwiftFile:(NSString *)content intoSet:(NSMutableSet<NSString *> *)set {
    // Swift方法模式：匹配func声明
    NSString *pattern = @"func\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*(?:\\([^\\)]*\\))?\\s*(?:->\\s*[^\\{]*)?\\{";
    
    NSError *regexError;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&regexError];
    if (regexError) {
        NSLog(@"Regex error: %@", regexError);
        return;
    }
    
    [regex enumerateMatchesInString:content options:0 range:NSMakeRange(0, content.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        if (result.range.location == NSNotFound) return;
        
        NSRange methodNameRange = [result rangeAtIndex:1];
        if (methodNameRange.location == NSNotFound) return;
        
        NSString *methodName = [content substringWithRange:methodNameRange];
        methodName = [methodName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // 过滤系统方法
        if (![self isSystemMethod:methodName] && methodName.length > 6) {
            [set addObject:methodName];
        }
    }];
}

+ (BOOL)isSystemMethod:(NSString *)methodName {
    // 常见的系统方法和属性访问器
    NSArray *systemMethods = [self sysMethodList];
    
    // 过滤属性访问器（setter/getter）
    if ([methodName hasPrefix:@"set"] && methodName.length > 3) {
        // 检查是否是setter方法（setXxx:格式）
        NSString *remaining = [methodName substringFromIndex:3];
        if (remaining.length > 0) {
            unichar firstChar = [remaining characterAtIndex:0];
            if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:firstChar]) {
                return YES;
            }
        }
    }
    
    // 过滤以下划线开头或结尾的方法
    if ([methodName hasPrefix:@"_"] || [methodName hasSuffix:@"_"]) {
        return YES;
    }
    
    // 过滤系统方法
    return [systemMethods containsObject:methodName];
}

+ (NSArray<NSString *> *)findAllSourceFilesInPath:(NSString *)path excludeDirs:(NSArray<NSString *> *)excludeDirs {
    NSMutableArray *sourceFiles = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 检查路径是否存在且是目录
    BOOL isDirectory;
    if (![fileManager fileExistsAtPath:path isDirectory:&isDirectory] || !isDirectory) {
        NSLog(@"Path does not exist or is not a directory: %@", path);
        return sourceFiles;
    }
    
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:path];
    NSString *filePath;
    
    while ((filePath = [enumerator nextObject])) {
        // 跳过隐藏文件和目录
        if ([filePath hasPrefix:@"."] || [filePath containsString:@".framework"] || [filePath containsString:@".xcframework"]) {
            [enumerator skipDescendants];
            continue;
        }
        
        // 检查是否在排除目录中
        BOOL shouldExclude = NO;
        for (NSString *excludeDir in excludeDirs) {
            NSArray *pathComponents = [filePath pathComponents];
            for (NSString *component in pathComponents) {
                if ([component isEqualToString:excludeDir]) {
                    shouldExclude = YES;
                    [enumerator skipDescendants];
                    break;
                }
            }
            if (shouldExclude) break;
        }
        
        if (!shouldExclude) {
            NSString *extension = [[filePath pathExtension] lowercaseString];
            if ([@[@"h",@"m",@"mm",@"swift"] containsObject:extension]) {
                NSString *fullPath = [path stringByAppendingPathComponent:filePath];
                [sourceFiles addObject:fullPath];
            }
        }
    }
    
    return sourceFiles;
}


//+ (NSArray<NSString *> *)extractAllMethodNamesFromProject:(NSString *)projectPath {
//    NSMutableSet<NSString *> *methodNames = [NSMutableSet set];
//
//    NSArray<NSString *> *excludeDirs = @[@"Pods",@"Package",@"Debug",@"DBSDKModule",@"ThirdParty"];
//    NSArray<NSString *> *filePaths = [self findAllSourceFilesInPath:projectPath excludeDirs:excludeDirs];
//
//    for (NSString *filePath in filePaths) {
//        NSError *error;
//        NSString *fileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
//        if (!error) {
//            if ([filePath hasSuffix:@".swift"]) {
//                [self parseSwiftFile:fileContent intoSet:methodNames];
//            } else {
//                [self parseObjCFile:fileContent intoSet:methodNames];
//            }
//        }
//    }
//
//    return [[methodNames allObjects] sortedArrayUsingSelector:@selector(compare:)];
//}
//
//+ (void)parseObjCFile:(NSString *)content intoSet:(NSMutableSet<NSString *> *)set {
//    // Objective-C method pattern (matches both - and + methods)
//    NSString *pattern = @"[-+]\\s*\\([^\\)]+\\)\\s*([^\\s:]+)(?::\\([^\\)]+\\)\\s*([^\\s]+)\\s*)*";
//    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
//
//    [regex enumerateMatchesInString:content options:0 range:NSMakeRange(0, content.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
//        if (result.numberOfRanges >= 2) {
//            NSRange methodNameRange = [result rangeAtIndex:1];
//            if (methodNameRange.location != NSNotFound) {
//                NSString *methodPart = [content substringWithRange:methodNameRange];
//
//                // Handle methods with parameters
//                NSMutableString *fullMethodName = [NSMutableString stringWithString:methodPart];
//
//                // Check for additional parameters
//                for (int i = 2; i < result.numberOfRanges; i++) {
//                    NSRange paramNameRange = [result rangeAtIndex:i];
//                    if (paramNameRange.location != NSNotFound) {
//                        NSString *paramPart = [content substringWithRange:paramNameRange];
//                        if (paramPart.length > 0) {
//                            [fullMethodName appendFormat:@":%@", paramPart];
//                            break; // We only need the first parameter name for the method signature
//                        }
//                    }
//                }
//
//                [set addObject:fullMethodName];
//            }
//        }
//    }];
//}
//
//+ (void)parseSwiftFile:(NSString *)content intoSet:(NSMutableSet<NSString *> *)set {
//    // Swift method pattern (matches func declarations)
//    NSString *pattern = @"func\\s+([^(]+)\\(";
//    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
//
//    [regex enumerateMatchesInString:content options:0 range:NSMakeRange(0, content.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
//        if (result.numberOfRanges >= 2) {
//            NSRange methodNameRange = [result rangeAtIndex:1];
//            if (methodNameRange.location != NSNotFound) {
//                NSString *methodName = [content substringWithRange:methodNameRange];
//                methodName = [methodName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//                if (![self.sysMethodList containsObject:methodName])
//                    [set addObject:methodName];
//            }
//        }
//    }];
//}
//
//+ (NSArray<NSString *> *)findAllSourceFilesInPath:(NSString *)path excludeDirs:(NSArray<NSString *> *)excludeDirs {
//    NSMutableArray *sourceFiles = [NSMutableArray array];
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//
//    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:path];
//    NSString *filePath;
//
//    while ((filePath = [enumerator nextObject])) {
//        BOOL shouldExclude = NO;
//
//        // Check if this file is in any of the excluded directories
//        for (NSString *excludeDir in excludeDirs) {
//            if ([filePath containsString:excludeDir]) {
//                shouldExclude = YES;
//                break;
//            }
//        }
//
//        if (!shouldExclude) {
//            if ([filePath hasSuffix:@".h"] || [filePath hasSuffix:@".m"] || [filePath hasSuffix:@".swift"]) {
//                [sourceFiles addObject:[path stringByAppendingPathComponent:filePath]];
//            }
//        }
//    }
//
//    return sourceFiles;
//}



/////////////////////////////////////////////////////////////////
+ (void)safeReplaceContentInDirectory:(NSString *)directoryPath
                          excludeDirs:(NSArray<NSString *> *)excludeDirs
                        renameMapping:(NSDictionary<NSString *, NSString *> *)renameMapping {
    
    NSString *methodMap = [BFConfuseManager readObfuscationMappingFileAtPath:directoryPath name:@"方法名映射"];
    if (methodMap){
        NSData *jsonData = [methodMap dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
        renameMapping = dict;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directoryPath];
    
    for (NSString *relativePath in enumerator) {
        NSString *fullPath = [directoryPath stringByAppendingPathComponent:relativePath];
        
        // 检查是否是排除的目录
        BOOL shouldExclude = NO;
        for (NSString *excludeDir in excludeDirs) {
            if ([relativePath hasPrefix:excludeDir] || [relativePath containsString:@".framework"] || [relativePath containsString:@".xcframework"]) {
                shouldExclude = YES;
                [enumerator skipDescendants];
                break;
            }
        }
        if (shouldExclude) {
            continue;
        }
        
        // 只处理普通文件
        BOOL isDirectory;
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory] && !isDirectory) {
            [self safeReplaceContentInFile:fullPath withMapping:renameMapping];
        }
    }
    
    [BFConfuseManager writeData:renameMapping toPath:directoryPath fileName:@"混淆/方法名映射"];
}

+ (void)safeReplaceContentInFile:(NSString *)filePath withMapping:(NSDictionary<NSString *, NSString *> *)mapping {
    NSError *error;
    NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:filePath
                                                                    encoding:NSUTF8StringEncoding
                                                                       error:&error];
    if (error) {
        NSLog(@"Error reading file %@: %@", filePath, error.localizedDescription);
        return;
    }
    
    BOOL contentChanged = NO;
    for (NSString *key in mapping) {
        NSString *value = mapping[key];
        NSRange searchRange = NSMakeRange(0, fileContent.length);
        
        while (YES) {
            // 查找key出现的位置（区分大小写）
            NSRange foundRange = [fileContent rangeOfString:key
                                                    options:NSLiteralSearch
                                                      range:searchRange];
            
            if (foundRange.location == NSNotFound) {
                break;
            }
            
            // 检查前后字符是否符合要求
            BOOL isValid = YES;
            
            // 检查前一个字符
            if (foundRange.location > 0) {
                unichar prevChar = [fileContent characterAtIndex:foundRange.location - 1];
                if ([self isAlphanumeric:prevChar]) {
                    isValid = NO;
                }
            }
            
            // 检查后一个字符
            if (isValid && foundRange.location + foundRange.length < fileContent.length) {
                unichar nextChar = [fileContent characterAtIndex:foundRange.location + foundRange.length];
                if ([self isAlphanumeric:nextChar]) {
                    isValid = NO;
                }
            }
            
            if (isValid) {
                // 执行替换
                [fileContent replaceCharactersInRange:foundRange withString:value];
                contentChanged = YES;
                
                // 更新搜索范围（因为内容长度可能已改变）
                NSUInteger newLocation = foundRange.location + value.length;
                searchRange = NSMakeRange(newLocation, fileContent.length - newLocation);
            } else {
                // 跳过这个匹配，继续搜索
                searchRange = NSMakeRange(foundRange.location + foundRange.length,
                                          fileContent.length - (foundRange.location + foundRange.length));
            }
        }
    }
    
    if (contentChanged) {
        error = nil;
        [fileContent writeToFile:filePath
                      atomically:YES
                        encoding:NSUTF8StringEncoding
                           error:&error];
        if (error) {
            NSLog(@"Error writing file %@: %@", filePath, error.localizedDescription);
        } else {
            NSLog(@"Updated file: %@", filePath);
        }
    }
}

+ (BOOL)isAlphanumeric:(unichar)c {
    return (c >= 'a' && c <= 'z') ||
    (c >= 'A' && c <= 'Z') ||
    (c >= '0' && c <= '9');
}




#pragma mark - Helper Methods



+ (NSArray<NSString *> *)extractMethodNamesFromString:(NSString *)content{
    NSMutableArray<NSString *> *methods = [NSMutableArray array];
    
    // Regular expression pattern to match Objective-C method declarations
    NSString *pattern = @"(?:^|\\n)[+-]\\s*\\([^\\)]+\\)\\s*[^\\{;]+?(?=\\s*[\\{;])";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:content options:0 range:NSMakeRange(0, content.length)];
    
    for (NSTextCheckingResult *match in matches) {
        NSString *methodDeclaration = [content substringWithRange:match.range];
        
        // Clean up the method name by:
        // 1. Removing extra whitespace/newlines
        // 2. Trimming whitespace from both ends
        NSString *cleanedMethod = [methodDeclaration stringByReplacingOccurrencesOfString:@"\\s+" withString:@" " options:NSRegularExpressionSearch range:NSMakeRange(0, methodDeclaration.length)];
        cleanedMethod = [cleanedMethod stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (![methods containsObject:cleanedMethod] && ![cleanedMethod containsString:@"yd_"] && ![cleanedMethod containsString:@"BF"] && ![cleanedMethod containsString:@"tc_"]) [methods addObject:cleanedMethod];
    }
    
    return [methods copy];
}




+ (NSArray<NSString *> *)filterArrayKeepingLongestStrings:(NSArray<NSString *> *)originalArray {
    
    // 首先按长度降序排序所有字符串
    NSArray<NSString *> *sortedArray = [originalArray sortedArrayUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
        return [@(str2.length) compare:@(str1.length)];
    }];
    
    // 用于存储最终结果的集合
    NSMutableSet<NSString *> *resultSet = [NSMutableSet set];
    
    for (NSString *currentString in sortedArray) {
        BOOL isSubstringOfLongerString = NO;
        
        // 检查当前字符串是否是结果集中某个更长字符串的前缀
        for (NSString *existingString in resultSet) {
            if ([existingString hasPrefix:currentString] && existingString.length > currentString.length) {
                isSubstringOfLongerString = YES;
                break;
            }
        }
        
        // 如果不是任何更长字符串的前缀，则添加到结果集
        if (!isSubstringOfLongerString) {
            [resultSet addObject:currentString];
        }
    }
    
    // 如果需要保持原始顺序，可以按原始索引排序
    NSArray<NSString *> *resultArray = [resultSet allObjects];
    resultArray = [resultArray sortedArrayUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
        NSUInteger index1 = [originalArray indexOfObject:str1];
        NSUInteger index2 = [originalArray indexOfObject:str2];
        return [@(index1) compare:@(index2)];
    }];
    
    return resultArray;
}

+ (NSArray *)retainsFilterin:(NSArray *)methodList{
    NSMutableArray *temp = [NSMutableArray array];
    for (NSString *string in methodList) {
        if ([string hasPrefix:@"+ (UIColor *)c"] || [string hasPrefix:@"+ (UIFont *)pingFang"]) continue;
        if ([string componentsSeparatedByString:@":"].count < 2){
            
            NSArray <NSString *>*retainList = [string componentsSeparatedByString:@")"];
            
            NSString *lastStr = retainList.lastObject.whitespace;
            if (lastStr.length < 7) continue;
            
            //去掉带数字的
            NSCharacterSet *digitSet = [NSCharacterSet decimalDigitCharacterSet];
            NSRange range = [lastStr rangeOfCharacterFromSet:digitSet];
            if (range.location != NSNotFound) continue;
            
            if (![self.sysMethodList containsObject:lastStr] && ![_propertyList containsObject:lastStr])
                [temp addObject:lastStr];
        }
    }
    return temp;
}




+ (NSArray *)defaultExcludeFolders {
    return @[
        @"Pods",
        @".framework",
        @".xcworkspace",
        @".xcodeproj",
        @"DerivedData",
        @"Carthage",
        @".bundle",
        @"vendor",
        @"ThirdParty",
        @"Libraries"
    ];
}

+ (BOOL)shouldExcludePath:(NSString *)filePath excludeFolders:(NSArray *)excludeFolders {
    for (NSString *folder in excludeFolders) {
        if ([filePath containsString:folder]) {
            return YES;
        }
    }
    return NO;
}

+ (void)detectSetterMethodInProject:(NSString *)projectPath
                       propertyName:(NSString *)propertyName
                     excludeFolders:(NSArray *)excludeFolders {
    
    NSString *setterName = [NSString stringWithFormat:@"set%@:",
                           [propertyName capitalizedString]];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:projectPath];
    
    NSMutableArray *foundFiles = [NSMutableArray array];
    NSMutableArray *excludedFiles = [NSMutableArray array];
    NSString *filePath;
    
    while ((filePath = [enumerator nextObject])) {
        NSString *extension = [filePath pathExtension];
        
        // 只检查 .m 和 .mm 文件
        if ([extension isEqualToString:@"m"] || [extension isEqualToString:@"mm"]) {
            
            // 检查是否在白名单中
            if ([self shouldExcludePath:filePath excludeFolders:excludeFolders]) {
                [excludedFiles addObject:filePath];
                continue; // 跳过这个文件
            }
            
            NSString *fullPath = [projectPath stringByAppendingPathComponent:filePath];
            
            NSError *error;
            NSString *fileContent = [NSString stringWithContentsOfFile:fullPath
                                                             encoding:NSUTF8StringEncoding
                                                                error:&error];
            
            if (!error && fileContent) {
                NSRange range = [fileContent rangeOfString:setterName];
                if (range.location != NSNotFound) {
                    [foundFiles addObject:filePath];
                    
                    NSString *context = [self getContextFromContent:fileContent
                                                          atRange:range
                                                      linesBefore:2
                                                       linesAfter:2];
                    
                    NSLog(@"✅ 在文件中找到: %@", filePath);
                    NSLog(@"📄 上下文:\n%@", context);
                    NSLog(@"---");
                }
            }
        }
    }
    
    // 输出结果汇总
    [self printSummaryForProperty:propertyName
                        foundFiles:foundFiles
                    excludedFiles:excludedFiles
                    excludeFolders:excludeFolders];
}

+ (void)detectSetterMethodInProject:(NSString *)projectPath
                       propertyName:(NSString *)propertyName {
    
    // 使用默认白名单
    [self detectSetterMethodInProject:projectPath
                         propertyName:propertyName
                       excludeFolders:[self defaultExcludeFolders]];
}

+ (void)detectMultipleSettersInProject:(NSString *)projectPath
                         propertyNames:(NSArray *)propertyNames
                        excludeFolders:(NSArray *)excludeFolders {
    

    for (NSString *propertyName in propertyNames) {
        [self detectSetterMethodInProject:projectPath
                             propertyName:propertyName
                           excludeFolders:excludeFolders];
    }
}

+ (void)printSummaryForProperty:(NSString *)propertyName
                      foundFiles:(NSArray *)foundFiles
                    excludedFiles:(NSArray *)excludedFiles
                   excludeFolders:(NSArray *)excludeFolders {
    
    NSLog(@"==========================================");
    NSLog(@"📊 检测结果汇总");
    NSLog(@"目标属性: %@", propertyName);
    NSLog(@"目标方法: set%@:", [propertyName capitalizedString]);
    NSLog(@"排除目录: %@", [excludeFolders componentsJoinedByString:@", "]);
    NSLog(@"------------------------------------------");
    
    if (foundFiles.count > 0) {
        NSLog(@"🎉 共在 %lu 个文件中找到目标方法:", (unsigned long)foundFiles.count);
        for (NSString *file in foundFiles) {
            NSLog(@"   📍 %@", file);
        }
    } else {
        NSLog(@"❌ 未在项目中找到目标方法");
    }
    
    if (excludedFiles.count > 0) {
        NSLog(@"\n🚫 已排除 %lu 个第三方库文件:", (unsigned long)excludedFiles.count);
        // 只显示前10个排除的文件，避免输出太长
        NSInteger maxShow = MIN(10, excludedFiles.count);
        for (NSInteger i = 0; i < maxShow; i++) {
            NSLog(@"   ⏩ %@", excludedFiles[i]);
        }
        if (excludedFiles.count > maxShow) {
            NSLog(@"   ... 还有 %lu 个文件被排除", (unsigned long)(excludedFiles.count - maxShow));
        }
    }
    
    NSLog(@"==========================================\n");
}

+ (NSString *)getContextFromContent:(NSString *)content
                           atRange:(NSRange)targetRange
                       linesBefore:(NSUInteger)before
                        linesAfter:(NSUInteger)after {
    
    __block NSUInteger targetLineNumber = 0;
    __block NSUInteger currentIndex = 0;
    
    [content enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        currentIndex += line.length + 1;
        if (currentIndex >= targetRange.location) {
            targetLineNumber++;
            *stop = YES;
        } else {
            targetLineNumber++;
        }
    }];
    
    NSArray *lines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSInteger startLine = MAX(0, (NSInteger)targetLineNumber - before - 1);
    NSInteger endLine = MIN(lines.count, targetLineNumber + after);
    
    NSMutableString *context = [NSMutableString string];
    for (NSInteger i = startLine; i < endLine; i++) {
        NSString *line = lines[i];
        if (i == targetLineNumber - 1) {
            [context appendFormat:@">>> %@\n", line];
        } else {
            [context appendFormat:@"    %@\n", line];
        }
    }
    
    return context;
}


+ (NSArray *)sysMethodList{
    return @[
        @"onResults",
        @"decodeAttachment",
        @"encodeAttachment",
        @"transMessage",
        @"onKickout",
        @"sessionConfig",
        @"hideLoadingIndicator",
        @"didTapMessage",
        @"footerViewHeight",
        @"cellTopLabelHeight",
        @"messageStyle",
        @"inputBar",
        @"cellTopLabelAttributedText",
        @"setupCustomCell",
        @"mj_objectClassInArray",
        @"mj_newValueFromOldValue",
        @"mj_replacedKeyFromPropertyName",
        @"requestHeaderFieldValueDictionary",
        @"requestSerializerType",
        @"requestFailed",
        @"isSuccess",
        @"tearDown",
        @"testExample",
        @"testPerformanceExample",
        @"requestMethod",
        @"systemLang",
        @"systemArea",
        @"requestFinished",
        @"applyConfigurationTemplate",
        @"itemWithImage",
        @"sendMessageReceipt",
        @"beginRefreshing",
        @"startListening",
        @"searchMessages",
        @"updateMessage",
        @"deleteMessage",
        @"callStatus",
        @"muteLocalAudio",
        @"adjustPlaybackSignalVolume",
        @"backCameraInput",
        @"frontCameraInput",
        @"enableLocalVideo",
        @"handLinkURL",
        @"showLoading",
        @"longValue",
        @"shortValue",
        @"charValue",
        @"numberValue",
        @"placeholderColor",
        @"colorWithHue",
        @"saturation",
        @"addDelegates",
        @"addDelegate",
        @"navigationBar",
        @"actionSheet",
        @"rowHeight",
        @"indicatorInfo",
        @"currentSender",
        @"messageForItem",
        @"observeValue",
        @"requestFailedFilter",
        @"initSubviews",
        @"requestCompleteFilter",
        @"requestArgument",
        @"requestUrl",
        @"separatorColor",
        @"minuteInterval",
        @"qmui_titleViewTintColor",
        @"setupNavigationItems",
        @"quickLoginBtnAction",
        @"qmui_navigationBarTintColor",
        @"didMoveToParentViewController",
        @"startWithCompletionBlockWithSuccess",
        @"scrollViewDidEndScrollingAnimation",
        @"shouldApplyTemplateAutomatically",
        @"qmui_navigationBarBackgroundImage",
        @"replaceEmojiForAttributedString",@"requestTimeoutInterval",@"resetCameraFocusAndExposureMode",
        @"requestTimeoutInterval",@"resetCameraFocusAndExposureMode",@"resetCameraPosition",@"resetCameraSettings",
        @"resetDecoder",@"resetPlayer",@"resetView",@"resumeAnimation",@"resumePlayer",
        @"saveImageToPhotoAlbum",@"scheduledTimerWithName",@"scrollToBottom",
        @"scrollToNextPageAnimated",@"scrollToPreviousPageAnimated",@"scrollToViewCenter",@"sendAction",
        @"sendButton",@"sendEvent",@"sendMessage",@"serviceExtensionTimeWillExpire",
        @"shouldHideKeyboardWhenTouchInView",@"shouldInsertTimestamp",
        @"shouldPopViewControllerByBackButtonOrPopGesture",@"showActionSheet",@"showActionSheetWithTitle",
        @"showAlert",@"showAlertWithTitle",@"showFromNavigationController",@"showFromRect",
        @"showFromTabBarController",@"showMenuInView",@"snapshotImage",@"switchCameraPosition",
        @"systemLanguage",@"textField",@"textStorage",@"textViewInputAccessoryView",@"timeLabel",@"timeout",
        @"titleLabel",@"unregisterApplicationObservers",
        @"unregisterPlayerItemNoticationObservers",@"updateAccessibilityElements",@"updateApnsToken",
        @"viewForPinSectionHeaderInPagerView",
        @"webSafeDecodeData",@"webSafeDecodeString",@"webSafeEncodeData",@"webSocket",
        @"webSocketDidOpen",@"willChangeHeight",@"willSendMessage",@"onViewDidDisappear",@"onViewWillAppear",
        @"pageControl",@"placeholder",@"playAudio",@"playButton",@"playVideo",@"playbackState",
        @"playerDidFinish",@"playerDidStart",@"playerItemDidReachEnd",@"playerItemFailedToPlayToEndTime",
        @"playing",@"preferredNavigationBarHidden",@"prepareToPlay",@"previewLayer",@"progress",
        @"progressView",@"reachabilityChanged",@"reachabilityForInternetConnection",
        @"reachabilityForLocalWiFi",@"reachabilityWithAddress",@"reachabilityWithHostName",@"readDuration",
        @"refresh",@"refreshData",@"registerApplicationObservers",
        @"registerNotification",@"registerPlayerItemNoticationObservers",@"reloadData",
        @"removeNotificationObserver",@"removePlayerKeyValueObservers",@"isAppExtension",@"isPlaying",
        @"isValidURL",@"keyboardWillChangeFrame",@"keyboardWillHide",
        @"keyboardWillShow",@"layoutAttributesForItemAtIndexPath",@"loadData",@"loadState",@"locationManager",
        @"makeConstraints",@"mediaPlayer",@"moviePlayDidEnd",@"moviePlaybackComplete",@"nameLabel",
        @"networkStatusHandler",@"normalBackgroundImage",@"numberOfRows",
        @"numberOfSectionsInCollectionView",@"observeValueForKeyPath",@"onApplicationDidBecomeActive",
        @"onCancel",@"onClose",@"onCompleted",@"onError",@"onReceiveMemoryWarning",@"onRefresh",
        @"onStart",@"onSystemNotificationCountChanged",@"onTap",@"onTextChanged",@"onTimer",
        @"onTouchDown",@"onTouchUpInside",@"onTouchUpOutside",@"didChangeHeight",@"didFinishLoad",
        @"dismissAction",@"dismissAnimation",@"display",@"displayView",@"doneEvent",@"downloadWithURL",
        @"drawBackground",@"editAction",@"endEditing",@"endRefresh",@"enterbackground",@"errorWithCode",
        @"exitAction",@"fadeOutWithDuration",@"failButton",@"fetchData",@"fileSize",
        @"finishWithCompletionHandler",@"finishedPlaying",@"firstTimeInterval",@"focusGesture",
        @"footerRefresh",@"gestureRecognizer",@"getCurrentLocationWithCompletion",@"getCurrentTimestamp",
        @"getCurrentTopVC",@"getFileName",@"getFirstFrameFromVideoURL",@"getToken",@"getVersion",
        @"getView",@"handleLongPress",@"handleOpenUniversalLink",@"handlePanGesture",
        @"handleResponse",@"handleSwipeGesture",@"handleTap",@"handleTapGesture",
        @"handleTextFieldCharLength",@"headerRefresh",@"headerRereshing",
        @"heightForPinSectionHeaderInPagerView",@"hiddenBackgroundImageView",@"hidePopup",
        @"hideSwipeAnimated",@"hideToolbarViewWithKeyboardUserInfo",@"imageFromPixelBuffer",@"imageView",
        @"imageWithName",@"indexOfAccessibilityElement",@"indicatorView",@"infoLabel",@"initWith",
        @"initWithBlock",@"initWithButtons",@"initWithCallback",@"initWithConfig",
        @"initWithDataProvider",@"initWithDelegate",@"initWithDevice",@"initWithImage",@"initWithItems",
        @"initWithName",@"initWithParams",@"initWithQuality",@"initWithSignature",@"initWithSource",
        @"initWithTarget",@"initWithText",@"initWithTitle",@"initWithType",@"initWithURL",@"initWithUrl",
        @"initWithView",@"initialiseControl",@"inputbar_clearQuote",@"insertMessage",@"insertMessages",
        @"instance",@"acceptEvent",@"addGesture",@"addItem",@"addObserver",
        @"addTapGesture",@"addTapGestureRecognizerWithTaps",@"addTapWithTarget",@"addToView",@"adjustContentEdge",
        @"adjustOffset",@"adjustTableView",@"alertView",@"alertWithTitle",
        @"allowsKeyboardDismissOnTap",@"animateWithDuration",@"animationDuration",
        @"appDidEnterBackground",@"appWillEnterForeground",@"appWillResignActive",
        @"appDidBecomeActive",@"attachmentForException",@"authorizeWithType",@"authorized",
        @"backgroundColorForSwipe",@"beginEdit",@"buttonWithTitle",@"cancelAction",@"cancelButton",
        @"cancelEditMode",@"cellWithReuseIdentifier",@"checkData",@"cleanUp",@"cleanup",@"clearAll",
        @"clearCache",@"clearHistory",@"clickAction",@"closeAction",@"closeButton",@"closeKeyboard",
        @"colorWithHex",@"colorWithHexString",@"commonInit",@"configure",@"configureUI",
        @"containsChinese",@"containsEmoticon",@"containsURLKeyword",@"contentView",@"contentOffsetIsValid",
        @"copyAction",@"copyText",@"createImageWithColor",@"createUI",@"currentTimeStamp",
        @"currentTopViewController",@"currentViewControllerWithRootViewController",@"customizeInterface",
        @"dateChanged",@"decodeBase64Data",@"decodeBase64String",@"decodeData",@"decodeString",
        @"defaultConfig",@"defaultSetting",@"delayAction",@"dismissViewControllerAnimated",
        @"URLSession",@"addEntriesFromDictionary",@"addGestureRecognizer",@"addNotificationObserver",
        @"addTarget",@"allKeysForObject",@"authorizeWithCompletion",@"beginEditing",
        @"cancelAllOperations",@"presentViewController",@"setAnimationDuration",@"setContentSize",@"setImage",
        @"setText",@"base64EncodedString",@"encodeWithCoder",@"colorSpaceModel",@"numberOfPages",
        @"stringWithString",@"didMoveToWindow",@"forwardInvocation",@"stringByAppendingPathScale",
        @"containsString",@"setBadgeValue",@"numberOfSectionsInTableView",
        @"textFieldShouldReturn",@"willMoveToParentViewController",@"imagePickerControllerDidCancel",@"setAttributedText",
        @"returnKeyType",@"didMoveToSuperview",@"viewControllers",@"setContentInset",
        @"setSelectedRange",@"didReceiveMemoryWarning",@"viewDidAppear",
        @"applicationDidEnterBackground",@"collectionViewContentSize",@"intrinsicContentSize",@"navigationController",
        @"textDidChange",@"textViewShouldEndEditing",@"textViewShouldReturn",@"shouldAutorotate",
        @"preferredStatusBarStyle",@"clearsOnInsertion",@"authorizationStatus",@"mutableCopyWithZone",
        @"setContentOffset",@"removeAllAnimations",@"backgroundColor",@"viewWillDisappear",
        @"viewDidDisappear",@"allocWithZone",@"setTextAlignment",@"continueUserActivity",
        @"initWithError",@"initWithSession",@"audioPlayerDidFinishPlaying",@"textViewShouldBeginEditing",
        @"initWithLabel",@"initWithGroup",@"initWithDictionary",@"initWithCenter",@"initWithUserID",
        @"collectionView",@"setSelectedIndex",@"setAllowsEditingTextAttributes",
        @"scrollViewDidScroll",@"registerDeviceToken",@"captureOutput",@"placeholderAttributedText",@"isFirstResponder",
        @"loadHTMLString",@"shareInstance",@"textViewDidEndEditing",@"textViewDidBeginEditing",
        @"initWithStyle",@"prepareForReuse",@"selectedRange",@"sharedInstance",@"setDataSource",
        @"viewWillAppear",@"updateContentOffset",@"updateForBounds",@"updatePlaceholder",@"updateProgress",
        @"updateState",@"updateText",@"updateUserInfo",@"useProxy",@"userName",@"authorizationController",
        @"videoConnection",
        @"videoOutput",
        @"webView",
        @"willMoveToSuperview",
        @"willResignActive",
        @"tintColorDidChange",
        @"titleRectForContentRect",
        @"topViewController",
        @"trackRectForBounds",
        @"subarrayWithRange",
        @"supportedInterfaceOrientations",
        @"suspend",
        @"switchCamera",
        @"tableView",
        @"textFieldDidBeginEditing",
        @"textFieldDidEndEditing",
        @"textFieldShouldBeginEditing",
        @"textViewDidChangeSelection",
        @"thumbnailImageForVideo",
        @"sizeThatFits",
        @"sortUsingComparator",
        @"sortUsingFunction",
        @"sortUsingSelector",
        @"sortWithOptions",
        @"sortedArrayHint",
        @"sortedArrayUsingComparator",
        @"sortedArrayUsingFunction",
        @"sortedArrayUsingSelector",
        @"sortedArrayWithOptions",
        @"shouldChangeTextInRange",
        @"shouldInteractWithTextAttachment",
        @"shouldInteractWithURL",
        @"scrollViewDidEndDecelerating",
        @"scrollViewDidEndDragging",
        @"scrollViewDidScrollToTop",
        @"selector",
        @"reverseObjectEnumerator",
        @"scrollRangeToVisible",
        @"scrollView",
        @"removeAllObjects",
        @"removeLastObject",
        @"removeObject",
        @"removeObjectAtIndex",
        @"removeObjectForKey",
        @"removeObjectIdenticalTo",
        @"removeObjectsAtIndexes",
        @"removeObjectsForKeys",
        @"removeObjectsInArray",
        @"removeObjectsInRange",
        @"replaceObjectAtIndex",
        @"replaceObjectsAtIndexes",
        @"replaceObjectsInRange",
        @"presentationAnchorForAuthorizationController",
        @"realloc",
        @"passwordDataForService",
        @"passwordForService",
        @"passwordObject",
        @"peripheralManagerDidUpdateState",
        @"pointInside",
        @"preferredInterfaceOrientationForPresentation",
        @"prefersHomeIndicatorAutoHidden",
        @"prepareForInterfaceBuilder",
        @"prepareForSegue",
        @"objectAtIndex",
        @"objectAtIndexedSubscript",
        @"objectEnumerator",
        @"objectForKey",
        @"objectForKeyedSubscript",
        @"objectsAtIndexes",
        @"objectsForKeys",
        @"mutableCopy",
        @"localizedStringForKey",
        @"makeObjectsPerformSelector",
        @"inputAccessoryView",
        @"inputView",
        @"insertObject",
        @"insertObjects",
        @"insertText",
        @"isAccessibilityElement",
        @"isEqual",
        @"isEqualToArray",
        @"isEqualToDictionary",
        @"keyEnumerator",
        @"keyWindow",
        @"keysOfEntriesPassingTest",
        @"keysOfEntriesWithOptions",
        @"keysSortedByValueUsingComparator",
        @"keysSortedByValueUsingSelector",
        @"keysSortedByValueWithOptions",
        @"lastObject",
        @"layerClass",
        @"indexOfObject",
        @"indexOfObjectAtIndexes",
        @"indexOfObjectIdenticalTo",
        @"indexOfObjectPassingTest",
        @"indexOfObjectWithOptions",
        @"indexesOfObjectsAtIndexes",
        @"indexesOfObjectsPassingTest",
        @"indexesOfObjectsWithOptions",
        @"initWithArray",
        @"initWithCapacity",
        @"initWithCoder",
        @"initWithContentURL",
        @"initWithContentsOfFile",
        @"initWithContentsOfURL",
        @"initWithObjects",
        @"initWithReuseIdentifier",
        @"hitTest",
        @"gestureRecognizerShouldBegin",
        @"firstObject",
        @"firstObjectCommonWithArray",
        @"forwardingTargetForSelector",
        @"getObjects",
        @"duration",
        @"endTrackingWithTouch",
        @"enableInputClicksWhenVisible",
        @"enumerateKeysAndObjectsUsingBlock",
        @"enumerateKeysAndObjectsWithOptions",
        @"enumerateObjectsAtIndexes",
        @"enumerateObjectsUsingBlock",
        @"enumerateObjectsWithOptions",
        @"description",
        @"descriptionInStringsFileFormat",
        @"descriptionWithLocale",
        @"containsObject",
        @"contentSize",
        @"continueTrackingWithTouch",
        @"countByEnumeratingWithState",
        @"currentCalendar",
        @"currentPlaybackTime",
        @"copyWithZone",
        @"arrayByAddingObject",
        @"arrayByAddingObjectsFromArray",
        @"base64String",
        @"becomeFirstResponder",
        @"beginTrackingWithTouch",
        @"canBecomeFirstResponder",
        @"canPerformAction",
        @"canResignFirstResponder",
        @"cancelTrackingWithEvent",
        @"canonicalRequestForRequest",
        @"centralManagerDidUpdateState",
        @"childViewControllerForStatusBarHidden",
        @"childViewControllerForStatusBarStyle",
        @"accessibilityDecrement",
        @"accessibilityElementAtIndex",
        @"accessibilityElementCount",
        @"accessibilityIncrement",
        @"accessibilityType",
        @"accessibleElements",
        @"addObject",
        @"addObjectsFromArray",
        @"allKeys",
        @"allValues",
        @"application",
        @"applicationDidBecomeActive",
        @"applicationWillResignActive",
        @"addAction",
        @"touchesBegan",
        @"touchesEnded",
        @"touchesMoved",
        @"textView",
        @"textLabel",
        @"respondsToSelector",
        @"setValue",
        @"drawRect",
        @"awakeFromNib",
        @"deinit",
        @"init",
        @"layoutAttributesForElementsInRect",
        @"prepareLayout",
        @"methodSignatureForSelector",
        @"handleOpenURL",
        @"userContentController",
        @"drawTextInRect",
        @"actionWithTitle",
        @"positionFromPosition",
        @"markedTextRange",
        @"linkTextAttributes",
        @"unsignedIntegerValue",
        @"unsignedLongValue",
        @"unsignedIntValue",
        @"unsignedShortValue",
        @"unsignedCharValue",
        @"textRectForBounds",
        @"textViewDidChange",
        @"unsignedLongLongValue",
        @"numberOfSections",
        @"backgroundView",
        @"tabBarController",
        @"textDidChangeNotification",
        @"textContainer",
        @"itemWithTitle",
        @"initWithFrame",
        @"cornerRadius",
        @"layoutSubviews",
        @"pointInside:withEvent:",
        @"traitCollectionDidChange:",
        @"drawRect:",
        @"rootViewController",
        @"viewDidLoad",
        @"viewWillLayoutSubviews",
        @"viewDidLayoutSubviews",
        @"dealloc",
        @"prefersStatusBarHidden",
        @"tableView:numberOfRowsInSection:",
        @"tableView:cellForRowAtIndexPath:",
        @"tableView:heightForRowAtIndexPath:",
        @"tableView:didSelectRowAtIndexPath:",
        @"collectionView:numberOfItemsInSection:",
        @"collectionView:cellForItemAtIndexPath:",
        @"collectionView:layout:sizeForItemAtIndexPath:",
        @"gestureRecognizerShouldBegin:",
        @"textFieldShouldReturn:",
        @"dismiss",
        @"application:openURL:options:",
        @"application:continueUserActivity:restorationHandler:",
        @"componentsSeparatedByString:",
        @"stringByTrimmingCharactersInSet:",
        @"rangeOfString:",
        @"substringFromIndex:",
        @"observeValueForKeyPath:ofObject:change:context:",
        @"userInfo",
        @"systemVersion",
        @"deviceModel",
        @"deviceName",
        @"text",
        @"attributedText",
        @"font",
        @"textColor",
        @"textAlignment",
        @"editable",
        @"selectable",
        @"textViewShouldBeginEditing:",
        @"textViewDidBeginEditing:",
        @"textViewShouldEndEditing:",
        @"textViewDidEndEditing:",
        @"textView:shouldChangeTextInRange:replacementText:",
        @"textViewDidChange:",
        @"textViewDidChangeSelection:",
        @"textView:shouldInteractWithURL:inRange:interaction:",
        @"textView:shouldInteractWithTextAttachment:inRange:interaction:",
        @"scrollRangeToVisible:",
        @"textContainerInset",
        @"dataDetectorTypes",
        @"allowsEditingTextAttributes",
        @"resignFirstResponder",
        
        
        
        //三方
        @"tapAction",
        @"getInstallParams",
        @"listView",
        @"longFormHeight",
        @"showDragIndicator",
        @"allowsDragToDismiss",
        @"allowsPullDownWhenShortState",
        @"allowsTouchEventsPassingThroughTransitionView",
        @"keyboardOffsetFromInputView",
        @"startAnimation",
        @"uuidString",
        @"fd_willAppearInjectBlock",
        @"fd_popGestureRecognizerDelegate",
        @"fd_fullscreenPopGestureRecognizer",
        @"fd_interactivePopMaxAllowedInitialDistanceToLeftEdge",
        @"fd_viewControllerBasedNavigationBarAppearanceEnabled",
        @"fd_prefersNavigationBarHidden",
        @"fd_interactivePopDisabled",
        @"modelCustomPropertyMapper",
        @"modelContainerPropertyGenericClass",
        @"backgroundConfig",
        @"allowScreenEdgeInteractive",
        @"imageObj",
        @"animate",
        @"enlargedEdgeInsets",
        @"ltype_image",
        @"canvasSize",
        @"parameters",
    ];
}





@end
