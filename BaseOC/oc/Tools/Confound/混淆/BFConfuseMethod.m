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
        if (arc4random_uniform(100) < 30) {
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
        [NSString stringWithFormat:@"\nCGFloat %@ = M_PI * 2.0;\nUIView *%@ = [[UIView alloc] init];\n%@.alpha = %@ / 10.0;",
         var1, var2, var2, var1],
        
        // 模板 2: 数学计算
        [NSString stringWithFormat:@"\nNSInteger %@ = 5;\nBOOL %@ = YES;\nCGFloat %@ = 1.5;\nCGRect %@ = CGRectMake(0, 0, 100 * %@, 50 * %@);",
         var3, var4, var5, var6, var5, var5],
        
        // 模板 3: 对象和协议
        [NSString stringWithFormat:@"\nid %@ = nil;\nClass %@ = [NSString class];\nSEL %@ = @selector(length);\nProtocol *%@ = @protocol(NSCopying);",
         var1, var2, var3, var4],
        
        // 模板 4: 尺寸计算
        [NSString stringWithFormat:@"\nNSUInteger %@ = 10;\nCGFloat %@ = 8.0;\nCGSize %@ = CGSizeMake(44.0, 44.0);\nCGFloat %@ = %@ * (%@.width + %@);",
         var1, var2, var3, var4, var1, var3, var2],
        
        // 模板 5: 颜色和视图
        [NSString stringWithFormat:@"\nUIColor *%@ = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];\nUIView *%@ = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];\n%@.backgroundColor = %@;\n%@.layer.cornerRadius = 5.0;",
         var1, var2, var2, var1, var2],
        
        // 模板 6: 数组和字典
        [NSString stringWithFormat:@"\nNSArray *%@ = @[@1, @2, @3];\nNSDictionary *%@ = @{@\"key\": @\"value\"};\nNSMutableArray *%@ = [%@ mutableCopy];\n[%@ addObject:@4];",
         var1, var2, var3, var1, var3],
        
        // 模板 8: 字符串操作
        [NSString stringWithFormat:@"\nNSString *%@ = @\"Hello\";\nNSString *%@ = @\"World\";\nNSString *%@ = [NSString stringWithFormat:@\"%%@ %%@\", %@, %@];\nNSInteger %@ = %@.length;",
         var1, var2, var3, var1, var2, var4, var3]
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateControlFlowWithIndent:(NSString *)indent {
    NSString *var1 = [self generateRandomVariableName];
    NSString *var2 = [self generateRandomVariableName];
    NSString *var3 = [self generateRandomVariableName];
    NSString *var4 = [self generateRandomVariableName];
    NSString *var5 = [self generateRandomVariableName];

    NSArray *templates = @[
        // 基础 if 语句
        [NSString stringWithFormat:@"\nif (YES) {\n    CGFloat %@ = M_E * 2.0;\n    CGRect %@ = CGRectMake(0, 0, %@, %@);\n}", var1, var2, var1, var1],
        
        // for 循环
        [NSString stringWithFormat:@"\nfor (NSUInteger %@ = 0; %@ < 3; %@++) {\n    CGFloat %@ = (CGFloat)%@ / 3.0;\n    CGPoint %@ = CGPointMake(%@ * 100.0, %@ * 50.0);\n}",
         var1, var1, var1, var2, var1, var3, var2, var2],
        
        // while 循环
        [NSString stringWithFormat:@"\nNSUInteger %@ = 0;\nwhile (%@ < 2) {\n    CGFloat %@ = (CGFloat)%@ * M_PI_4;\n    CGAffineTransform %@ = CGAffineTransformMakeRotation(%@);\n    %@++;\n}",
         var1, var1, var2, var1, var3, var2, var1],
        
        // 布尔逻辑 if 语句
        [NSString stringWithFormat:@"\nBOOL %@ = YES;\nBOOL %@ = NO;\nif (%@ && !%@) {\n    CGFloat %@ = 0.7;\n    UIColor *%@ = [UIColor colorWithWhite:%@ alpha:1.0];\n}",
         var1, var2, var1, var2, var3, [self generateRandomVariableName], var3],
        
        // if-else 语句
        [NSString stringWithFormat:@"\nCGFloat %@ = arc4random_uniform(100) / 100.0;\nif (%@ > 0.5) {\n    CGSize %@ = CGSizeMake(%@ * 200.0, 100.0);\n} else {\n    CGSize %@ = CGSizeMake(100.0, %@ * 200.0);\n}",
         var1, var1, var2, var1, var3, var1],
        
        // 嵌套 if 语句
        [NSString stringWithFormat:@"\nNSInteger %@ = arc4random_uniform(10);\nif (%@ > 3) {\n    if (%@ < 8) {\n        CGRect %@ = CGRectMake(0, 0, %@ * 50.0, %@ * 25.0);\n    }\n}",
         var1, var1, var1, var2, var1, var1],
        
        // do-while 循环
        [NSString stringWithFormat:@"\nNSInteger %@ = 0;\ndo {\n    CGAffineTransform %@ = CGAffineTransformMakeRotation(M_PI * %@ / 180.0);\n    %@++;\n} while (%@ < 3);",
         var1, var2, var1, var1, var1],
        
        // 复杂 for 循环
        [NSString stringWithFormat:@"\nfor (NSInteger %@ = 0, %@ = 10; %@ < %@; %@++, %@--) {\n    CGFloat %@ = (CGFloat)%@ / (CGFloat)%@;\n    CGPoint %@ = CGPointMake(%@ * 100.0, %@ * 50.0);\n}",
         var1, var2, var1, var2, var1, var2, var3, var1, var2, var4, var3, var3],
        
        // 多条件 if 语句
        [NSString stringWithFormat:@"\nCGFloat %@ = 0.3;\nCGFloat %@ = 0.7;\nif (%@ > 0.2 && %@ < 0.8) {\n    CGRect %@ = CGRectMake(%@ * 100.0, %@ * 50.0, 200.0, 100.0);\n}",
         var1, var2, var1, var2, var3, var1, var2],
        
        // 三元运算符
        [NSString stringWithFormat:@"\nBOOL %@ = arc4random_uniform(2) == 1;\nCGFloat %@ = %@ ? 1.0 : 0.5;\nCGRect %@ = %@ ? CGRectMake(0, 0, 100, 50) : CGRectMake(0, 0, 50, 100);",
         var1, var2, var1, var3, var1],
        
        // 多分支 if-else if-else
        [NSString stringWithFormat:@"\nNSInteger %@ = arc4random_uniform(5);\nif (%@ == 0) {\n    CGSize %@ = CGSizeMake(50, 50);\n} else if (%@ == 1) {\n    CGSize %@ = CGSizeMake(100, 100);\n} else {\n    CGSize %@ = CGSizeMake(150, 150);\n}",
         var1, var1, var2, var1, var3, var4],
        
        // 循环中的条件判断
        [NSString stringWithFormat:@"\nfor (NSInteger %@ = 0; %@ < 5; %@++) {\n    if (%@ %% 2 == 0) {\n        CGAffineTransform %@ = CGAffineTransformMakeScale(1.0 + %@ * 0.1, 1.0);\n    } else {\n        CGAffineTransform %@ = CGAffineTransformMakeScale(1.0, 1.0 + %@ * 0.1);\n    }\n}",
         var1, var1, var1, var1, var2, var1, var3, var1],
        
        // 复杂的布尔表达式
        [NSString stringWithFormat:@"\nBOOL %@ = YES;\nBOOL %@ = NO;\nNSInteger %@ = 5;\nif ((%@ || %@) && %@ > 3) {\n    CGPoint %@ = CGPointMake(%@ * 20.0, %@ * 10.0);\n}",
         var1, var2, var3, var1, var2, var3, var4, var3, var3],
        
        // 多层嵌套循环
        [NSString stringWithFormat:@"\nfor (NSInteger %@ = 0; %@ < 2; %@++) {\n    for (NSInteger %@ = 0; %@ < 3; %@++) {\n        CGRect %@ = CGRectMake(%@ * 50.0, %@ * 30.0, 20.0, 20.0);\n    }\n}",
         var1, var1, var1, var2, var2, var2, var3, var1, var2],
        
        // while 循环与计数器
        [NSString stringWithFormat:@"\nNSInteger %@ = 0;\nCGFloat %@ = 0.0;\nwhile (%@ < 4) {\n    %@ += 0.25;\n    CGAffineTransform %@ = CGAffineTransformMakeRotation(%@ * M_PI);\n    %@++;\n}",
         var1, var2, var1, var2, var3, var2, var1],
        
        // 复杂的条件分支
        [NSString stringWithFormat:@"\nNSInteger %@ = arc4random_uniform(100);\nif (%@ < 25) {\n    CGSize %@ = CGSizeMake(25, 25);\n} else if (%@ < 50) {\n    CGSize %@ = CGSizeMake(50, 50);\n} else if (%@ < 75) {\n    CGSize %@ = CGSizeMake(75, 75);\n} else {\n    CGSize %@ = CGSizeMake(100, 100);\n}",
         var1, var1, var2, var1, var3, var1, var4, var5],
        
        // do-while 与复杂条件
        [NSString stringWithFormat:@"\nNSInteger %@ = 0;\nCGFloat %@ = 0.0;\ndo {\n    %@ += 0.1;\n    CGRect %@ = CGRectMake(0, 0, %@ * 100.0, 50.0);\n    %@++;\n} while (%@ < 5 && %@ < 0.5);",
         var1, var2, var2, var3, var2, var1, var1, var2],
        
        // 多变量 for 循环
        [NSString stringWithFormat:@"\nfor (CGFloat %@ = 0.0, %@ = 1.0; %@ < 1.0; %@ += 0.2, %@ -= 0.1) {\n    CGPoint %@ = CGPointMake(%@ * 200.0, %@ * 100.0);\n}",
         var1, var2, var1, var1, var2, var3, var1, var2],
        
        // 复杂的逻辑运算符组合
        [NSString stringWithFormat:@"\nBOOL %@ = arc4random_uniform(2) == 1;\nBOOL %@ = arc4random_uniform(2) == 1;\nNSInteger %@ = arc4random_uniform(10);\nif ((%@ && %@) || (!%@ && %@ > 5)) {\n    CGAffineTransform %@ = CGAffineTransformMakeScale(1.5, 1.5);\n}",
         var1, var2, var3, var1, var2, var1, var3, var4],
        
        // 循环中的多个操作
        [NSString stringWithFormat:@"\nfor (NSInteger %@ = 0; %@ < 3; %@++) {\n    CGFloat %@ = (CGFloat)%@ * 0.33;\n    CGRect %@ = CGRectMake(0, 0, 100 * %@, 50 * %@);\n    CGAffineTransform %@ = CGAffineTransformMakeScale(%@, %@);\n}",
         var1, var1, var1, var2, var1, var3, var2, var2, var4, var2, var2],
        
        // 条件嵌套循环
        [NSString stringWithFormat:@"\nNSInteger %@ = arc4random_uniform(3);\nif (%@ > 0) {\n    for (NSInteger %@ = 0; %@ < %@; %@++) {\n        CGSize %@ = CGSizeMake(%@ * 30.0, %@ * 20.0);\n    }\n}",
         var1, var1, var2, var2, var1, var2, var3, var2, var2],
        
        // 复杂的 while 条件
        [NSString stringWithFormat:@"\nNSInteger %@ = 0;\nCGFloat %@ = 0.0;\nwhile (%@ < 3 && %@ < 0.6) {\n    %@ += 0.2;\n    CGRect %@ = CGRectMake(%@ * 50.0, 0, 100.0, 50.0);\n    %@++;\n}",
         var1, var2, var1, var2, var2, var3, var2, var1],
        
        // 多分支条件与变量赋值
        [NSString stringWithFormat:@"\nNSInteger %@ = arc4random_uniform(4);\nCGSize %@;\nswitch (%@) {\n    case 0:\n        %@ = CGSizeMake(25, 25);\n        break;\n    case 1:\n        %@ = CGSizeMake(50, 50);\n        break;\n    case 2:\n        %@ = CGSizeMake(75, 75);\n        break;\n    default:\n        %@ = CGSizeMake(100, 100);\n        break;\n}",
         var1, var2, var1, var2, var2, var2, var2],
        
        // 复杂的循环控制
        [NSString stringWithFormat:@"\nfor (NSInteger %@ = 0; %@ < 10; %@++) {\n    if (%@ == 3) {\n        continue;\n    }\n    if (%@ == 7) {\n        break;\n    }\n    CGRect %@ = CGRectMake(0, 0, %@ * 10.0, 50.0);\n}",
         var1, var1, var1, var1, var1, var2, var1],
        
        // 条件运算符嵌套
        [NSString stringWithFormat:@"\nBOOL %@ = arc4random_uniform(2) == 1;\nBOOL %@ = arc4random_uniform(2) == 1;\nCGFloat %@ = %@ ? (%@ ? 1.0 : 0.7) : 0.3;\nCGRect %@ = %@ ? CGRectMake(0, 0, 100, 100) : CGRectMake(0, 0, 50, 200);",
         var1, var2, var3, var1, var2, var4, var1]
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateDataStructuresWithIndent:(NSString *)indent {
    NSString *var1 = [self generateRandomVariableName];
    NSString *var2 = [self generateRandomVariableName];
    NSString *var3 = [self generateRandomVariableName];
    NSString *var4 = [self generateRandomVariableName];
    NSString *var5 = [self generateRandomVariableName];

    NSArray *templates = @[
        // 基础数组操作
        [NSString stringWithFormat:@"\nNSMutableArray *%@ = [NSMutableArray array];\n[%@ addObject:[NSValue valueWithCGRect:CGRectMake(0, 0, 50, 50)]];\n[%@ addObject:[NSValue valueWithCGPoint:CGPointMake(10, 10)]];\n[%@ addObject:[NSValue valueWithCGAffineTransform:CGAffineTransformIdentity]];",
         var1, var1, var1, var1],
        
        // 字典操作
        [NSString stringWithFormat:@"\nNSMutableDictionary *%@ = [NSMutableDictionary dictionary];\n%@[@\"scale\"] = @(1.5);\n%@[@\"duration\"] = @(0.3);\n%@[@\"opacity\"] = @(0.8);\nCGSize %@ = CGSizeMake(100 * [%@[@\"scale\"] floatValue], 100);",
         var1, var1, var1, var1, var2, var1],
        
        // 集合操作
        [NSString stringWithFormat:@"\nNSMutableSet *%@ = [NSMutableSet set];\n[%@ addObject:@(M_PI)];\n[%@ addObject:@(M_E)];\n[%@ addObject:@(M_LN2)];\nNSUInteger %@ = %@.count;",
         var1, var1, var1, var1, var2, var1],
        
        // 数组排序
        [NSString stringWithFormat:@"\nNSArray *%@ = @[@(3.14), @(2.71), @(1.41), @(1.61)];\nNSArray *%@ = [%@ sortedArrayUsingComparator:^NSComparisonResult(NSNumber *%@, NSNumber *%@) {\n    return [%@ compare:%@];\n}];\nCGFloat %@ = [%@.firstObject floatValue];",
         var1, var2, var1, var3, var4, var3, var4, [self generateRandomVariableName], var2],
        
        // 复杂字典操作
        [NSString stringWithFormat:@"\nNSMutableDictionary *%@ = [NSMutableDictionary dictionary];\nNSValue *%@ = [NSValue valueWithCGRect:CGRectMake(0, 0, 100, 50)];\nNSValue *%@ = [NSValue valueWithCGSize:CGSizeMake(200, 100)];\n%@[@\"frame\"] = %@;\n%@[@\"size\"] = %@;\nCGRect %@ = [%@[@\"frame\"] CGRectValue];",
         var1, var2, var3, var1, var2, var1, var3, var4, var1],
        
        // 数组枚举
        [NSString stringWithFormat:@"\nNSArray *%@ = @[@1, @2, @3, @4, @5];\nNSMutableArray *%@ = [NSMutableArray array];\n[%@ enumerateObjectsUsingBlock:^(NSNumber *%@, NSUInteger idx, BOOL *stop) {\n    CGRect %@ = CGRectMake(0, 0, [%@ floatValue] * 20.0, 50.0);\n    [%@ addObject:[NSValue valueWithCGRect:%@]];\n}];",
         var1, var2, var1, var3, var4, var3, var2, var4],
        
        // 字典枚举
        [NSString stringWithFormat:@"\nNSDictionary *%@ = @{@\"width\": @100, @\"height\": @50, @\"scale\": @2.0};\n[%@ enumerateKeysAndObjectsUsingBlock:^(NSString *%@, NSNumber *%@, BOOL *stop) {\n    CGFloat %@ = [%@ floatValue];\n    CGRect %@ = CGRectMake(0, 0, %@, %@);\n}];",
         var1, var1, var2, var3, var4, var3, var5, var4, var4],
        
        // 修复的索引集合操作
        [NSString stringWithFormat:@"\nNSMutableIndexSet *%@ = [NSMutableIndexSet indexSet];\n[%@ addIndex:1];\n[%@ addIndex:3];\n[%@ addIndex:5];\nNSArray *%@ = @[@\"A\", @\"B\", @\"C\", @\"D\", @\"E\", @\"F\"];\nNSArray *%@ = [%@ objectsAtIndexes:%@];\nNSUInteger %@ = %@.count;",var1, var1, var1, var1, var2, var3, var2, var1, var4, var3],
        
        // 有序集合
        [NSString stringWithFormat:@"\nNSMutableOrderedSet *%@ = [NSMutableOrderedSet orderedSet];\n[%@ addObject:@(M_PI)];\n[%@ addObject:@(M_E)];\n[%@ addObject:@(M_LN2)];\n[%@ insertObject:@(1.414) atIndex:1];\nCGFloat %@ = [[%@ objectAtIndex:0] floatValue];",
         var1, var1, var1, var1, var1, var2, var1],
        
        // 数组过滤
        [NSString stringWithFormat:@"NSArray *%@ = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];\nNSPredicate *%@ = [NSPredicate predicateWithFormat:@\"self > 5\"];\nNSArray *%@ = [%@ filteredArrayUsingPredicate:%@];\nNSUInteger %@ = %@.count;",
         var1, var2, var3, var1, var2, var4, var3],
        
        // 字典数组转换
        [NSString stringWithFormat:@"\nNSArray *%@ = @[@\"name\", @\"age\", @\"score\"];\nNSArray *%@ = @[@\"John\", @25, @85.5];\nNSDictionary *%@ = [NSDictionary dictionaryWithObjects:%@ forKeys:%@];\nNSString *%@ = %@[@\"name\"];",
         var1, var2, var3, var2, var1, var4, var3],
        
        // 集合操作
        [NSString stringWithFormat:@"\nNSSet *%@ = [NSSet setWithObjects:@1, @2, @3, nil];\nNSSet *%@ = [NSSet setWithObjects:@3, @4, @5, nil];\nNSSet *%@ = [%@ setByAddingObjectsFromSet:%@];\nNSSet *%@ = [%@ intersectsSet:%@] ? %@ : %@;",
         var1, var2, var3, var1, var2, var4, var1, var2, var1, var2],
        
        // 数组映射
        [NSString stringWithFormat:@"\nNSArray *%@ = @[@10, @20, @30, @40];\nNSMutableArray *%@ = [NSMutableArray array];\nfor (NSNumber *%@ in %@) {\n    CGRect %@ = CGRectMake(0, 0, [%@ floatValue], [%@ floatValue] * 0.5);\n    [%@ addObject:[NSValue valueWithCGRect:%@]];\n}",
         var1, var2, var3, var1, var4, var3, var3, var2, var4],
        
        // 复杂数据结构嵌套
        [NSString stringWithFormat:@"\nNSMutableDictionary *%@ = [NSMutableDictionary dictionary];\nNSMutableArray *%@ = [NSMutableArray arrayWithObjects:@1, @2, @3, nil];\nNSMutableSet *%@ = [NSMutableSet setWithObjects:@\"A\", @\"B\", @\"C\", nil];\n%@[@\"array\"] = %@;\n%@[@\"set\"] = %@;\nNSArray *%@ = %@[@\"array\"];",
         var1, var2, var3, var1, var2, var1, var3, var4, var1],
        
 
        // 字典合并
        [NSString stringWithFormat:@"\nNSDictionary *%@ = @{@\"x\": @10, @\"y\": @20};\nNSDictionary *%@ = @{@\"width\": @100, @\"height\": @50};\nNSMutableDictionary *%@ = [NSMutableDictionary dictionaryWithDictionary:%@];\n[%@ addEntriesFromDictionary:%@];\nCGRect %@ = CGRectMake([%@[@\"x\"] floatValue], [%@[@\"y\"] floatValue], [%@[@\"width\"] floatValue], [%@[@\"height\"] floatValue]);",
         var1, var2, var3, var1, var3, var2, var4, var3, var3, var3, var3],
        
        // 集合代数运算
        [NSString stringWithFormat:@"\nNSSet *%@ = [NSSet setWithObjects:@1, @2, @3, @4, nil];\nNSSet *%@ = [NSSet setWithObjects:@3, @4, @5, @6, nil];\nNSSet *%@ = [%@ setByAddingObjectsFromSet:%@];\nNSSet *%@ = [%@ setByAddingObjectsFromSet:%@];\nBOOL %@ = [%@ isSubsetOfSet:%@];",
         var1, var2, var3, var1, var2, var4, var1, var2, var5, var1, var2],
        
        // 数组查找
        [NSString stringWithFormat:@"\nNSArray *%@ = @[@\"apple\", @\"banana\", @\"cherry\", @\"date\", @\"elderberry\"];\nNSString *%@ = @\"cherry\";\nNSUInteger %@ = [%@ indexOfObject:%@];\nBOOL %@ = [%@ containsObject:@\"banana\"];\nNSArray *%@ = [%@ filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@\"self BEGINSWITH 'a'\"]];",
         var1, var2, var3, var1, var2, var4, var1, var5, var1],
        
        // 可变字符串数组
        [NSString stringWithFormat:@"\nNSMutableArray *%@ = [NSMutableArray arrayWithArray:@[@\"Hello\", @\"World\", @\"Test\"]];\n[%@ insertObject:@\"Inserted\" atIndex:1];\n[%@ removeObjectAtIndex:2];\n[%@ replaceObjectAtIndex:0 withObject:@\"Replaced\"];\nNSString *%@ = [%@ componentsJoinedByString:@\"-\"];",
         var1, var1, var1, var1, var2, var1],
        
        // 复杂对象数组
        [NSString stringWithFormat:@"\nNSMutableArray *%@ = [NSMutableArray array];\nfor (int i = 0; i < 5; i++) {\n    NSDictionary *%@ = @{\n        @\"frame\": [NSValue valueWithCGRect:CGRectMake(i * 50.0, 0, 40.0, 40.0)],\n        @\"color\": [UIColor colorWithWhite:(CGFloat)i/5.0 alpha:1.0],\n        @\"scale\": @(1.0 + i * 0.1)\n    };\n    [%@ addObject:%@];\n}",
         var1, var2, var1, var2],
        
        // 字典的键值枚举
        [NSString stringWithFormat:@"\nNSDictionary *%@ = @{\n    @\"position\": [NSValue valueWithCGPoint:CGPointMake(10.0, 20.0)],\n    @\"size\": [NSValue valueWithCGSize:CGSizeMake(100.0, 50.0)],\n    @\"transform\": [NSValue valueWithCGAffineTransform:CGAffineTransformIdentity]\n};\nNSArray *%@ = [%@ allKeys];\nNSArray *%@ = [%@ allValues];\nfor (NSString *%@ in %@) {\n    id %@ = %@[%@];\n}",
         var1, var2, var1, var3, var1, var4, var2, var5, var1, var4],
        
        // 数组分组
        [NSString stringWithFormat:@"\nNSArray *%@ = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];\nNSMutableArray *%@ = [NSMutableArray array];\nNSMutableArray *%@ = [NSMutableArray array];\nfor (NSNumber *%@ in %@) {\n    if ([%@ integerValue] %% 2 == 0) {\n        [%@ addObject:%@];\n    } else {\n        [%@ addObject:%@];\n    }\n}",
         var1, var2, var3, var4, var1, var4, var2, var4, var3, var4],
        
        // 堆栈模拟
        [NSString stringWithFormat:@"\nNSMutableArray *%@ = [NSMutableArray array];\n[%@ addObject:@\"First\"];\n[%@ addObject:@\"Second\"];\n[%@ addObject:@\"Third\"];\nNSString *%@ = [%@ lastObject];\n[%@ removeLastObject];\nNSUInteger %@ = %@.count;",
         var1, var1, var1, var1, var2, var1, var1, var3, var1],
        
        // 队列模拟
        [NSString stringWithFormat:@"\nNSMutableArray *%@ = [NSMutableArray array];\n[%@ addObject:@\"First\"];\n[%@ addObject:@\"Second\"];\n[%@ addObject:@\"Third\"];\nNSString *%@ = [%@ firstObject];\n[%@ removeObjectAtIndex:0];\nNSUInteger %@ = %@.count;",
         var1, var1, var1, var1, var2, var1, var1, var3, var1],
        
        // 复杂过滤和映射
        [NSString stringWithFormat:@"\nNSArray *%@ = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];\nNSIndexSet *%@ = [%@ indexesOfObjectsPassingTest:^BOOL(NSNumber *%@, NSUInteger idx, BOOL *stop) {\n    return [%@ integerValue] > 5 && [%@ integerValue] %% 2 == 0;\n}];\nNSArray *%@ = [%@ objectsAtIndexes:%@];\nCGFloat %@ = [[%@ valueForKeyPath:@\"@avg.self\"] floatValue];",
         var1, var2, var1, var3, var3, var3, var4, var1, var2, var5, var4],
        
        // 嵌套数据结构
        [NSString stringWithFormat:@"\nNSMutableArray *%@ = [NSMutableArray array];\nfor (int i = 0; i < 3; i++) {\n    NSMutableDictionary *%@ = [NSMutableDictionary dictionary];\n    %@[@\"index\"] = @(i);\n    %@[@\"frame\"] = [NSValue valueWithCGRect:CGRectMake(i * 50.0, 0, 40.0, 40.0)];\n    NSMutableArray *%@ = [NSMutableArray array];\n    for (int j = 0; j < 2; j++) {\n        [%@ addObject:@(i + j)];\n    }\n    %@[@\"values\"] = %@;\n    [%@ addObject:%@];\n}",
         var1, var2, var2, var2, var3, var3, var2, var3, var1, var2],
        
        // 新的：使用索引集进行批量操作
        [NSString stringWithFormat:@"\nNSMutableIndexSet *%@ = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(2, 3)];\nNSArray *%@ = @[@\"A\", @\"B\", @\"C\", @\"D\", @\"E\"];\nNSArray *%@ = [%@ objectsAtIndexes:%@];\n[%@ addIndex:0];\n[%@ removeIndex:3];\nBOOL %@ = [%@ containsIndex:2];",
         var1, var2, var3, var2, var1, var1, var1, var4, var1],
        
        // 新的：哈希表性能测试
        [NSString stringWithFormat:@"\nNSMutableDictionary *%@ = [NSMutableDictionary dictionary];\nfor (int i = 0; i < 10; i++) {\n    NSString *%@ = [NSString stringWithFormat:@\"key%%d\", i];\n    CGRect %@ = CGRectMake(i * 10.0, i * 5.0, 30.0, 20.0);\n    %@[%@] = [NSValue valueWithCGRect:%@];\n}\nNSUInteger %@ = %@.count;\nNSArray *%@ = [%@ allKeys];",
         var1, var2, var3, var1, var2, var3, var4, var1, var5, var1]
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateObjectOperationsWithIndent:(NSString *)indent {
    NSString *var1 = [self generateRandomVariableName];
    NSString *var2 = [self generateRandomVariableName];
    NSString *var3 = [self generateRandomVariableName];
    NSString *var4 = [self generateRandomVariableName];
    NSString *var5 = [self generateRandomVariableName];
    NSString *var6 = [self generateRandomVariableName];

    NSArray *templates = @[
        // UIView 创建和配置
        [NSString stringWithFormat:@"\nUIView *%@ = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];\n%@.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];\n%@.layer.cornerRadius = 8.0;\n%@.layer.borderWidth = 1.0;\n%@.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;",
         var1, var1, var1, var1, var1],
        
        // 变换操作
        [NSString stringWithFormat:@"\nCGAffineTransform %@ = CGAffineTransformIdentity;\nCGAffineTransform %@ = CGAffineTransformScale(%@, 1.2, 0.8);\nCGAffineTransform %@ = CGAffineTransformRotate(%@, M_PI_4);\nCGAffineTransform %@ = CGAffineTransformTranslate(%@, 10, 5);",
         var1, var2, var1, var3, var2, var4, var3],
        
        // CALayer 操作
        [NSString stringWithFormat:@"\nCALayer *%@ = [CALayer layer];\n%@.frame = CGRectMake(0, 0, 100, 50);\n%@.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;\n%@.cornerRadius = 4.0;\n%@.shadowOpacity = 0.2;",
         var1, var1, var1, var1, var1],
        
        // UILabel 创建和配置
        [NSString stringWithFormat:@"\nUILabel *%@ = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 40)];\n%@.text = @\"Sample Text\";\n%@.font = [UIFont systemFontOfSize:16.0];\n%@.textColor = [UIColor darkGrayColor];\n%@.textAlignment = NSTextAlignmentCenter;\n%@.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1.0];",
         var1, var1, var1, var1, var1, var1],
        
        // UIButton 创建和配置
        [NSString stringWithFormat:@"\nUIButton *%@ = [UIButton buttonWithType:UIButtonTypeSystem];\n%@.frame = CGRectMake(0, 0, 120, 44);\n[%@ setTitle:@\"Button\" forState:UIControlStateNormal];\n%@.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];\n%@.layer.cornerRadius = 6.0;\n%@.layer.borderWidth = 1.0;\n%@.layer.borderColor = [UIColor lightGrayColor].CGColor;",
         var1, var1, var1, var1, var1, var1, var1],
        
        // UIImageView 创建和配置
        [NSString stringWithFormat:@"\nUIImageView *%@ = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];\n%@.contentMode = UIViewContentModeScaleAspectFill;\n%@.clipsToBounds = YES;\n%@.layer.cornerRadius = 10.0;\n%@.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];",
         var1, var1, var1, var1, var1],
        
        // UIScrollView 创建和配置
        [NSString stringWithFormat:@"\nUIScrollView *%@ = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 200, 300)];\n%@.contentSize = CGSizeMake(200, 600);\n%@.showsVerticalScrollIndicator = YES;\n%@.showsHorizontalScrollIndicator = NO;\n%@.bounces = YES;\n%@.decelerationRate = UIScrollViewDecelerationRateNormal;",
         var1, var1, var1, var1, var1, var1],
        
        // UITableView 创建和配置
        [NSString stringWithFormat:@"\nUITableView *%@ = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 200, 300) style:UITableViewStylePlain];\n%@.rowHeight = 44.0;\n%@.sectionHeaderHeight = 30.0;\n%@.separatorStyle = UITableViewCellSeparatorStyleSingleLine;\n%@.backgroundColor = [UIColor groupTableViewBackgroundColor];",
         var1, var1, var1, var1, var1],
        
        // 复杂图层操作
        [NSString stringWithFormat:@"\nCALayer *%@ = [CALayer layer];\n%@.frame = CGRectMake(0, 0, 80, 80);\n%@.backgroundColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0].CGColor;\n%@.cornerRadius = 8.0;\n%@.shadowColor = [UIColor blackColor].CGColor;\n%@.shadowOffset = CGSizeMake(2, 2);\n%@.shadowRadius = 4.0;\n%@.shadowOpacity = 0.3;\n%@.borderWidth = 2.0;\n%@.borderColor = [UIColor whiteColor].CGColor;",
         var1, var1, var1, var1, var1, var1, var1, var1, var1, var1],
        
        // 复杂变换组合
        [NSString stringWithFormat:@"\nCGAffineTransform %@ = CGAffineTransformIdentity;\nCGAffineTransform %@ = CGAffineTransformMakeScale(1.5, 1.5);\nCGAffineTransform %@ = CGAffineTransformMakeRotation(M_PI_4);\nCGAffineTransform %@ = CGAffineTransformMakeTranslation(20, 10);\nCGAffineTransform %@ = CGAffineTransformConcat(%@, %@);\nCGAffineTransform %@ = CGAffineTransformConcat(%@, %@);",
         var1, var2, var3, var4, var5, var1, var2, var6, var5, var3],
        
        // 视图层次操作
        [NSString stringWithFormat:@"\nUIView *%@ = [[UIView alloc] initWithFrame:CGRectMake(10, 10, 150, 150)];\nUIView *%@ = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 110, 110)];\nUIView *%@ = [[UIView alloc] initWithFrame:CGRectMake(30, 30, 70, 70)];\n%@.backgroundColor = [UIColor redColor];\n%@.backgroundColor = [UIColor greenColor];\n%@.backgroundColor = [UIColor blueColor];\n[%@ addSubview:%@];\n[%@ addSubview:%@];",
         var1, var2, var3, var1, var2, var3, var1, var2, var2, var3],
        

        // 图层动画
        [NSString stringWithFormat:@"\nCABasicAnimation *%@ = [CABasicAnimation animationWithKeyPath:@\"transform.rotation\"];\n%@.fromValue = @(0.0);\n%@.toValue = @(M_PI * 2.0);\n%@.duration = 1.0;\n%@.repeatCount = 1;\nCALayer *%@ = [CALayer layer];\n[%@ addAnimation:%@ forKey:@\"rotationAnimation\"];",
         var1, var1, var1, var1, var1, var2, var2, var1],
        
        // 渐变图层
        [NSString stringWithFormat:@"\nCAGradientLayer *%@ = [CAGradientLayer layer];\n%@.frame = CGRectMake(0, 0, 120, 120);\n%@.colors = @[(id)[UIColor redColor].CGColor, (id)[UIColor blueColor].CGColor];\n%@.locations = @[@0.0, @1.0];\n%@.startPoint = CGPointMake(0.0, 0.5);\n%@.endPoint = CGPointMake(1.0, 0.5);\n%@.cornerRadius = 10.0;",
         var1, var1, var1, var1, var1, var1, var1],
        
        // 形状图层
        [NSString stringWithFormat:@"\nCAShapeLayer *%@ = [CAShapeLayer layer];\nUIBezierPath *%@ = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 80, 80) cornerRadius:12.0];\n%@.path = %@.CGPath;\n%@.fillColor = [UIColor orangeColor].CGColor;\n%@.strokeColor = [UIColor darkGrayColor].CGColor;\n%@.lineWidth = 2.0;\n%@.lineCap = kCALineCapRound;",
         var1, var2, var1, var2, var1, var1, var1, var1],
        
        // 文本图层
        [NSString stringWithFormat:@"\nCATextLayer *%@ = [CATextLayer layer];\n%@.frame = CGRectMake(0, 0, 120, 40);\n%@.string = @\"Sample Text\";\n%@.fontSize = 14.0;\n%@.foregroundColor = [UIColor blackColor].CGColor;\n%@.alignmentMode = kCAAlignmentCenter;\n%@.contentsScale = [UIScreen mainScreen].scale;",
         var1, var1, var1, var1, var1, var1, var1],
        
        // 复制图层
        [NSString stringWithFormat:@"\nCAReplicatorLayer *%@ = [CAReplicatorLayer layer];\n%@.frame = CGRectMake(0, 0, 200, 60);\n%@.instanceCount = 3;\n%@.instanceTransform = CATransform3DMakeTranslation(50, 0, 0);\nCALayer *%@ = [CALayer layer];\n%@.frame = CGRectMake(0, 0, 40, 40);\n%@.backgroundColor = [UIColor systemBlueColor].CGColor;\n[%@ addSublayer:%@];",
         var1, var1, var1, var1, var2, var2, var2, var1, var2],
        
        // 复杂视图组合
        [NSString stringWithFormat:@"\nUIView *%@ = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 180, 180)];\nUILabel *%@ = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 140, 30)];\nUIButton *%@ = [UIButton buttonWithType:UIButtonTypeSystem];\n%@.frame = CGRectMake(20, 70, 140, 44);\nUIImageView *%@ = [[UIImageView alloc] initWithFrame:CGRectMake(60, 130, 60, 40)];\n[%@ addSubview:%@];\n[%@ addSubview:%@];\n[%@ addSubview:%@];",
         var1, var2, var3, var3, var4, var1, var2, var1, var3, var1, var4],
        
        // 滚动视图内容
        [NSString stringWithFormat:@"\nUIScrollView *%@ = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 200, 400)];\nUIView *%@ = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 800)];\n%@.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];\nfor (int i = 0; i < 5; i++) {\n    UIView *%@ = [[UIView alloc] initWithFrame:CGRectMake(20, 50 + i * 120, 160, 100)];\n    %@.backgroundColor = [UIColor colorWithWhite:0.8 + i * 0.05 alpha:1.0];\n    [%@ addSubview:%@];\n}\n[%@ addSubview:%@];\n%@.contentSize = %@.frame.size;",
         var1, var2, var2, var3, var3, var2, var3, var1, var2, var1, var2],
        

        // 图层组动画
        [NSString stringWithFormat:@"\nCAAnimationGroup *%@ = [CAAnimationGroup animation];\nCABasicAnimation *%@ = [CABasicAnimation animationWithKeyPath:@\"position\"];\nCABasicAnimation *%@ = [CABasicAnimation animationWithKeyPath:@\"opacity\"];\n%@.fromValue = @(0.0);\n%@.toValue = @(1.0);\n%@.animations = @[%@, %@];\n%@.duration = 0.5;\nCALayer *%@ = [CALayer layer];\n[%@ addAnimation:%@ forKey:@\"groupAnimation\"];",
         var1, var2, var3, var3, var3, var1, var2, var3, var1, var4, var4, var1],
        
        // 复杂图层样式
        [NSString stringWithFormat:@"\nCALayer *%@ = [CALayer layer];\n%@.frame = CGRectMake(0, 0, 100, 100);\n%@.backgroundColor = [UIColor colorWithRed:0.1 green:0.2 blue:0.3 alpha:1.0].CGColor;\n%@.cornerRadius = 12.0;\n%@.shadowColor = [UIColor blackColor].CGColor;\n%@.shadowOffset = CGSizeMake(0, 3);\n%@.shadowRadius = 6.0;\n%@.shadowOpacity = 0.4;\n%@.borderWidth = 2.0;\n%@.borderColor = [UIColor whiteColor].CGColor;\n%@.masksToBounds = NO;\n%@.opacity = 0.9;",
         var1, var1, var1, var1, var1, var1, var1, var1, var1, var1, var1, var1]
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateStringOperationsWithIndent:(NSString *)indent {
    NSString *var1 = [self generateRandomVariableName];
    NSString *var2 = [self generateRandomVariableName];
    NSString *var3 = [self generateRandomVariableName];
    NSString *var4 = [self generateRandomVariableName];
    NSString *var5 = [self generateRandomVariableName];
    NSString *var6 = [self generateRandomVariableName];
    NSString *var7 = [self generateRandomVariableName];
    NSString *var8 = [self generateRandomVariableName];
    
    NSArray *templates = @[
        // 基础字符串拼接
        [NSString stringWithFormat:@"\nNSString *%@ = @\"Content\";\nNSString *%@ = @\"Data\";\nNSString *%@ = [%@ stringByAppendingString:%@];\nNSUInteger %@ = %@.length;\nNSRange %@ = NSMakeRange(0, %@);",
         var1, var2, var3, var1, var2, var4, var3, var5, var4],
        
        // 字符串大小写转换和比较
        [NSString stringWithFormat:@"\nNSString *%@ = @\"SampleText\";\nNSString *%@ = [%@ uppercaseString];\nNSString *%@ = [%@ lowercaseString];\nNSString *%@ = [%@ capitalizedString];\nNSComparisonResult %@ = [%@ compare:%@];",
         var1, var2, var1, var3, var1, var4, var1, var5, var2, var3],
        
        // 文件路径操作
        [NSString stringWithFormat:@"\nNSString *%@ = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;\nNSString *%@ = [%@ stringByAppendingPathComponent:@\"data.file\"];\nNSString *%@ = [%@ pathExtension];\nNSString *%@ = [%@ lastPathComponent];\nNSString *%@ = [%@ stringByDeletingLastPathComponent];",
         var1, var2, var1, var3, var2, var4, var2, var5, var2],
        
        // 字符串格式化
        [NSString stringWithFormat:@"\nNSInteger %@ = 42;\nCGFloat %@ = 3.14159;\nNSString *%@ = [NSString stringWithFormat:@\"Number: %%ld, Pi: %%.2f\", %@, %@];\nNSString *%@ = [NSString stringWithFormat:@\"Value: %%.3f\", %@ * 2.0];",
         var1, var2, var3, var1, var2, var4, var2],
        
        // 字符串搜索和替换
        [NSString stringWithFormat:@"\nNSString *%@ = @\"Hello World Example Text\";\nNSRange %@ = [%@ rangeOfString:@\"World\"];\nBOOL %@ = %@.location != NSNotFound;\nNSString *%@ = [%@ stringByReplacingOccurrencesOfString:@\"World\" withString:@\"Universe\"];\nNSString *%@ = [%@ stringByReplacingCharactersInRange:NSMakeRange(6, 5) withString:@\"There\"];",
         var1, var2, var1, var3, var2, var4, var1, var5, var1],
        
        // 字符串分割
        [NSString stringWithFormat:@"\nNSString *%@ = @\"apple,banana,cherry,date\";\nNSArray *%@ = [%@ componentsSeparatedByString:@\",\"];\nNSString *%@ = %@.firstObject;\nNSString *%@ = %@.lastObject;\nNSUInteger %@ = %@.count;",
         var1, var2, var1, var3, var2, var4, var2, var5, var2],
        
        // 字符串编码
        [NSString stringWithFormat:@"\nNSString *%@ = @\"Hello 世界\";\nNSData *%@ = [%@ dataUsingEncoding:NSUTF8StringEncoding];\nNSString *%@ = [[NSString alloc] initWithData:%@ encoding:NSUTF8StringEncoding];\nNSString *%@ = [%@ stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];",
         var1, var2, var1, var3, var2, var4, var1],
        
        // 可变字符串操作
        [NSString stringWithFormat:@"\nNSMutableString *%@ = [NSMutableString stringWithString:@\"Initial\"];\n[%@ appendString:@\" Text\"];\n[%@ insertString:@\"More \" atIndex:0];\n[%@ replaceCharactersInRange:NSMakeRange(5, 4) withString:@\"Content\"];\n[%@ deleteCharactersInRange:NSMakeRange(0, 6)];",
         var1, var1, var1, var1, var1],
        
        // 字符串前缀和后缀
        [NSString stringWithFormat:@"\nNSString *%@ = @\"https://www.example.com/path\";\nBOOL %@ = [%@ hasPrefix:@\"https://\"];\nBOOL %@ = [%@ hasSuffix:@\".com\"];\nBOOL %@ = [%@ containsString:@\"example\"];\nNSString *%@ = [%@ substringFromIndex:8];\nNSString *%@ = [%@ substringToIndex:22];",
         var1, var2, var1, var3, var1, var4, var1, var5, var1, var6, var1],
        
        // 字符串修剪和空白处理
        [NSString stringWithFormat:@"\nNSString *%@ = @\"   Hello World   \";\nNSString *%@ = [%@ stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];\nNSArray *%@ = [%@ componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];\nNSString *%@ = [%@ stringByReplacingOccurrencesOfString:@\" \" withString:@\"_\"];",
         var1, var2, var1, var3, var1, var4, var1],
        
        // 数字和字符串转换
        [NSString stringWithFormat:@"\nNSInteger %@ = 123;\nCGFloat %@ = 45.67;\nNSString *%@ = [NSString stringWithFormat:@\"%%ld\", %@];\nNSString *%@ = [@(%@) stringValue];\nNSString *%@ = [NSString stringWithFormat:@\"%%.2f\", %@];\nNSInteger %@ = [%@ integerValue];\nCGFloat %@ = [%@ floatValue];",
         var1, var2, var3, var1, var4, var2, var5, var2, var6, var3, var7, var5],
        
        // 字符串枚举
        [NSString stringWithFormat:@"\nNSString *%@ = @\"Hello\";\n[%@ enumerateSubstringsInRange:NSMakeRange(0, %@.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *%@, NSRange %@, NSRange %@, BOOL *%@) {\n    unichar %@ = [%@ characterAtIndex:0];\n}];",
         var1, var1, var1, var2, var3, var4, var5, var6, var2],
        
        // 正则表达式
        [NSString stringWithFormat:@"\nNSString *%@ = @\"Test123Example456Data\";\nNSRegularExpression *%@ = [NSRegularExpression regularExpressionWithPattern:@\"[0-9]+\" options:0 error:NULL];\nNSArray *%@ = [%@ matchesInString:%@ options:0 range:NSMakeRange(0, %@.length)];\nNSUInteger %@ = %@.count;",
         var1, var2, var3, var2, var1, var1, var4, var3],
        
        // 属性字符串
        [NSString stringWithFormat:@"\nNSMutableAttributedString *%@ = [[NSMutableAttributedString alloc] initWithString:@\"Styled Text\"];\n[%@ addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0, 6)];\n[%@ addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:16.0] range:NSMakeRange(7, 4)];\n[%@ addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, %@.length)];",
         var1, var1, var1, var1, var1],
        
        // 字符串比较选项
        [NSString stringWithFormat:@"\nNSString *%@ = @\"Hello\";\nNSString *%@ = @\"hello\";\nBOOL %@ = [%@ isEqualToString:%@];\nBOOL %@ = [%@ caseInsensitiveCompare:%@] == NSOrderedSame;\nNSComparisonResult %@ = [%@ compare:%@ options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];",
         var1, var2, var3, var1, var2, var4, var1, var2, var5, var1, var2],
        
        // 字符串编码检测
        [NSString stringWithFormat:@"\nNSString *%@ = @\"Sample Text\";\nNSData *%@ = [%@ dataUsingEncoding:NSUTF8StringEncoding];\nNSStringEncoding %@ = [%@ fastestEncoding];\nconst char *%@ = [%@ UTF8String];\nNSString *%@ = [NSString stringWithCString:%@ encoding:NSUTF8StringEncoding];",
         var1, var2, var1, var3, var1, var4, var1, var5, var4],
        
        // 字符串写入文件
        [NSString stringWithFormat:@"\nNSString *%@ = @\"Hello World\";\nNSString *%@ = [NSTemporaryDirectory() stringByAppendingPathComponent:@\"test.txt\"];\nNSError *%@;\nBOOL %@ = [%@ writeToFile:%@ atomically:YES encoding:NSUTF8StringEncoding error:&%@];\nNSString *%@ = [NSString stringWithContentsOfFile:%@ encoding:NSUTF8StringEncoding error:NULL];",
         var1, var2, var3, var4, var1, var2, var3, var5, var2],

        // 字符串性能测试
        [NSString stringWithFormat:@"\nNSMutableString *%@ = [NSMutableString string];\nfor (int i = 0; i < 10; i++) {\n    [%@ appendFormat:@\"Item%%d \", i];\n}\nNSString *%@ = [%@ copy];\nNSUInteger %@ = %@.length;\nNSArray *%@ = [%@ componentsSeparatedByString:@\" \"];",
         var1, var1, var2, var1, var3, var2, var4, var2],
        
        // 本地化字符串
        [NSString stringWithFormat:@"\nNSString *%@ = NSLocalizedString(@\"Welcome\", @\"Welcome message\");\nNSString *%@ = [[NSBundle mainBundle] localizedStringForKey:@\"Title\" value:@\"Default\" table:nil];\nNSString *%@ = [NSString stringWithFormat:NSLocalizedString(@\"Count: %%d\", @\"Count format\"), 5];",
         var1, var2, var3],

        // 字符串范围和子字符串
        [NSString stringWithFormat:@"\nNSString *%@ = @\"Hello World Example\";\nNSRange %@ = NSMakeRange(6, 5);\nNSString *%@ = [%@ substringWithRange:%@];\nNSString *%@ = [%@ substringToIndex:5];\nNSString *%@ = [%@ substringFromIndex:12];\nNSArray *%@ = [%@ componentsSeparatedByString:@\" \"];",
         var1, var2, var3, var1, var2, var4, var1, var5, var1, var6, var1],
        
        // URL 字符串操作
        [NSString stringWithFormat:@"NSString *%@ = @\"https://example.com/path?query=test&value=123\";\nNSURL *%@ = [NSURL URLWithString:%@];\nNSString *%@ = %@.scheme;\nNSString *%@ = %@.host;\nNSString *%@ = %@.path;\nNSString *%@ = %@.query;",
         var1, var2, var1, var3, var2, var4, var2, var5, var2, var6, var2],
        
        // 字符串字符访问
        [NSString stringWithFormat:@"\nNSString *%@ = @\"ABCDEFG\";\nunichar %@ = [%@ characterAtIndex:2];\nNSMutableString *%@ = [NSMutableString string];\nfor (NSUInteger i = 0; i < %@.length; i++) {\n    unichar %@ = [%@ characterAtIndex:i];\n    [%@ appendFormat:@\"%%C\", %@];\n}",
         var1, var2, var1, var3, var1, var4, var1, var3, var4],
        
        // 字符串集合操作
        [NSString stringWithFormat:@"\nNSSet *%@ = [NSSet setWithObjects:@\"apple\", @\"banana\", @\"cherry\", nil];\nNSArray *%@ = %@.allObjects;\nNSString *%@ = [%@ componentsJoinedByString:@\", \"];\nNSArray *%@ = [%@ sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];",
         var1, var2, var1, var3, var2, var4, var2],
        
        // 复杂字符串构建
        [NSString stringWithFormat:@"\nNSMutableString *%@ = [NSMutableString string];\n[%@ appendString:@\"Items: \"];\nfor (int i = 1; i <= 5; i++) {\n    [%@ appendFormat:@\"%%d\", i];\n    if (i < 5) [%@ appendString:@\", \"];\n}\nNSString *%@ = [NSString stringWithString:%@];\nNSUInteger %@ = %@.length;",
         var1, var1, var1, var1, var2, var1, var3, var2],
        
        // 字符串性能优化
        [NSString stringWithFormat:@"\n@autoreleasepool {\n    NSMutableString *%@ = [NSMutableString stringWithCapacity:100];\n    for (int i = 0; i < 20; i++) {\n        [%@ appendFormat:@\"Value%%d\", i];\n    }\n    NSString *%@ = [%@ copy];\n    NSData *%@ = [%@ dataUsingEncoding:NSUTF8StringEncoding];\n}",
         var1, var1, var2, var1, var3, var2]
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateMathematicalOperationsWithIndent:(NSString *)indent {
    NSString *var1 = [self generateRandomVariableName];
    NSString *var2 = [self generateRandomVariableName];
    NSString *var3 = [self generateRandomVariableName];
    NSString *var4 = [self generateRandomVariableName];
    NSString *var5 = [self generateRandomVariableName];
    NSString *var6 = [self generateRandomVariableName];
    NSString *var7 = [self generateRandomVariableName];
    NSString *var8 = [self generateRandomVariableName];
    
    NSArray *templates = @[
        // 矩形几何运算
        [NSString stringWithFormat:@"\nCGRect %@ = CGRectMake(0, 0, 200, 100);\nCGRect %@ = CGRectInset(%@, 10, 5);\nCGRect %@ = CGRectOffset(%@, 5, 2);\nCGRect %@ = CGRectUnion(%@, %@);\nCGRect %@ = CGRectIntersection(%@, %@);",
         var1, var2, var1, var3, var2, var4, var1, var3, var5, var1, var3],
        
        // 三角函数运算
        [NSString stringWithFormat:@"\nCGFloat %@ = M_PI;\nCGFloat %@ = %@ * %@;\nCGFloat %@ = sqrt(%@);\nCGFloat %@ = cos(%@);\nCGFloat %@ = sin(%@);\nCGFloat %@ = tan(%@);",
         var1, var2, var1, var1, var3, var2, var4, var1, var5, var1, var6, var1],
        
        // 点运算和距离计算
        [NSString stringWithFormat:@"\nCGPoint %@ = CGPointMake(0, 0);\nCGPoint %@ = CGPointMake(100, 50);\nCGFloat %@ = hypot(%@.x - %@.x, %@.y - %@.y);\nCGPoint %@ = CGPointMake((%@.x + %@.x) / 2, (%@.y + %@.y) / 2);\nCGVector %@ = CGVectorMake(%@.x - %@.x, %@.y - %@.y);",
         var1, var2, var3, var2, var1, var2, var1, var4, var1, var2, var1, var2, var5, var2, var1, var2, var1],
        
        // 随机数生成
        [NSString stringWithFormat:@"\nCGFloat %@ = (CGFloat)arc4random_uniform(100) / 100.0;\nNSInteger %@ = arc4random_uniform(50) + 10;\nCGFloat %@ = %@ * 200.0;\nCGFloat %@ = (CGFloat)arc4random_uniform(360) * M_PI / 180.0;\nCGPoint %@ = CGPointMake(cos(%@) * 100.0, sin(%@) * 100.0);",
         var1, var2, var3, var1, var4, var5, var4, var4],
        
        // 尺寸运算
        [NSString stringWithFormat:@"\nCGSize %@ = CGSizeMake(100, 50);\nCGSize %@ = CGSizeMake(200, 100);\nCGSize %@ = CGSizeMake(%@.width + %@.width, %@.height + %@.height);\nCGSize %@ = CGSizeMake(%@.width * 1.5, %@.height * 0.8);\nCGFloat %@ = %@.width * %@.height;",
         var1, var2, var3, var1, var2, var1, var2, var4, var3, var3, var5, var3, var3],
        
        // 向量运算
        [NSString stringWithFormat:@"\nCGVector %@ = CGVectorMake(10, 5);\nCGVector %@ = CGVectorMake(3, 7);\nCGVector %@ = CGVectorMake(%@.dx + %@.dx, %@.dy + %@.dy);\nCGFloat %@ = %@.dx * %@.dx + %@.dy * %@.dy;\nCGFloat %@ = sqrt(%@);",
         var1, var2, var3, var1, var2, var1, var2, var4, var1, var1, var1, var1, var5, var4],
        
        // 矩阵运算
        [NSString stringWithFormat:@"\nCGAffineTransform %@ = CGAffineTransformIdentity;\nCGAffineTransform %@ = CGAffineTransformMake(1.0, 0.5, -0.5, 1.0, 10.0, 5.0);\nCGAffineTransform %@ = CGAffineTransformConcat(%@, %@);\nBOOL %@ = CGAffineTransformIsIdentity(%@);\nCGAffineTransform %@ = CGAffineTransformInvert(%@);",
         var1, var2, var3, var1, var2, var4, var3, var5, var3],
        
        // 几何变换组合
        [NSString stringWithFormat:@"\nCGAffineTransform %@ = CGAffineTransformIdentity;\nCGAffineTransform %@ = CGAffineTransformMakeRotation(M_PI_4);\nCGAffineTransform %@ = CGAffineTransformMakeScale(1.5, 0.8);\nCGAffineTransform %@ = CGAffineTransformMakeTranslation(20, 10);\nCGAffineTransform %@ = CGAffineTransformConcat(%@, %@);\nCGAffineTransform %@ = CGAffineTransformConcat(%@, %@);",
         var1, var2, var3, var4, var5, var2, var3, var6, var5, var4],
        
        // 复杂三角函数
        [NSString stringWithFormat:@"\nCGFloat %@ = M_PI / 6.0;\nCGFloat %@ = sin(%@);\nCGFloat %@ = cos(%@);\nCGFloat %@ = tan(%@);\nCGFloat %@ = asin(%@);\nCGFloat %@ = acos(%@);\nCGFloat %@ = atan(%@);",
         var1, var2, var1, var3, var1, var4, var1, var5, var2, var6, var3, var7, var4],
        
        // 指数和对数运算
        [NSString stringWithFormat:@"\nCGFloat %@ = M_E;\nCGFloat %@ = exp(1.0);\nCGFloat %@ = log(%@);\nCGFloat %@ = log10(100.0);\nCGFloat %@ = pow(2.0, 3.0);\nCGFloat %@ = sqrt(16.0);",
         var1, var2, var3, var1, var4, var5, var6],
        
        // 范围运算
        [NSString stringWithFormat:@"\nNSRange %@ = NSMakeRange(0, 10);\nNSRange %@ = NSMakeRange(5, 8);\nNSRange %@ = NSIntersectionRange(%@, %@);\nBOOL %@ = NSLocationInRange(7, %@);\nNSUInteger %@ = NSMaxRange(%@);",
         var1, var2, var3, var1, var2, var4, var1, var5, var1],
        
        // 浮点数比较和舍入
        [NSString stringWithFormat:@"\nCGFloat %@ = 3.14159;\nCGFloat %@ = round(%@);\nCGFloat %@ = floor(%@);\nCGFloat %@ = ceil(%@);\nCGFloat %@ = fabs(-2.5);\nCGFloat %@ = fmod(10.3, 3.0);",
         var1, var2, var1, var3, var1, var4, var1, var5, var6],
        
        // 复杂几何计算
        [NSString stringWithFormat:@"\nCGRect %@ = CGRectMake(10, 20, 100, 80);\nCGRect %@ = CGRectMake(50, 40, 120, 60);\nBOOL %@ = CGRectIntersectsRect(%@, %@);\nBOOL %@ = CGRectContainsRect(%@, %@);\nBOOL %@ = CGRectContainsPoint(%@, CGPointMake(60, 60));\nCGRect %@ = CGRectStandardize(CGRectMake(150, 150, -50, -30));",
         var1, var2, var3, var1, var2, var4, var2, var1, var5, var1, var6],
        
        // 向量几何
        [NSString stringWithFormat:@"\nCGPoint %@ = CGPointMake(30, 40);\nCGPoint %@ = CGPointMake(70, 20);\nCGVector %@ = CGVectorMake(%@.x - %@.x, %@.y - %@.y);\nCGFloat %@ = sqrt(%@.dx * %@.dx + %@.dy * %@.dy);\nCGPoint %@ = CGPointMake(%@.x + %@.dx, %@.y + %@.dy);",
         var1, var2, var3, var2, var1, var2, var1, var4, var3, var3, var3, var3, var5, var1, var3, var1, var3],
        
        // 角度和弧度转换
        [NSString stringWithFormat:@"\nCGFloat %@ = 45.0;\nCGFloat %@ = %@ * M_PI / 180.0;\nCGFloat %@ = %@ * 180.0 / M_PI;\nCGFloat %@ = sin(%@);\nCGFloat %@ = cos(%@);\nCGPoint %@ = CGPointMake(cos(%@) * 50.0, sin(%@) * 50.0);",
         var1, var2, var1, var3, var2, var4, var2, var5, var2, var6, var2, var2],
        
        // 数学常数运算
        [NSString stringWithFormat:@"\nCGFloat %@ = M_PI;\nCGFloat %@ = M_E;\nCGFloat %@ = M_LN2;\nCGFloat %@ = M_SQRT2;\nCGFloat %@ = %@ + %@ + %@ + %@;\nCGFloat %@ = %@ * %@ / %@;",
         var1, var2, var3, var4, var5, var1, var2, var3, var4, var6, var1, var2, var3],
        
        // 比例和缩放计算
        [NSString stringWithFormat:@"\nCGSize %@ = CGSizeMake(100, 50);\nCGFloat %@ = 1.5;\nCGSize %@ = CGSizeMake(%@.width * %@, %@.height * %@);\nCGFloat %@ = %@.width / %@.height;\nCGSize %@ = CGSizeMake(%@.width * 0.8, %@.height * 1.2);",
         var1, var2, var3, var1, var2, var1, var2, var4, var3, var3, var5, var3, var3],
        
        // 边界和插图计算
        [NSString stringWithFormat:@"\nCGRect %@ = CGRectMake(0, 0, 200, 150);\nUIEdgeInsets %@ = UIEdgeInsetsMake(10, 15, 20, 25);\nCGRect %@ = UIEdgeInsetsInsetRect(%@, %@);\nCGFloat %@ = %@.origin.x + %@.size.width;\nCGFloat %@ = %@.origin.y + %@.size.height;",
         var1, var2, var3, var1, var2, var4, var3, var3, var5, var3, var3],
        
        // 复杂随机分布
        [NSString stringWithFormat:@"\nCGFloat %@ = (CGFloat)arc4random_uniform(1000) / 1000.0;\nCGFloat %@ = (CGFloat)arc4random_uniform(500) / 100.0;\nCGFloat %@ = %@ * 2.0 * M_PI;\nCGPoint %@ = CGPointMake(cos(%@) * %@, sin(%@) * %@);\nCGFloat %@ = atan2(%@.y, %@.x);",
         var1, var2, var3, var1, var4, var3, var2, var3, var2, var5, var4, var4],
        

        // 几何路径计算
        [NSString stringWithFormat:@"\nCGMutablePathRef %@ = CGPathCreateMutable();\nCGPathMoveToPoint(%@, NULL, 0, 0);\nCGPathAddLineToPoint(%@, NULL, 100, 0);\nCGPathAddLineToPoint(%@, NULL, 100, 50);\nCGPathAddLineToPoint(%@, NULL, 0, 50);\nCGPathCloseSubpath(%@);\nCGRect %@ = CGPathGetBoundingBox(%@);\nCGPathRelease(%@);",
         var1, var1, var1, var1, var1, var1, var2, var1, var1],
        
        // 矩阵分解
        [NSString stringWithFormat:@"\nCGAffineTransform %@ = CGAffineTransformMakeRotation(M_PI_4);\nCGFloat %@ = %@.a;\nCGFloat %@ = %@.b;\nCGFloat %@ = %@.c;\nCGFloat %@ = %@.d;\nCGFloat %@ = %@.tx;\nCGFloat %@ = %@.ty;\nCGFloat %@ = %@ * %@ - %@ * %@;",
         var1, var2, var1, var3, var1, var4, var1, var5, var1, var6, var1, var7, var1, var8, var2, var5, var3, var4],
        
        // 复杂数学函数组合
        [NSString stringWithFormat:@"\nCGFloat %@ = 2.0;\nCGFloat %@ = pow(%@, 3.0);\nCGFloat %@ = exp(%@);\nCGFloat %@ = log(%@);\nCGFloat %@ = sin(%@) + cos(%@);\nCGFloat %@ = atan2(%@, %@);",
         var1, var2, var1, var3, var1, var4, var3, var5, var1, var1, var6, var2, var3],
        
        // 物理模拟计算
        [NSString stringWithFormat:@"\nCGFloat %@ = 9.8;\nCGFloat %@ = 2.0;\nCGFloat %@ = 0.5 * %@ * %@ * %@;\nCGFloat %@ = %@ * %@;\nCGPoint %@ = CGPointMake(%@ * cos(M_PI_4), %@ * sin(M_PI_4) - %@);",
         var1, var2, var3, var1, var2, var2, var4, var1, var2, var5, var4, var4, var1],
        
        // 插值计算
        [NSString stringWithFormat:@"\nCGFloat %@ = 0.0;\nCGFloat %@ = 1.0;\nCGFloat %@ = 0.3;\nCGFloat %@ = %@ + (%@ - %@) * %@;\nCGPoint %@ = CGPointMake(0, 0);\nCGPoint %@ = CGPointMake(100, 50);\nCGPoint %@ = CGPointMake(%@.x + (%@.x - %@.x) * %@, %@.y + (%@.y - %@.y) * %@);",
         var1, var2, var3, var4, var1, var2, var1, var3, var5, var6, var7, var5, var6, var5, var3, var5, var6, var5, var3]
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateAsyncOperationsWithIndent:(NSString *)indent {
    NSString *var1 = [self generateRandomVariableName];
    NSString *var2 = [self generateRandomVariableName];
    NSString *var3 = [self generateRandomVariableName];
    NSString *var4 = [self generateRandomVariableName];
    NSString *var5 = [self generateRandomVariableName];
    NSString *var6 = [self generateRandomVariableName];
 
    NSArray *templates = @[
        // 基础异步操作
        [NSString stringWithFormat:@"\ndispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{\n    CGRect %@ = CGRectMake(0, 0, 100, 50);\n    CGAffineTransform %@ = CGAffineTransformIdentity;\n    dispatch_async(dispatch_get_main_queue(), ^{\n        CGRect %@ = %@;\n        CGAffineTransform %@ = %@;\n    });\n});",
         var1, var2, var3, var1, var4, var2],
        
        
        // 一次性操作
        [NSString stringWithFormat:@"\nstatic dispatch_once_t %@;\ndispatch_once(&%@, ^{\n    CGFloat %@ = M_E;\n    CGRect %@ = CGRectMake(0, 0, %@ * 50, %@ * 25);\n});",
         var1, var1, var2, var3, var2, var2],
        
        // 屏障异步操作
        [NSString stringWithFormat:@"\ndispatch_queue_t %@ = dispatch_queue_create(\"custom.queue\", DISPATCH_QUEUE_CONCURRENT);\ndispatch_async(%@, ^{\n    CGFloat %@ = 3.14;\n});\ndispatch_barrier_async(%@, ^{\n    CGFloat %@ = 2.71;\n});",
         var1, var1, var2, var1, var3],
        
        // 延迟执行
        [NSString stringWithFormat:@"\ndispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{\n    CGRect %@ = CGRectMake(0, 0, 200, 100);\n    CGAffineTransform %@ = CGAffineTransformMakeScale(1.1, 1.1);\n});",
         var1, var2],
        
        // 多个队列的异步操作
        [NSString stringWithFormat:@"\ndispatch_queue_t %@ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);\ndispatch_queue_t %@ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);\ndispatch_async(%@, ^{\n    CGFloat %@ = M_PI_2;\n});\ndispatch_async(%@, ^{\n    CGFloat %@ = M_PI_4;\n});",
         var1, var2, var1, var3, var2, var4],
        
        // 信号量控制
        [NSString stringWithFormat:@"\ndispatch_semaphore_t %@ = dispatch_semaphore_create(1);\ndispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{\n    dispatch_semaphore_wait(%@, DISPATCH_TIME_FOREVER);\n    CGRect %@ = CGRectMake(0, 0, 100, 50);\n    dispatch_semaphore_signal(%@);\n});",
         var1, var1, var2, var1],
        
        // 应用任务
        [NSString stringWithFormat:@"\n[[NSOperationQueue mainQueue] addOperationWithBlock:^{\n    CGRect %@ = CGRectMake(0, 0, 150, 75);\n    CGAffineTransform %@ = CGAffineTransformMakeRotation(M_PI_4);\n}];",
         var1, var2],
        
        // 自定义操作队列
        [NSString stringWithFormat:@"\nNSOperationQueue *%@ = [[NSOperationQueue alloc] init];\n%@.maxConcurrentOperationCount = 2;\n[%@ addOperationWithBlock:^{\n    CGFloat %@ = 3.14159;\n    CGRect %@ = CGRectMake(0, 0, %@ * 30.0, 50.0);\n}];",
         var1, var1, var1, var2, var3, var2],
        
        // 操作依赖
        [NSString stringWithFormat:@"\nNSBlockOperation *%@ = [NSBlockOperation blockOperationWithBlock:^{\n    CGFloat %@ = M_PI;\n}];\nNSBlockOperation *%@ = [NSBlockOperation blockOperationWithBlock:^{\n    CGFloat %@ = M_E;\n}];\n[%@ addDependency:%@];\nNSOperationQueue *%@ = [[NSOperationQueue alloc] init];\n[%@ addOperations:@[%@, %@] waitUntilFinished:NO];",
         var1, var2, var3, var4, var3, var1, var5, var5, var1, var3],
        
        // 定时器调度
        [NSString stringWithFormat:@"\ndispatch_source_t %@ = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());\ndispatch_source_set_timer(%@, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);\ndispatch_source_set_event_handler(%@, ^{\n    static int %@ = 0;\n    CGRect %@ = CGRectMake(0, 0, 50 + %@ * 10, 50);\n    %@++;\n});\ndispatch_resume(%@);",
         var1, var1, var1, var2, var3, var2, var2, var1],
        
        // I/O 异步操作
        [NSString stringWithFormat:@"\ndispatch_io_t %@ = dispatch_io_create_with_path(DISPATCH_IO_STREAM, \"/tmp/test.file\", O_RDONLY, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(int error) {\n    CGRect %@ = CGRectMake(0, 0, 100, 50);\n});",
         var1, var2],
        
        // 递归锁和异步
        [NSString stringWithFormat:@"\nNSRecursiveLock *%@ = [[NSRecursiveLock alloc] init];\ndispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{\n    [%@ lock];\n    CGRect %@ = CGRectMake(0, 0, 120, 60);\n    [%@ unlock];\n});",
         var1, var1, var2, var1],
        
        // 读写锁模式
        [NSString stringWithFormat:@"\ndispatch_queue_t %@ = dispatch_queue_create(\"read.write.queue\", DISPATCH_QUEUE_CONCURRENT);\n__block CGRect %@ = CGRectZero;\ndispatch_barrier_async(%@, ^{\n    %@ = CGRectMake(0, 0, 100, 50);\n});\ndispatch_sync(%@, ^{\n    CGRect %@ = %@;\n});",
         var1, var2, var1, var2, var1, var3, var2],
        
        // 异步迭代
        [NSString stringWithFormat:@"\ndispatch_apply(5, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t index) {\n    CGRect %@ = CGRectMake(index * 30.0, 0, 25.0, 25.0);\n    CGAffineTransform %@ = CGAffineTransformMakeRotation((CGFloat)index * M_PI_4);\n});",
         var1, var2],
        
        // 操作取消
        [NSString stringWithFormat:@"\nNSBlockOperation *%@ = [NSBlockOperation blockOperationWithBlock:^{\n    for (int i = 0; i < 10 && !%@.isCancelled; i++) {\n        CGRect %@ = CGRectMake(i * 20.0, 0, 15.0, 15.0);\n    }\n}];\nNSOperationQueue *%@ = [[NSOperationQueue alloc] init];\n[%@ addOperation:%@];",
         var1, var1, var2, var3, var3, var1],
        
        // 优先级操作
        [NSString stringWithFormat:@"\nNSOperationQueue *%@ = [[NSOperationQueue alloc] init];\nNSBlockOperation *%@ = [NSBlockOperation blockOperationWithBlock:^{\n    CGRect %@ = CGRectMake(0, 0, 100, 50);\n}];\n%@.queuePriority = NSOperationQueuePriorityHigh;\n[%@ addOperation:%@];",
         var1, var2, var3, var2, var1, var2],
        
        // 异步等待
        [NSString stringWithFormat:@"\ndispatch_group_t %@ = dispatch_group_create();\ndispatch_group_async(%@, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{\n    CGRect %@ = CGRectMake(0, 0, 80, 40);\n});\ndispatch_time_t %@ = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC));\nlong %@ = dispatch_group_wait(%@, %@);",
         var1, var1, var2, var3, var4, var1, var3],
        
        // 源事件
        [NSString stringWithFormat:@"\ndispatch_source_t %@ = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());\ndispatch_source_set_event_handler(%@, ^{\n    CGRect %@ = CGRectMake(0, 0, 100, 50);\n});\ndispatch_resume(%@);\ndispatch_source_merge_data(%@, 1);",
         var1, var1, var2, var1, var1],
        
        // 自定义调度目标
        [NSString stringWithFormat:@"\ndispatch_queue_t %@ = dispatch_queue_create(\"custom.target.queue\", DISPATCH_QUEUE_SERIAL);\ndispatch_set_target_queue(%@, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));\ndispatch_async(%@, ^{\n    CGRect %@ = CGRectMake(0, 0, 90, 45);\n});",
         var1, var1, var1, var2],
        
        // 操作暂停和恢复
        [NSString stringWithFormat:@"\nNSOperationQueue *%@ = [[NSOperationQueue alloc] init];\n[%@ setSuspended:YES];\nNSBlockOperation *%@ = [NSBlockOperation blockOperationWithBlock:^{\n    CGRect %@ = CGRectMake(0, 0, 110, 55);\n}];\n[%@ addOperation:%@];\n[%@ setSuspended:NO];",
         var1, var1, var2, var3, var1, var2, var1],
        
        // 屏障和组组合
        [NSString stringWithFormat:@"\ndispatch_queue_t %@ = dispatch_queue_create(\"composite.queue\", DISPATCH_QUEUE_CONCURRENT);\ndispatch_group_t %@ = dispatch_group_create();\ndispatch_group_async(%@, %@, ^{\n    CGRect %@ = CGRectMake(0, 0, 100, 50);\n});\ndispatch_group_notify(%@, %@, ^{\n    dispatch_barrier_async(%@, ^{\n        CGAffineTransform %@ = CGAffineTransformIdentity;\n    });\n});",
         var1, var2, var2, var1, var3, var2, var1, var1, var4],
        
        // 信号量限制并发
        [NSString stringWithFormat:@"\ndispatch_semaphore_t %@ = dispatch_semaphore_create(2);\nfor (int i = 0; i < 5; i++) {\n    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{\n        dispatch_semaphore_wait(%@, DISPATCH_TIME_FOREVER);\n        CGRect %@ = CGRectMake(i * 25.0, 0, 20.0, 20.0);\n        dispatch_semaphore_signal(%@);\n    });\n}",
         var1, var1, var2, var1],
        
        // 异步性能测试
        [NSString stringWithFormat:@"\nCFAbsoluteTime %@ = CFAbsoluteTimeGetCurrent();\ndispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{\n    for (int i = 0; i < 1000; i++) {\n        CGRect %@ = CGRectMake(0, 0, i, i);\n    }\n    CFAbsoluteTime %@ = CFAbsoluteTimeGetCurrent() - %@;\n    dispatch_async(dispatch_get_main_queue(), ^{\n        CGRect %@ = CGRectMake(0, 0, %@ * 1000.0, 50.0);\n    });\n});",
         var1, var2, var3, var1, var4, var3],
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateUtilityOperationsWithIndent:(NSString *)indent {
    NSString *var1 = [self generateRandomVariableName];
    NSString *var2 = [self generateRandomVariableName];
    NSString *var3 = [self generateRandomVariableName];
    NSString *var4 = [self generateRandomVariableName];
    NSString *var5 = [self generateRandomVariableName];
    NSString *var6 = [self generateRandomVariableName];
    NSString *var7 = [self generateRandomVariableName];
    NSString *var8 = [self generateRandomVariableName];
    
    NSArray *templates = @[
        // NSUserDefaults 操作
        [NSString stringWithFormat:@"\nNSUserDefaults *%@ = [NSUserDefaults standardUserDefaults];\n[%@ setFloat:M_PI forKey:@\"saved_constant\"];\n[%@ setBool:YES forKey:@\"configuration_flag\"];\nCGFloat %@ = [%@ floatForKey:@\"saved_constant\"];\nBOOL %@ = [%@ boolForKey:@\"configuration_flag\"];",
         var1, var1, var1, var2, var1, var3, var1],
        
        // 文件管理器操作
        [NSString stringWithFormat:@"\nNSFileManager *%@ = [NSFileManager defaultManager];\nNSString *%@ = NSTemporaryDirectory();\nNSString *%@ = [%@ stringByAppendingPathComponent:@\"temp.data\"];\nBOOL %@ = [%@ fileExistsAtPath:%@];\nNSDictionary *%@ = %@ ? [%@ attributesOfItemAtPath:%@ error:NULL] : @{};",
         var1, var2, var3, var2, var4, var1, var3, var5, var4, var1, var3],
        
        // Bundle 操作
        [NSString stringWithFormat:@"\nNSBundle *%@ = [NSBundle mainBundle];\nNSString *%@ = %@.bundleIdentifier;\nNSDictionary *%@ = %@.infoDictionary;\nNSString *%@ = %@[@\"CFBundleShortVersionString\"];\nNSString *%@ = %@[(@\"CFBundleVersion\")];",
         var1, var2, var1, var3, var1, var4, var3, var5, var3],
        
        // 进程信息
        [NSString stringWithFormat:@"\nNSProcessInfo *%@ = [NSProcessInfo processInfo];\nNSUInteger %@ = %@.processorCount;\nNSUInteger %@ = %@.activeProcessorCount;\nNSTimeInterval %@ = %@.systemUptime;\nNSString *%@ = %@.processName;",
         var1, var2, var1, var3, var1, var4, var1, var5, var1],
        
        // 通知中心
        [NSString stringWithFormat:@"\nNSNotificationCenter *%@ = [NSNotificationCenter defaultCenter];\n[%@ addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *%@) {\n    CGRect %@ = CGRectMake(0, 0, 100, 50);\n}];\n[%@ postNotificationName:@\"CustomNotification\" object:nil];",
         var1, var1, var2, var3, var1],
        
        // 定时器操作
        [NSString stringWithFormat:@"\nNSTimer *%@ = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *%@) {\n    static NSUInteger %@ = 0;\n    CGRect %@ = CGRectMake(0, 0, 50 + %@ * 10, 50);\n    %@++;\n}];",
         var1, var2, var3, var4, var3, var3],
        
        // 日期和时间操作
        [NSString stringWithFormat:@"\nNSDate *%@ = [NSDate date];\nNSDateFormatter *%@ = [[NSDateFormatter alloc] init];\n%@.dateFormat = @\"yyyy-MM-dd HH:mm:ss\";\nNSString *%@ = [%@ stringFromDate:%@];\nNSDate *%@ = [%@ dateByAddingTimeInterval:3600.0];",
         var1, var2, var2, var3, var2, var1, var4, var1],
        
        // 日历操作
        [NSString stringWithFormat:@"\nNSCalendar *%@ = [NSCalendar currentCalendar];\nNSDateComponents *%@ = [%@ components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:[NSDate date]];\nNSInteger %@ = %@.year;\nNSInteger %@ = %@.month;\nNSInteger %@ = %@.day;",
         var1, var2, var1, var3, var2, var4, var2, var5, var2],
        
        // 时区操作
        [NSString stringWithFormat:@"\nNSTimeZone *%@ = [NSTimeZone systemTimeZone];\nNSString *%@ = %@.name;\nNSInteger %@ = %@.secondsFromGMT;\nNSTimeZone *%@ = [NSTimeZone timeZoneWithName:@\"America/New_York\"];",
         var1, var2, var1, var3, var1, var4],
        
        // 语言环境
        [NSString stringWithFormat:@"\nNSLocale *%@ = [NSLocale currentLocale];\nNSString *%@ = [%@ displayNameForKey:NSLocaleIdentifier value:%@.localeIdentifier];\nNSString *%@ = [%@ objectForKey:NSLocaleCountryCode];\nNSString *%@ = [%@ objectForKey:NSLocaleLanguageCode];",
         var1, var2, var1, var1, var3, var1, var4, var1],
        
        // URL 会话和请求
        [NSString stringWithFormat:@"\nNSURL *%@ = [NSURL URLWithString:@\"https://api.example.com/data\"];\nNSURLRequest *%@ = [NSURLRequest requestWithURL:%@];\nNSURLSession *%@ = [NSURLSession sharedSession];\nNSURLSessionDataTask *%@ = [%@ dataTaskWithRequest:%@ completionHandler:^(NSData *%@, NSURLResponse *%@, NSError *%@) {\n    if (!%@) {\n        CGRect %@ = CGRectMake(0, 0, 100, 50);\n    }\n}];\n[%@ resume];",
         var1, var2, var1, var3, var4, var3, var2, var5, var6, var7, var7, var8, var4],
        
        // JSON 序列化
        [NSString stringWithFormat:@"\nNSDictionary *%@ = @{@\"key\": @\"value\", @\"number\": @42, @\"array\": @[@1, @2, @3]};\nNSError *%@;\nNSData *%@ = [NSJSONSerialization dataWithJSONObject:%@ options:0 error:&%@];\nNSDictionary *%@ = [NSJSONSerialization JSONObjectWithData:%@ options:0 error:NULL];",
         var1, var2, var3, var1, var2, var4, var3],
        
        // 属性列表操作
        [NSString stringWithFormat:@"\nNSDictionary *%@ = @{@\"setting1\": @YES, @\"setting2\": @\"text\", @\"setting3\": @3.14};\nNSData *%@ = [NSPropertyListSerialization dataWithPropertyList:%@ format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL];\nNSDictionary *%@ = [NSPropertyListSerialization propertyListWithData:%@ options:0 format:NULL error:NULL];",
         var1, var2, var1, var3, var2],
        
   
        
        // 归档和解档
        [NSString stringWithFormat:@"\nNSMutableData *%@ = [NSMutableData data];\nNSKeyedArchiver *%@ = [[NSKeyedArchiver alloc] initForWritingWithMutableData:%@];\n[%@ encodeCGRect:CGRectMake(0, 0, 100, 50) forKey:@\"rect\"];\n[%@ finishEncoding];\nNSKeyedUnarchiver *%@ = [[NSKeyedUnarchiver alloc] initForReadingWithData:%@];\nCGRect %@ = [%@ decodeCGRectForKey:@\"rect\"];",
         var1, var2, var1, var2, var2, var3, var1, var4, var3],
        
        // 谓词操作
        [NSString stringWithFormat:@"\nNSArray *%@ = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];\nNSPredicate *%@ = [NSPredicate predicateWithFormat:@\"self > 5\"];\nNSArray *%@ = [%@ filteredArrayUsingPredicate:%@];\nNSPredicate *%@ = [NSPredicate predicateWithFormat:@\"self BETWEEN {2, 8}\"];\nNSArray *%@ = [%@ filteredArrayUsingPredicate:%@];",
         var1, var2, var3, var1, var2, var4, var5, var1, var4],
        
        // 排序描述符
        [NSString stringWithFormat:@"\nNSArray *%@ = @[@\"banana\", @\"apple\", @\"cherry\", @\"date\"];\nNSSortDescriptor *%@ = [NSSortDescriptor sortDescriptorWithKey:@\"self\" ascending:YES];\nNSArray *%@ = [%@ sortedArrayUsingDescriptors:@[%@]];\nNSSortDescriptor *%@ = [NSSortDescriptor sortDescriptorWithKey:@\"length\" ascending:NO];\nNSArray *%@ = [%@ sortedArrayUsingDescriptors:@[%@]];",
         var1, var2, var3, var1, var2, var4, var5, var1, var4],
        
        // 表达式求值
        [NSString stringWithFormat:@"\nNSExpression *%@ = [NSExpression expressionWithFormat:@\"3 + 4 * 2\"];\nid %@ = [%@ expressionValueWithObject:nil context:nil];\nNSExpression *%@ = [NSExpression expressionForFunction:@\"average:\" arguments:@[[NSExpression expressionForConstantValue:@[@1, @2, @3, @4, @5]]]];\nid %@ = [%@ expressionValueWithObject:nil context:nil];",
         var1, var2, var1, var3, var4, var3],
        
        // 用户活动
        [NSString stringWithFormat:@"\nNSUserActivity *%@ = [[NSUserActivity alloc] initWithActivityType:@\"com.example.activity\"];\n%@.title = @\"Sample Activity\";\n%@.userInfo = @{@\"key\": @\"value\"};\n%@.eligibleForSearch = YES;\n%@.eligibleForHandoff = YES;",
         var1, var1, var1, var1, var1],
        
        // 粘贴板操作
        [NSString stringWithFormat:@"\nUIPasteboard *%@ = [UIPasteboard generalPasteboard];\n%@.string = @\"Copied Text\";\nNSString *%@ = %@.string;\nNSArray *%@ = %@.pasteboardTypes;\n%@.items = @[@{@\"public.text\": @\"Sample Data\"}];",
         var1, var1, var2, var1, var3, var1, var1],

        // 设备信息
        [NSString stringWithFormat:@"\nUIDevice *%@ = [UIDevice currentDevice];\nNSString *%@ = %@.systemName;\nNSString *%@ = %@.systemVersion;\nNSString *%@ = %@.model;\nBOOL %@ = %@.multitaskingSupported;",
         var1, var2, var1, var3, var1, var4, var1, var5, var1],
        

        // 自动释放池
        [NSString stringWithFormat:@"\n@autoreleasepool {\n    NSMutableArray *%@ = [NSMutableArray array];\n    for (int i = 0; i < 100; i++) {\n        NSString *%@ = [NSString stringWithFormat:@\"Item%%d\", i];\n        [%@ addObject:%@];\n    }\n    NSArray *%@ = [%@ copy];\n}",
         var1, var2, var1, var2, var3, var1],
        
        // 性能测量
        [NSString stringWithFormat:@"\nCFAbsoluteTime %@ = CFAbsoluteTimeGetCurrent();\nfor (int i = 0; i < 1000; i++) {\n    CGRect %@ = CGRectMake(0, 0, i, i);\n}\nCFAbsoluteTime %@ = CFAbsoluteTimeGetCurrent() - %@;\nNSLog(@\"Execution time: %%f seconds\", %@);",
         var1, var2, var3, var1, var3],
        

        // 错误处理
        [NSString stringWithFormat:@"\nNSError *%@;\nNSFileManager *%@ = [NSFileManager defaultManager];\nBOOL %@ = [%@ removeItemAtPath:@\"/invalid/path\" error:&%@];\nif (!%@) {\n    NSLog(@\"Error: %%@\", %@.localizedDescription);\n    CGRect %@ = CGRectMake(0, 0, 100, 50);\n}",
         var1, var2, var3, var2, var1, var3, var1, var4]
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
