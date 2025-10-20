//
//  BFConfuseMethod.m
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/2.
//

#import "BFConfuseMethod.h"
#import "BFConfuseProperty.h"
#import "BFConfuseManager.h"
#import "BFWordsRackTool.h"
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

+ (NSDictionary *)mapMethodDict103{
    return [self parseModuleMappingJSON:@"method_yueyi 3"];
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









+ (void)detectMultipleSettersInProject:(NSString *)projectPath
                         propertyNames:(NSArray *)propertyNames
                        excludeFolders:(NSArray *)excludeFolders {
    
    
    for (NSString *propertyName in propertyNames) {
        [self detectSetterMethodInProject:projectPath
                             propertyName:propertyName
                           excludeFolders:excludeFolders];
    }
    NSLog(@"-------------------------结束-------------------------");
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

+ (void)detectSetterMethodInProject:(NSString *)projectPath
                       propertyName:(NSString *)propertyName
                     excludeFolders:(NSArray *)excludeFolders {
    
    NSString *capitalizedPropertyName = [propertyName stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                                              withString:[[propertyName substringToIndex:1] uppercaseString]];
    NSString *setterName = [NSString stringWithFormat:@"set%@:", capitalizedPropertyName];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:projectPath];
    
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
            if (setterName && [fileContent containsString:setterName]) {
                NSLog(@"✅ 在文件中找到: %@", filePath);
                NSLog(@"📄 上下文:\n%@", propertyName);
            }
        }
    }
}

+ (void)detectSetterMethodInProject:(NSString *)projectPath
                       propertyName:(NSString *)propertyName {
    
    // 使用默认白名单
    [self detectSetterMethodInProject:projectPath
                         propertyName:propertyName
                       excludeFolders:[self defaultExcludeFolders]];
}

+ (BOOL)shouldExcludePath:(NSString *)filePath excludeFolders:(NSArray *)excludeFolders {
    for (NSString *folder in excludeFolders) {
        if ([filePath containsString:folder]) {
            return YES;
        }
    }
    return NO;
}








//插入随机方法
+ (void)injectRandomCodeToExistingMethodsInPath:(NSString *)path {
    NSArray *mFiles = [self findAllMFilesInDirectory:path];
    
    for (NSString *filePath in mFiles) {
        [self injectRandomCodeToFile:filePath];
    }
}

+ (void)injectRandomCodeToFile:(NSString *)filePath {
    NSString *content = [NSString stringWithContentsOfFile:filePath
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil];
    if (!content) {
        NSLog(@"❌ 无法读取文件: %@", filePath);
        return;
    }
    
    if ([self shouldSkipFile:content filePath:filePath]) {
        NSLog(@"⏭️ 跳过文件: %@", [filePath lastPathComponent]);
        return;
    }
    
    NSMutableString *mutableContent = [content mutableCopy];
    NSUInteger injectionCount = 0;
    
    NSLog(@"🔍 开始处理文件: %@", [filePath lastPathComponent]);
    
    // 在现有方法中插入随机代码
    injectionCount = [self injectRandomCodeIntoMethodsInContent:mutableContent];
    
    if (injectionCount > 0) {
        NSError *writeError = nil;
        BOOL success = [mutableContent writeToFile:filePath
                                        atomically:YES
                                          encoding:NSUTF8StringEncoding
                                             error:&writeError];
        
        if (success) {
            NSLog(@"✅ 成功向 %@ 的 %lu 个方法中插入随机代码", [filePath lastPathComponent], (unsigned long)injectionCount);
        } else {
            NSLog(@"❌ 写入失败: %@", writeError);
        }
    } else {
        NSLog(@"⏭️ 未在 %@ 中插入任何代码", [filePath lastPathComponent]);
    }
}

#pragma mark - 核心逻辑：在方法中插入随机代码

+ (NSUInteger)injectRandomCodeIntoMethodsInContent:(NSMutableString *)content {
    NSUInteger injectionCount = 0;
    NSUInteger position = 0;
    
    while (position < content.length) {
        // 查找方法开始
        NSRange methodRange = [self findNextMethodInContent:content startPosition:position];
        if (methodRange.location == NSNotFound) {
            break;
        }
        
        // 随机决定是否在这个方法中插入代码（60%概率）
        if (arc4random_uniform(100) < 80) {
            if ([self injectRandomCodeInMethodRange:methodRange content:content]) {
                injectionCount++;
            }
        }
        
        position = methodRange.location + methodRange.length;
    }
    
    return injectionCount;
}

+ (NSRange)findNextMethodInContent:(NSString *)content startPosition:(NSUInteger)startPosition {
    // 查找方法开始标记
    NSRange searchRange = NSMakeRange(startPosition, content.length - startPosition);
    
    // 查找实例方法或类方法
    NSRange instanceMethodRange = [content rangeOfString:@"\n-" options:0 range:searchRange];
    NSRange classMethodRange = [content rangeOfString:@"\n+" options:0 range:searchRange];
    
    NSRange methodStartRange;
    if (instanceMethodRange.location != NSNotFound && classMethodRange.location != NSNotFound) {
        methodStartRange = (instanceMethodRange.location < classMethodRange.location) ? instanceMethodRange : classMethodRange;
    } else if (instanceMethodRange.location != NSNotFound) {
        methodStartRange = instanceMethodRange;
    } else if (classMethodRange.location != NSNotFound) {
        methodStartRange = classMethodRange;
    } else {
        return NSMakeRange(NSNotFound, 0);
    }
    
    // 找到方法体开始 {
    NSRange braceSearchRange = NSMakeRange(methodStartRange.location, content.length - methodStartRange.location);
    NSRange openBraceRange = [content rangeOfString:@"{" options:0 range:braceSearchRange];
    
    if (openBraceRange.location == NSNotFound) {
        return NSMakeRange(NSNotFound, 0);
    }
    
    // 找到方法体结束 }
    NSRange closeBraceRange = [self findMatchingCloseBraceInContent:content startPosition:openBraceRange.location];
    
    if (closeBraceRange.location == NSNotFound) {
        return NSMakeRange(NSNotFound, 0);
    }
    
    // 返回完整的方法范围
    return NSMakeRange(methodStartRange.location, closeBraceRange.location + closeBraceRange.length - methodStartRange.location);
}

+ (NSRange)findMatchingCloseBraceInContent:(NSString *)content startPosition:(NSUInteger)startPosition {
    NSInteger braceCount = 1; // 从 { 开始计数
    NSUInteger position = startPosition + 1;
    
    while (position < content.length && braceCount > 0) {
        unichar ch = [content characterAtIndex:position];
        
        if (ch == '{') {
            braceCount++;
        } else if (ch == '}') {
            braceCount--;
            if (braceCount == 0) {
                return NSMakeRange(position, 1);
            }
        }
        
        position++;
    }
    
    return NSMakeRange(NSNotFound, 0);
}

+ (BOOL)injectRandomCodeInMethodRange:(NSRange)methodRange content:(NSMutableString *)content {
    @try {
        // 提取方法内容
        NSString *methodContent = [content substringWithRange:methodRange];
        
        // 检查方法中是否包含 switch 语句，如果有则跳过
        if ([self methodContainsSwitchStatement:methodContent]) {
            NSLog(@"⏭️ 跳过包含 switch 语句的方法");
            return NO;
        }
        
        // 找到所有有效的插入位置（分号位置）
        NSArray *insertionPoints = [self findValidInsertionPointsInMethodContent:methodContent];
        
        if (insertionPoints.count == 0) {
            return NO;
        }
        
        // 随机选择一个插入位置
        NSUInteger randomIndex = arc4random_uniform((uint32_t)insertionPoints.count);
        NSDictionary *insertionPoint = insertionPoints[randomIndex];
        
        NSUInteger localSemicolonPosition = [insertionPoint[@"position"] unsignedIntegerValue];
        NSString *indent = insertionPoint[@"indent"];
        
        // 生成随机代码
        NSString *randomCode = [self generateRandomCodeWithIndent:indent];
        
        // 计算在原始内容中的实际位置
        NSUInteger actualPosition = methodRange.location + localSemicolonPosition + 1; // +1 表示在分号之后
        
        // 验证插入位置是否正确（前一个字符应该是分号）
        if (actualPosition > 0 && actualPosition <= content.length) {
            unichar previousChar = [content characterAtIndex:actualPosition - 1];
            if (previousChar != ';') {
                NSLog(@"❌ 插入位置错误：前一个字符不是分号，而是 '%c'", previousChar);
                return NO;
            }
        }
        
        // 插入随机代码
        [content insertString:randomCode atIndex:actualPosition];
        
        NSLog(@"📝 在方法中插入随机代码: %@", [randomCode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]);
        
        return YES;
        
    } @catch (NSException *exception) {
        NSLog(@"❌ 插入随机代码失败: %@", exception);
        return NO;
    }
}

+ (NSArray *)findValidInsertionPointsInMethodContent:(NSString *)methodContent {
    NSMutableArray *insertionPoints = [NSMutableArray array];
    
    // 找到方法体的开始和结束位置
    NSRange openBraceRange = [methodContent rangeOfString:@"{"];
    NSRange closeBraceRange = [methodContent rangeOfString:@"}" options:NSBackwardsSearch];
    
    if (openBraceRange.location == NSNotFound || closeBraceRange.location == NSNotFound) {
        return insertionPoints;
    }
    
    // 计算方法体的实际范围
    NSUInteger bodyStart = openBraceRange.location + 1;
    NSUInteger bodyEnd = closeBraceRange.location;
    
    if (bodyStart >= bodyEnd) {
        return insertionPoints;
    }
    
    // 提取方法体
    NSString *methodBody = [methodContent substringWithRange:NSMakeRange(bodyStart, bodyEnd - bodyStart)];
    
    // 使用更精确的方法找到所有分号位置
    NSUInteger position = 0;
    while (position < methodBody.length) {
        // 找到下一个分号
        NSRange semicolonRange = [methodBody rangeOfString:@";" options:0 range:NSMakeRange(position, methodBody.length - position)];
        if (semicolonRange.location == NSNotFound) {
            break;
        }
        
        // 检查这个分号是否在有效的位置
        if ([self isValidSemicolonPosition:semicolonRange.location inMethodBody:methodBody]) {
            // 获取当前行的缩进
            NSString *indent = [self getIndentAtPosition:semicolonRange.location inMethodBody:methodBody];
            
            [insertionPoints addObject:@{
                @"position": @(bodyStart + semicolonRange.location),
                @"indent": indent ?: @""
            }];
        }
        
        position = semicolonRange.location + semicolonRange.length;
    }
    
    return insertionPoints;
}

+ (BOOL)isValidSemicolonPosition:(NSUInteger)position inMethodBody:(NSString *)methodBody {
    // 提取分号所在的行
    NSString *line = [self getLineContainingPosition:position inString:methodBody];
    NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // 跳过注释
    if ([trimmedLine hasPrefix:@"//"] ||
        [trimmedLine hasPrefix:@"/*"] ||
        [trimmedLine hasPrefix:@"*"] ||
        [trimmedLine hasSuffix:@"*/"]) {
        return NO;
    }
    
    // 跳过控制流语句
    NSArray *controlFlowKeywords = @[
        @"if", @"else", @"for", @"while", @"do", @"switch",
        @"case", @"default", @"return", @"break", @"continue",
        @"goto"
    ];
    
    for (NSString *keyword in controlFlowKeywords) {
        if ([trimmedLine hasPrefix:keyword] || [trimmedLine containsString:[NSString stringWithFormat:@" %@", keyword]]) {
            return NO;
        }
    }
    
    // 跳过包含 @ 或 # 的行
    if ([trimmedLine hasPrefix:@"@"] || [trimmedLine hasPrefix:@"#"]) {
        return NO;
    }
    
    // 检查括号平衡
    NSString *textBeforeSemicolon = [methodBody substringToIndex:position];
    if (![self isTextBalanced:textBeforeSemicolon]) {
        return NO;
    }
    
    return YES;
}

+ (NSString *)getLineContainingPosition:(NSUInteger)position inString:(NSString *)string {
    // 找到行的开始
    NSUInteger lineStart = position;
    while (lineStart > 0) {
        unichar ch = [string characterAtIndex:lineStart - 1];
        if (ch == '\n') {
            break;
        }
        lineStart--;
    }
    
    // 找到行的结束
    NSUInteger lineEnd = position;
    while (lineEnd < string.length) {
        unichar ch = [string characterAtIndex:lineEnd];
        if (ch == '\n') {
            break;
        }
        lineEnd++;
    }
    
    if (lineStart <= lineEnd && lineEnd <= string.length) {
        return [string substringWithRange:NSMakeRange(lineStart, lineEnd - lineStart)];
    }
    
    return @"";
}

+ (NSString *)getIndentAtPosition:(NSUInteger)position inMethodBody:(NSString *)methodBody {
    NSString *line = [self getLineContainingPosition:position inString:methodBody];
    
    NSUInteger indentLength = 0;
    for (NSUInteger i = 0; i < line.length; i++) {
        unichar ch = [line characterAtIndex:i];
        if (ch == ' ' || ch == '\t') {
            indentLength++;
        } else {
            break;
        }
    }
    
    if (indentLength > 0 && indentLength <= line.length) {
        return [line substringToIndex:indentLength];
    }
    
    return @"";
}

+ (BOOL)isTextBalanced:(NSString *)text {
    // 简单的括号平衡检查
    NSInteger parenCount = 0;
    NSInteger bracketCount = 0;
    NSInteger braceCount = 0;
    
    for (NSUInteger i = 0; i < text.length; i++) {
        unichar ch = [text characterAtIndex:i];
        
        if (ch == '(') parenCount++;
        else if (ch == ')') parenCount--;
        else if (ch == '[') bracketCount++;
        else if (ch == ']') bracketCount--;
        else if (ch == '{') braceCount++;
        else if (ch == '}') braceCount--;
        
        // 如果括号计数出现负数，说明不平衡
        if (parenCount < 0 || bracketCount < 0 || braceCount < 0) {
            return NO;
        }
    }
    
    // 最终检查所有括号是否平衡
    return (parenCount == 0 && bracketCount == 0 && braceCount == 0);
}

+ (BOOL)methodContainsSwitchStatement:(NSString *)methodContent {
    // 检查方法内容中是否包含 switch 语句
    // 使用简单的字符串匹配，注意避免匹配到注释中的 switch
    NSArray *lines = [methodContent componentsSeparatedByString:@"\n"];
    
    for (NSString *line in lines) {
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // 跳过注释行
        if ([trimmedLine hasPrefix:@"//"] || [trimmedLine hasPrefix:@"/*"] || [trimmedLine hasPrefix:@"*"]) {
            continue;
        }
        
        // 检查是否包含 switch 关键字
        if ([trimmedLine containsString:@"switch"] && ![trimmedLine containsString:@"//"]) {
            return YES;
        }
    }
    
    return NO;
}



#pragma mark - 随机代码生成器（随机变量名）

+ (NSString *)generateRandomCodeWithIndent:(NSString *)indent {
    // 随机选择代码类型
    NSUInteger codeType = arc4random_uniform(8);
    
    switch (codeType) {
        case 0:
            return [self generateVariableOperationsWithIndent:indent];
        case 1:
            return [self generateControlFlowWithIndent:indent];
        case 2:
            return [self generateDataStructuresWithIndent:indent];
        case 3:
            return [self generateObjectOperationsWithIndent:indent];
        case 4:
            return [self generateStringOperationsWithIndent:indent];
        case 5:
            return [self generateMathematicalOperationsWithIndent:indent];
        case 6:
            return [self generateAsyncOperationsWithIndent:indent];
        case 7:
            return [self generateUtilityOperationsWithIndent:indent];
        default:
            return [self generateVariableOperationsWithIndent:indent];
    }
}

#pragma mark - 随机变量名生成器

+ (NSString *)generateRandomVariableName {
    NSArray *prefixes = [BFWordsRackTool propertyNames];
    
    NSArray *suffixes = [BFWordsRackTool propertyNames];
    
    NSString *prefix = prefixes[arc4random_uniform((uint32_t)prefixes.count)];
    NSString *suffix = suffixes[arc4random_uniform((uint32_t)suffixes.count)];
    
    // 有时添加数字增加随机性
    if (arc4random_uniform(3) == 0) {
        NSUInteger randomNum = arc4random_uniform(10);
        return [NSString stringWithFormat:@"%@%@%lu", prefix, suffix, (unsigned long)randomNum];
    } else {
        return [NSString stringWithFormat:@"%@%@", prefix, suffix];
    }
}

+ (NSString *)generateRandomClassName {
    NSArray *classPrefixes = [BFWordsRackTool propertyNames];
    
    NSArray *classSuffixes = [BFWordsRackTool propertyNames];
    
    NSString *prefix = classPrefixes[arc4random_uniform((uint32_t)classPrefixes.count)];
    NSString *suffix = classSuffixes[arc4random_uniform((uint32_t)classSuffixes.count)];
    
    return [NSString stringWithFormat:@"%@%@", prefix, suffix];
}

#pragma mark - 各种代码生成方法（使用随机变量名）

+ (NSString *)generateVariableOperationsWithIndent:(NSString *)indent {
    NSString *var1 = [self generateRandomVariableName];
    NSString *var2 = [self generateRandomVariableName];
    NSString *var3 = [self generateRandomVariableName];
    NSString *var4 = [self generateRandomVariableName];
    NSString *var5 = [self generateRandomVariableName];
    NSString *var6 = [self generateRandomVariableName];
    NSArray *templates = @[
        // 模板 1: 基础变量操作
        [NSString stringWithFormat:@"CGFloat %@ = M_PI * 2.0;\nUIView *%@ = [[UIView alloc] init];\n%@.alpha = %@ / 10.0;",
         var1, var2, var2, var1],
        
        // 模板 2: 数学计算
        [NSString stringWithFormat:@"NSInteger %@ = 5;\nBOOL %@ = YES;\nCGFloat %@ = 1.5;\nCGRect %@ = CGRectMake(0, 0, 100 * %@, 50 * %@);",
         var3, var4, var5, var6, var5, var5],
        
        // 模板 3: 对象和协议
        [NSString stringWithFormat:@"id %@ = nil;\nClass %@ = [NSString class];\nSEL %@ = @selector(length);\nProtocol *%@ = @protocol(NSCopying);",
         var1, var2, var3, var4],
        
        // 模板 4: 尺寸计算
        [NSString stringWithFormat:@"NSUInteger %@ = 10;\nCGFloat %@ = 8.0;\nCGSize %@ = CGSizeMake(44.0, 44.0);\nCGFloat %@ = %@ * (%@.width + %@);",
         var1, var2, var3, var4, var1, var3, var2],
        
        // 模板 5: 颜色和视图
        [NSString stringWithFormat:@"UIColor *%@ = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];\nUIView *%@ = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];\n%@.backgroundColor = %@;\n%@.layer.cornerRadius = 5.0;",
         var1, var2, var2, var1, var2],
        
        // 模板 6: 数组和字典
        [NSString stringWithFormat:@"NSArray *%@ = @[@1, @2, @3];\nNSDictionary *%@ = @{@\"key\": @\"value\"};\nNSMutableArray *%@ = [%@ mutableCopy];\n[%@ addObject:@4];",
         var1, var2, var3, var1, var3],
        
        // 模板 7: 几何变换
        [NSString stringWithFormat:@"CGAffineTransform %@ = CGAffineTransformIdentity;\nCGAffineTransform %@ = CGAffineTransformMakeScale(1.5, 1.5);\nCGAffineTransform %@ = CGAffineTransformRotate(%@, M_PI_4);\nCGAffineTransform %@ = CGAffineTransformConcat(%@, %@);",
         var1, var2, var3, var2, var4, var1, var3],
        
        // 模板 8: 字符串操作
        [NSString stringWithFormat:@"NSString *%@ = @\"Hello\";\nNSString *%@ = @\"World\";\nNSString *%@ = [NSString stringWithFormat:@\"%%@ %%@\", %@, %@];\nNSInteger %@ = %@.length;",
         var1, var2, var3, var1, var2, var4, var3]
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateControlFlowWithIndent:(NSString *)indent {
    NSString *var1 = [self generateRandomVariableName];
    NSString *var2 = [self generateRandomVariableName];
    NSString *var3 = [self generateRandomVariableName];
    
    NSArray *templates = @[
        [NSString stringWithFormat:@"if (YES) {\n    CGFloat %@ = M_E * 2.0;\n    CGRect %@ = CGRectMake(0, 0, %@, %@);\n}", var1, var2, var1, var1],
        
        [NSString stringWithFormat:@"for (NSUInteger %@ = 0; %@ < 3; %@++) {\n    CGFloat %@ = (CGFloat)%@ / 3.0;\n    CGPoint %@ = CGPointMake(%@ * 100.0, %@ * 50.0);\n}",
         var1, var1, var1, var2, var1, var3, var2, var2],
        
        [NSString stringWithFormat:@"NSUInteger %@ = 0;\nwhile (%@ < 2) {\n    CGFloat %@ = (CGFloat)%@ * M_PI_4;\n    CGAffineTransform %@ = CGAffineTransformMakeRotation(%@);\n    %@++;\n}",
         var1, var1, var2, var1, var3, var2, var1],
        
        [NSString stringWithFormat:@"BOOL %@ = YES;\nBOOL %@ = NO;\nif (%@ && !%@) {\n    CGFloat %@ = 0.7;\n    UIColor *%@ = [UIColor colorWithWhite:%@ alpha:1.0];\n}",
         var1, var2, var1, var2, var3, [self generateRandomVariableName], var3]
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateDataStructuresWithIndent:(NSString *)indent {
    NSString *var1 = [self generateRandomVariableName];
    NSString *var2 = [self generateRandomVariableName];
    NSString *var3 = [self generateRandomVariableName];
    NSString *var4 = [self generateRandomVariableName];
    
    NSArray *templates = @[
        [NSString stringWithFormat:@"NSMutableArray *%@ = [NSMutableArray array];\n[%@ addObject:[NSValue valueWithCGRect:CGRectMake(0, 0, 50, 50)]];\n[%@ addObject:[NSValue valueWithCGPoint:CGPointMake(10, 10)]];\n[%@ addObject:[NSValue valueWithCGAffineTransform:CGAffineTransformIdentity]];",
         var1, var1, var1, var1],
        
        [NSString stringWithFormat:@"NSMutableDictionary *%@ = [NSMutableDictionary dictionary];\n%@[@\"scale\"] = @(1.5);\n%@[@\"duration\"] = @(0.3);\n%@[@\"opacity\"] = @(0.8);\nCGSize %@ = CGSizeMake(100 * [%@[@\"scale\"] floatValue], 100);",
         var1, var1, var1, var1, var2, var1],
        
        [NSString stringWithFormat:@"NSMutableSet *%@ = [NSMutableSet set];\n[%@ addObject:@(M_PI)];\n[%@ addObject:@(M_E)];\n[%@ addObject:@(M_LN2)];\nNSUInteger %@ = %@.count;",
         var1, var1, var1, var1, var2, var1],
        
        [NSString stringWithFormat:@"NSArray *%@ = @[@(3.14), @(2.71), @(1.41), @(1.61)];\nNSArray *%@ = [%@ sortedArrayUsingComparator:^NSComparisonResult(NSNumber *%@, NSNumber *%@) {\n    return [%@ compare:%@];\n}];\nCGFloat %@ = [%@.firstObject floatValue];",
         var1, var2, var1, var3, var4, var3, var4, [self generateRandomVariableName], var2]
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateObjectOperationsWithIndent:(NSString *)indent {
    NSString *var1 = [self generateRandomVariableName];
    NSString *var2 = [self generateRandomVariableName];
    NSString *var3 = [self generateRandomVariableName];
    NSString *var4 = [self generateRandomVariableName];
    
    NSArray *templates = @[
        [NSString stringWithFormat:@"UIView *%@ = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];\n%@.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];\n%@.layer.cornerRadius = 8.0;\n%@.layer.borderWidth = 1.0;\n%@.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;",
         var1, var1, var1, var1, var1],
        
        [NSString stringWithFormat:@"CGFloat %@ = 0.2;\nCGFloat %@ = 0.4;\nCGFloat %@ = 0.6;\nUIColor *%@ = [UIColor colorWithRed:%@ green:%@ blue:%@ alpha:1.0];\nCGColorRef %@ = %@.CGColor;",
         var1, var2, var3, var4, var1, var2, var3, [self generateRandomVariableName], var4],
        
        [NSString stringWithFormat:@"CGAffineTransform %@ = CGAffineTransformIdentity;\nCGAffineTransform %@ = CGAffineTransformScale(%@, 1.2, 0.8);\nCGAffineTransform %@ = CGAffineTransformRotate(%@, M_PI_4);\nCGAffineTransform %@ = CGAffineTransformTranslate(%@, 10, 5);",
         var1, var2, var1, var3, var2, var4, var3],
        
        [NSString stringWithFormat:@"CALayer *%@ = [CALayer layer];\n%@.frame = CGRectMake(0, 0, 100, 50);\n%@.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;\n%@.cornerRadius = 4.0;\n%@.shadowOpacity = 0.2;",
         var1, var1, var1, var1, var1]
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateStringOperationsWithIndent:(NSString *)indent {
    NSString *var1 = [self generateRandomVariableName];
    NSString *var2 = [self generateRandomVariableName];
    NSString *var3 = [self generateRandomVariableName];
    NSString *var4 = [self generateRandomVariableName];
    
    NSArray *templates = @[
        [NSString stringWithFormat:@"NSString *%@ = @\"Content\";\nNSString *%@ = @\"Data\";\nNSString *%@ = [%@ stringByAppendingString:%@];\nNSUInteger %@ = %@.length;\nNSRange %@ = NSMakeRange(0, %@);",
         var1, var2, var3, var1, var2, var4, var3, [self generateRandomVariableName], var4],
        
        [NSString stringWithFormat:@"NSString *%@ = @\"SampleText\";\nNSString *%@ = [%@ uppercaseString];\nNSString *%@ = [%@ lowercaseString];\nNSString *%@ = [%@ capitalizedString];\nNSComparisonResult %@ = [%@ compare:%@];",
         var1, var2, var1, var3, var1, var4, var1, [self generateRandomVariableName], var2, var3],
        
        [NSString stringWithFormat:@"NSString *%@ = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;\nNSString *%@ = [%@ stringByAppendingPathComponent:@\"data.file\"];\nNSString *%@ = [%@ pathExtension];\nNSString *%@ = [%@ lastPathComponent];\nNSString *%@ = [%@ stringByDeletingLastPathComponent];",
         var1, var2, var1, var3, var2, var4, var2, [self generateRandomVariableName], var2]
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateMathematicalOperationsWithIndent:(NSString *)indent {
    NSString *var1 = [self generateRandomVariableName];
    NSString *var2 = [self generateRandomVariableName];
    NSString *var3 = [self generateRandomVariableName];
    NSString *var4 = [self generateRandomVariableName];
    
    NSArray *templates = @[
        [NSString stringWithFormat:@"CGRect %@ = CGRectMake(0, 0, 200, 100);\nCGRect %@ = CGRectInset(%@, 10, 5);\nCGRect %@ = CGRectOffset(%@, 5, 2);\nCGRect %@ = CGRectUnion(%@, %@);\nCGRect %@ = CGRectIntersection(%@, %@);",
         var1, var2, var1, var3, var2, var4, var1, var3, [self generateRandomVariableName], var1, var3],
        
        [NSString stringWithFormat:@"CGFloat %@ = M_PI;\nCGFloat %@ = %@ * %@;\nCGFloat %@ = sqrt(%@);\nCGFloat %@ = cos(%@);\nCGFloat %@ = sin(%@);\nCGFloat %@ = tan(%@);",
         var1, var2, var1, var1, var3, var2, var4, var1, [self generateRandomVariableName], var1, [self generateRandomVariableName], var1],
        
        [NSString stringWithFormat:@"CGPoint %@ = CGPointMake(0, 0);\nCGPoint %@ = CGPointMake(100, 50);\nCGFloat %@ = hypot(%@.x - %@.x, %@.y - %@.y);\nCGPoint %@ = CGPointMake((%@.x + %@.x) / 2, (%@.y + %@.y) / 2);\nCGVector %@ = CGVectorMake(%@.x - %@.x, %@.y - %@.y);",
         var1, var2, var3, var2, var1, var2, var1, var4, var1, var2, var1, var2, [self generateRandomVariableName], var2, var1, var2, var1]
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateAsyncOperationsWithIndent:(NSString *)indent {
    NSString *var1 = [self generateRandomVariableName];
    NSString *var2 = [self generateRandomVariableName];
    NSString *var3 = [self generateRandomVariableName];
    NSString *var4 = [self generateRandomVariableName];
    
    NSArray *templates = @[
        [NSString stringWithFormat:@"dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{\n    CGRect %@ = CGRectMake(0, 0, 100, 50);\n    CGAffineTransform %@ = CGAffineTransformIdentity;\n    dispatch_async(dispatch_get_main_queue(), ^{\n        CGRect %@ = %@;\n        CGAffineTransform %@ = %@;\n    });\n});",
         var1, var2, var3, var1, var4, var2],
        
        [NSString stringWithFormat:@"dispatch_group_t %@ = dispatch_group_create();\ndispatch_group_enter(%@);\nCGFloat %@ = M_PI;\ndispatch_group_leave(%@);\ndispatch_group_notify(%@, dispatch_get_main_queue(), ^{\n    CGFloat %@ = %@;\n});",
         var1, var1, var2, var1, var1, var3, var2],
        
        [NSString stringWithFormat:@"static dispatch_once_t %@;\ndispatch_once(&%@, ^{\n    CGFloat %@ = M_E;\n    CGRect %@ = CGRectMake(0, 0, %@ * 50, %@ * 25);\n});",
         var1, var1, var2, var3, var2, var2],
        
        [NSString stringWithFormat:@"dispatch_queue_t %@ = dispatch_queue_create(\"custom.queue\", DISPATCH_QUEUE_CONCURRENT);\ndispatch_async(%@, ^{\n    CGFloat %@ = 3.14;\n});\ndispatch_barrier_async(%@, ^{\n    CGFloat %@ = 2.71;\n});",
         var1, var1, var2, var1, var3]
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateUtilityOperationsWithIndent:(NSString *)indent {
    NSString *var1 = [self generateRandomVariableName];
    NSString *var2 = [self generateRandomVariableName];
    NSString *var3 = [self generateRandomVariableName];
    NSString *var4 = [self generateRandomVariableName];
    
    NSArray *templates = @[
        [NSString stringWithFormat:@"NSFileManager *%@ = [NSFileManager defaultManager];\nNSString *%@ = NSTemporaryDirectory();\nNSString *%@ = [%@ stringByAppendingPathComponent:@\"temp.data\"];\nBOOL %@ = [%@ fileExistsAtPath:%@];\nNSDictionary *%@ = %@ ? [%@ attributesOfItemAtPath:%@ error:NULL] : @{};",
         var1, var2, var3, var2, var4, var1, var3, [self generateRandomVariableName], var4, var1, var3],
        
        [NSString stringWithFormat:@"NSUserDefaults *%@ = [NSUserDefaults standardUserDefaults];\n[%@ setFloat:M_PI forKey:@\"saved_constant\"];\n[%@ setBool:YES forKey:@\"configuration_flag\"];\nCGFloat %@ = [%@ floatForKey:@\"saved_constant\"];\nBOOL %@ = [%@ boolForKey:@\"configuration_flag\"];",
         var1, var1, var1, var2, var1, var3, var1],
        
        [NSString stringWithFormat:@"NSBundle *%@ = [NSBundle mainBundle];\nNSString *%@ = %@.bundleIdentifier;\nNSDictionary *%@ = %@.infoDictionary;\nNSString *%@ = %@[@\"CFBundleShortVersionString\"];\nNSString *%@ = %@[(@\"CFBundleVersion\")];",
         var1, var2, var1, var3, var1, var4, var3, [self generateRandomVariableName], var3],
        
        [NSString stringWithFormat:@"NSProcessInfo *%@ = [NSProcessInfo processInfo];\nNSUInteger %@ = %@.processorCount;\nNSUInteger %@ = %@.activeProcessorCount;\nNSTimeInterval %@ = %@.systemUptime;\nNSString *%@ = %@.processName;",
         var1, var2, var1, var3, var1, var4, var1, [self generateRandomVariableName], var1]
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

#pragma mark - 辅助方法

+ (NSString *)applyIndent:(NSString *)indent toCode:(NSString *)code {
    // 按行分割代码
    NSArray *lines = [code componentsSeparatedByString:@"\n"];
    NSMutableArray *indentedLines = [NSMutableArray array];
    
    for (NSString *line in lines) {
        // 对每一行应用缩进
        NSString *indentedLine = [NSString stringWithFormat:@"%@%@", indent, line];
        [indentedLines addObject:indentedLine];
    }
    
    // 重新组合并确保以换行符结尾
    NSString *result = [indentedLines componentsJoinedByString:@"\n"];
    return [result stringByAppendingString:@"\n"];
}


#pragma mark - 文件处理辅助方法

+ (NSArray *)findAllMFilesInDirectory:(NSString *)directory {
    NSMutableArray *mFiles = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 检查目录是否存在
    BOOL isDirectory = NO;
    if (![fileManager fileExistsAtPath:directory isDirectory:&isDirectory] || !isDirectory) {
        NSLog(@"❌ 目录不存在或不是目录: %@", directory);
        return mFiles;
    }
    
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directory];
    NSString *file;
    
    while ((file = [enumerator nextObject])) {
        // 跳过 Pods 目录
        if ([file hasPrefix:@"Pods/"] || [file containsString:@"/Pods/"]) {
            [enumerator skipDescendants];
            continue;
        }
        
        // 跳过 .framework 目录
        if ([[file pathExtension] isEqualToString:@"framework"] ||
            [file containsString:@".framework/"]) {
            [enumerator skipDescendants];
            continue;
        }
        
        // 跳过其他需要排除的目录
        if ([self shouldSkipDirectory:file]) {
            [enumerator skipDescendants];
            continue;
        }
        
        // 只处理 .m 文件
        if ([[file pathExtension] isEqualToString:@"m"]) {
            NSString *fullPath = [directory stringByAppendingPathComponent:file];
            [mFiles addObject:fullPath];
        }
    }
    
    NSLog(@"📁 找到 %lu 个 .m 文件", (unsigned long)mFiles.count);
    return mFiles;
}

+ (BOOL)shouldSkipDirectory:(NSString *)filePath {
    NSArray *skipDirectories = @[
        @".git",
        @".bundle",
        @".xcassets",
        @".xcodeproj",
        @".xcworkspace",
        @"DerivedData",
        @"build",
        @"Carthage",
        @"vendor",
        @"node_modules",
        @".svn"
    ];
    
    for (NSString *directory in skipDirectories) {
        if ([filePath hasPrefix:[directory stringByAppendingString:@"/"]] ||
            [filePath isEqualToString:directory] ||
            [filePath containsString:[NSString stringWithFormat:@"/%@/", directory]]) {
            return YES;
        }
    }
    
    return NO;
}

+ (BOOL)shouldSkipFile:(NSString *)content filePath:(NSString *)filePath {
    // 基于文件路径的过滤
    NSArray *pathSkipKeywords = @[
        @"/Pods/",
        @".framework/",
        @"/DerivedData/",
        @"main.m"
    ];
    
    for (NSString *keyword in pathSkipKeywords) {
        if ([filePath containsString:keyword]) {
            return YES;
        }
    }
    
    // 基于文件内容的过滤
    NSArray *contentSkipKeywords = @[
        @"@implementation UI",
        @"@implementation NS",
        @"@implementation __",
        @"@implementation UIViewController",
        @"@implementation UITableView",
        @"@implementation UICollectionView",
        @"@implementation UINavigationController"
    ];
    
    for (NSString *keyword in contentSkipKeywords) {
        if ([content containsString:keyword]) {
            return YES;
        }
    }
    
    return NO;
}







+ (NSArray *)sysMethodList{
    return @[
        @"giftList",
        @"female",
        @"testLaunchPerformance",
        @"testLaunch",
        @"runsForEachTargetApplicationUIConfiguration",
        @"params",
        @"giftType",
        @"durationStr",
        @"cycleScrollView",
        @"toNumber",
        @"currentNumber",
        @"isMe",
        @"listContainerView",
        @"resources",
        @"ctx",
        @"margin",
        @"scrollViewTimingDelegate",
        @"parser",
        @"callMethod",
        @"preSendTime",
        @"maleClient",
        @"targetLang",
        @"giftNameL",
        @"transSizeHeight",
        @"pinSizeHeight",
        @"giftName",
        @"groupAni",
        @"isFollow",
        @"opuses",
        @"isRemoteRead",
        @"JSONData",
        @"JSONString",
        @"coverUrl",
        @"maxNum",
        @"extent",
        @"outputImage",
        @"channelType",
        @"onNetworkQuality",
        @"onNERtcEngineUserVideoDidStartWithUserID",
        @"onNERtcEngineUserDidLeaveWithUserID",
        @"onNERtcEngineUserDidJoinWithUserID",
        @"onNERtcEngineUserAudioDidStart",
        @"onNERtcEngineUserVideoDidStop",
        @"onNERtcEngineUserAudioDidStop",
        @"nimSignalingOfflineNotify",
        @"nimSignalingMultiClientSyncNotifyEventType",
        @"nimSignalingOnlineNotifyEventType",
        @"removeDelegates",
        @"cantonese",
        @"mandarin",
        @"friendCount",
        @"followCount",
        @"fansCount",
        @"countDown",
        @"countUp",
        @"onTapCamera",
        @"walletAmountRequest",
        @"recharge",
        @"t_tipCode",
        @"t_linkString",
        @"onSendText",
        @"t_color",
        @"t_selctorName",
        @"onRecvMessageReceipts",
        @"onLongTap",
        @"cellPaddingToNick",
        @"stopPlayAudio",
        @"onLogin",
        @"allMessagesRead",
        @"allMessagesDeleted",
        @"didRemoveRecentSession",
        @"didUpdateRecentSession",
        @"didAddRecentSession",
        @"didLoadAllRecentSessionCompletion",
        @"onMarkMessageReadCompleteInSession",
        @"addStickTopWithSession",
        @"removeStickTopWithSession",
        @"deleteAllRemoteMessagesWithSession",
        @"onVolumeChanged",
        @"onEndOfSpeech",
        @"onBeginOfSpeech",
        @"rechargeViewPaySuccess",
        @"transToTText",
        @"tapEvent",
        @"recordAudio",
        @"onRecordTouchChanged",
        @"onReceiveCustomSystemNotification",
        @"onRecvAllRemoteMessagesInSessionDeleted",
        @"messagesDeletedInSession",
        @"allMessagesClearedInSession",
        @"onRecvRevokeMessageNotification",
        @"onRecvMessages",
        @"onIMRecvCustomCommand",
        @"onPublisherStateUpdate",
        @"onRoomStreamUpdate",
        @"onRoomUserUpdate",
        @"onRoomStateChanged",
        @"userVideoDuration",
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
        @"showAlert",@"showFromNavigationController",@"showFromRect",
        @"showFromTabBarController",@"showMenuInView",@"snapshotImage",@"switchCameraPosition",
        @"systemLanguage",@"textField",@"textStorage",@"textViewInputAccessoryView",@"timeLabel",@"timeout",
        @"titleLabel",@"unregisterApplicationObservers",
        @"unregisterPlayerItemNoticationObservers",@"updateAccessibilityElements",@"updateApnsToken",
        @"viewForPinSectionHeaderInPagerView",
        @"webSafeDecodeData",@"webSafeDecodeString",@"webSafeEncodeData",@"webSocket",
        @"webSocketDidOpen",@"willChangeHeight",@"willSendMessage",@"onViewDidDisappear",@"onViewWillAppear",
        @"pageControl",@"placeholder",@"playAudio",@"playVideo",@"playbackState",
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
        @"onStart",@"onSystemNotificationCountChanged",@"onTap",@"onTimer",
        @"didChangeHeight",@"didFinishLoad",
        @"dismissAction",@"dismissAnimation",@"display",@"displayView",@"doneEvent",@"downloadWithURL",
        @"drawBackground",@"editAction",@"endEditing",@"endRefresh",@"enterbackground",@"errorWithCode",
        @"exitAction",@"fadeOutWithDuration",@"failButton",@"fetchData",@"fileSize",
        @"finishWithCompletionHandler",@"finishedPlaying",@"firstTimeInterval",@"focusGesture",
        @"gestureRecognizer",@"getCurrentLocationWithCompletion",
        @"getCurrentTopVC",@"getFileName",@"getFirstFrameFromVideoURL",@"getToken",@"getVersion",
        @"getView",@"handleLongPress",@"handleOpenUniversalLink",@"handlePanGesture",
        @"handleResponse",@"handleSwipeGesture",@"handleTap",@"handleTapGesture",
        @"handleTextFieldCharLength",@"headerRereshing",
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
        @"currentTopViewController",@"currentViewControllerWithRootViewController",
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
