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
        if (arc4random_uniform(100) < 60) {
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
        
        // 找到方法体的开始和结束位置
        NSRange openBraceRange = [methodContent rangeOfString:@"{"];
        NSRange closeBraceRange = [methodContent rangeOfString:@"}" options:NSBackwardsSearch];
        
        if (openBraceRange.location == NSNotFound || closeBraceRange.location == NSNotFound) {
            return NO;
        }
        
        // 计算方法体的实际范围
        NSUInteger bodyStart = openBraceRange.location + 1;
        NSUInteger bodyEnd = closeBraceRange.location;
        
        if (bodyStart >= bodyEnd) {
            return NO;
        }
        
        // 提取方法体
        NSString *methodBody = [methodContent substringWithRange:NSMakeRange(bodyStart, bodyEnd - bodyStart)];
        
        // 按行分割方法体
        NSArray *lines = [methodBody componentsSeparatedByString:@"\n"];
        if (lines.count <= 1) {
            return NO;
        }
        
        // 找到有效的代码行
        NSMutableArray *validLines = [NSMutableArray array];
        NSMutableArray *linePositions = [NSMutableArray array];
        
        NSUInteger currentPosition = bodyStart;
        for (NSString *line in lines) {
            NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            // 跳过空行、注释和特殊标记
            if (trimmedLine.length > 0 &&
                ![trimmedLine hasPrefix:@"//"] &&
                ![trimmedLine hasPrefix:@"/*"] &&
                ![trimmedLine hasPrefix:@"*"] &&
                ![trimmedLine isEqualToString:@"}"] &&
                ![trimmedLine hasSuffix:@"{"] &&
                ![trimmedLine hasPrefix:@"@"] &&
                ![trimmedLine hasPrefix:@"#"] &&
                ![trimmedLine hasPrefix:@"return"] && // 避免在return语句后插入
                ![trimmedLine hasPrefix:@"break"] && // 避免在break后插入
                ![trimmedLine hasPrefix:@"continue"] && // 避免在continue后插入
                ![trimmedLine hasPrefix:@"case"] && // 避免在case语句中插入
                ![trimmedLine hasPrefix:@"default"] && // 避免在default语句中插入
                ![trimmedLine containsString:@"switch"]) { // 避免在switch语句附近插入
                
                [validLines addObject:line];
                [linePositions addObject:@(currentPosition)];
            }
            currentPosition += line.length + 1; // +1 for newline
        }
        
        if (validLines.count == 0) {
            return NO;
        }
        
        // 随机选择插入位置
        NSUInteger randomIndex = arc4random_uniform((uint32_t)validLines.count);
        NSUInteger insertPosition = [linePositions[randomIndex] unsignedIntegerValue];
        
        // 获取当前行的缩进
        NSString *currentLine = validLines[randomIndex];
        NSString *indent = [self extractIndentFromLine:currentLine];
        
        // 生成随机代码（避免生成 switch 语句）
        NSString *randomCode = [self generateRandomCodeWithIndent:indent];
        
        // 在原始内容中的实际位置
        NSUInteger actualPosition = methodRange.location + insertPosition;
        
        // 插入随机代码
        [content insertString:randomCode atIndex:actualPosition];
        
        NSLog(@"📝 在方法中插入随机代码: %@", [randomCode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]);
        
        return YES;
        
    } @catch (NSException *exception) {
        NSLog(@"❌ 插入随机代码失败: %@", exception);
        return NO;
    }
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

+ (NSString *)extractIndentFromLine:(NSString *)line {
    NSUInteger indentLength = 0;
    for (NSUInteger i = 0; i < line.length; i++) {
        unichar ch = [line characterAtIndex:i];
        if (ch == ' ' || ch == '\t') {
            indentLength++;
        } else {
            break;
        }
    }
    return [line substringToIndex:indentLength];
}


#pragma mark - 随机代码生成器（修复格式化崩溃问题）

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

+ (NSString *)generateVariableOperationsWithIndent:(NSString *)indent {
    NSArray *templates = @[
        // 基本变量操作
        @"CGFloat tempValue = M_PI * 2.0;\nUIView *containerView = [[UIView alloc] init];\ncontainerView.alpha = tempValue / 10.0;",
        
        @"NSInteger iterationCount = 5;\nBOOL shouldProcess = YES;\nCGFloat scaleFactor = 1.5;\nCGRect viewFrame = CGRectMake(0, 0, 100 * scaleFactor, 50 * scaleFactor);",
        
        @"id temporaryObject = nil;\nClass targetClass = [NSString class];\nSEL actionSelector = @selector(length);\nProtocol *dataProtocol = @protocol(NSCopying);",
        
        @"NSUInteger itemCount = 10;\nCGFloat padding = 8.0;\nCGSize elementSize = CGSizeMake(44.0, 44.0);\nCGFloat totalWidth = itemCount * (elementSize.width + padding);",
        
        @"BOOL isVertical = YES;\nBOOL hasContent = NO;\nBOOL needsLayout = YES;\nUIEdgeInsets contentInset = UIEdgeInsetsMake(10, 10, 10, 10);"
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateControlFlowWithIndent:(NSString *)indent {
    NSArray *templates = @[
        // 条件语句
        @"if (YES) {\n    CGFloat calculatedValue = M_E * 2.0;\n    CGRect tempRect = CGRectMake(0, 0, calculatedValue, calculatedValue);\n}",
        
        @"for (NSUInteger index = 0; index < 3; index++) {\n    CGFloat progress = (CGFloat)index / 3.0;\n    CGPoint position = CGPointMake(progress * 100.0, progress * 50.0);\n}",
        
        @"NSUInteger counter = 0;\nwhile (counter < 2) {\n    CGFloat angle = (CGFloat)counter * M_PI_4;\n    CGAffineTransform rotation = CGAffineTransformMakeRotation(angle);\n    counter++;\n}",
        
        @"BOOL conditionA = YES;\nBOOL conditionB = NO;\nif (conditionA && !conditionB) {\n    CGFloat blendValue = 0.7;\n    UIColor *blendedColor = [UIColor colorWithWhite:blendValue alpha:1.0];\n}",
        
        @"do {\n    CGAffineTransform identity = CGAffineTransformIdentity;\n    CGFloat scale = 1.2;\n    CGAffineTransform scaled = CGAffineTransformScale(identity, scale, scale);\n} while (NO);"
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateDataStructuresWithIndent:(NSString *)indent {
    NSArray *templates = @[
        // 数组操作
        @"NSMutableArray *collection = [NSMutableArray array];\n[collection addObject:[NSValue valueWithCGRect:CGRectMake(0, 0, 50, 50)]];\n[collection addObject:[NSValue valueWithCGPoint:CGPointMake(10, 10)]];\n[collection addObject:[NSValue valueWithCGAffineTransform:CGAffineTransformIdentity]];",
        
        // 字典操作
        @"NSMutableDictionary *configuration = [NSMutableDictionary dictionary];\nconfiguration[@\"scale\"] = @(1.5);\nconfiguration[@\"duration\"] = @(0.3);\nconfiguration[@\"opacity\"] = @(0.8);\nCGSize configuredSize = CGSizeMake(100 * [configuration[@\"scale\"] floatValue], 100);",
        
        // 集合操作
        @"NSMutableSet *uniqueItems = [NSMutableSet set];\n[uniqueItems addObject:@(M_PI)];\n[uniqueItems addObject:@(M_E)];\n[uniqueItems addObject:@(M_LN2)];\nNSUInteger uniqueCount = uniqueItems.count;",
        
        // 排序操作
        @"NSArray *values = @[@(3.14), @(2.71), @(1.41), @(1.61)];\nNSArray *sortedValues = [values sortedArrayUsingComparator:^NSComparisonResult(NSNumber *a, NSNumber *b) {\n    return [a compare:b];\n}];\nCGFloat firstValue = [sortedValues.firstObject floatValue];",
        
        // 过滤操作
        @"NSArray *sourceArray = @[@(10), @(20), @(30), @(40)];\nNSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@\"self > 25\"];\nNSArray *filteredArray = [sourceArray filteredArrayUsingPredicate:filterPredicate];\nCGFloat filteredSum = 0;\nfor (NSNumber *number in filteredArray) {\n    filteredSum += [number floatValue];\n}"
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateObjectOperationsWithIndent:(NSString *)indent {
    NSArray *templates = @[
        // UIView 操作
        @"UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];\ncontentView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];\ncontentView.layer.cornerRadius = 8.0;\ncontentView.layer.borderWidth = 1.0;\ncontentView.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;",
        
        // 颜色操作
        @"CGFloat redComponent = 0.2;\nCGFloat greenComponent = 0.4;\nCGFloat blueComponent = 0.6;\nUIColor *customColor = [UIColor colorWithRed:redComponent green:greenComponent blue:blueComponent alpha:1.0];\nCGColorRef colorRef = customColor.CGColor;",
        
        // 变换操作
        @"CGAffineTransform baseTransform = CGAffineTransformIdentity;\nCGAffineTransform scaledTransform = CGAffineTransformScale(baseTransform, 1.2, 0.8);\nCGAffineTransform rotatedTransform = CGAffineTransformRotate(scaledTransform, M_PI_4);\nCGAffineTransform translatedTransform = CGAffineTransformTranslate(rotatedTransform, 10, 5);",
        
        // 图层操作
        @"CALayer *contentLayer = [CALayer layer];\ncontentLayer.frame = CGRectMake(0, 0, 100, 50);\ncontentLayer.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;\ncontentLayer.cornerRadius = 4.0;\ncontentLayer.shadowOpacity = 0.2;",
        
        // 动画操作
        @"[UIView animateWithDuration:0.25 animations:^{\n    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(1.1, 1.1);\n    CGAffineTransform currentTransform = scaleTransform;\n} completion:^(BOOL finished) {\n    CGAffineTransform identityTransform = CGAffineTransformIdentity;\n}];"
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateStringOperationsWithIndent:(NSString *)indent {
    NSArray *templates = @[
        // 字符串构建
        @"NSString *baseString = @\"Content\";\nNSString *suffixString = @\"Data\";\nNSString *combinedString = [baseString stringByAppendingString:suffixString];\nNSUInteger stringLength = combinedString.length;\nNSRange fullRange = NSMakeRange(0, stringLength);",
        
        // 字符串处理
        @"NSString *sourceText = @\"SampleText\";\nNSString *uppercaseVersion = [sourceText uppercaseString];\nNSString *lowercaseVersion = [sourceText lowercaseString];\nNSString *capitalizedVersion = [sourceText capitalizedString];\nNSComparisonResult comparison = [uppercaseVersion compare:lowercaseVersion];",
        
        // 路径操作
        @"NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;\nNSString *filePath = [documentsPath stringByAppendingPathComponent:@\"data.file\"];\nNSString *fileExtension = [filePath pathExtension];\nNSString *fileName = [filePath lastPathComponent];\nNSString *directoryPath = [filePath stringByDeletingLastPathComponent];",
        
        // 格式化字符串
        @"CGFloat widthValue = 120.5;\nCGFloat heightValue = 80.25;\nNSString *sizeDescription = [NSString stringWithFormat:@\"%.1fx%.1f\", widthValue, heightValue];\nCGSize describedSize = CGSizeMake(widthValue, heightValue);",
        
        // 字符串分析
        @"NSString *testString = @\"ABCDEFG\";\nNSRange searchRange = NSMakeRange(0, testString.length);\nNSRange foundRange = [testString rangeOfString:@\"CDE\" options:0 range:searchRange];\nBOOL containsSubstring = foundRange.location != NSNotFound;\nNSString *substring = containsSubstring ? [testString substringWithRange:foundRange] : @\"\";"
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateMathematicalOperationsWithIndent:(NSString *)indent {
    NSArray *templates = @[
        // 几何计算
        @"CGRect containerRect = CGRectMake(0, 0, 200, 100);\nCGRect innerRect = CGRectInset(containerRect, 10, 5);\nCGRect offsetRect = CGRectOffset(innerRect, 5, 2);\nCGRect unionRect = CGRectUnion(containerRect, offsetRect);\nCGRect intersectionRect = CGRectIntersection(containerRect, offsetRect);",
        
        // 数学计算
        @"CGFloat baseValue = M_PI;\nCGFloat squaredValue = baseValue * baseValue;\nCGFloat squareRoot = sqrt(squaredValue);\nCGFloat cosineValue = cos(baseValue);\nCGFloat sineValue = sin(baseValue);\nCGFloat tangentValue = tan(baseValue);",
        
        // 点线计算
        @"CGPoint startPoint = CGPointMake(0, 0);\nCGPoint endPoint = CGPointMake(100, 50);\nCGFloat distance = hypot(endPoint.x - startPoint.x, endPoint.y - startPoint.y);\nCGPoint midPoint = CGPointMake((startPoint.x + endPoint.x) / 2, (startPoint.y + endPoint.y) / 2);\nCGVector directionVector = CGVectorMake(endPoint.x - startPoint.x, endPoint.y - startPoint.y);",
        
        // 矩阵计算
        @"CGFloat matrix[9] = {1, 0, 0, 0, 1, 0, 0, 0, 1};\nCGAffineTransform transformMatrix = CGAffineTransformMake(matrix[0], matrix[1], matrix[3], matrix[4], matrix[6], matrix[7]);\nBOOL isIdentity = CGAffineTransformIsIdentity(transformMatrix);\nCGAffineTransform invertedMatrix = CGAffineTransformInvert(transformMatrix);",
        
        // 数值处理
        @"CGFloat values[5] = {1.5, 2.3, 3.7, 4.1, 5.9};\nCGFloat sum = 0;\nCGFloat average = 0;\nfor (NSUInteger i = 0; i < 5; i++) {\n    sum += values[i];\n}\naverage = sum / 5;\nCGFloat normalizedValues[5];\nfor (NSUInteger i = 0; i < 5; i++) {\n    normalizedValues[i] = values[i] / sum;\n}"
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateAsyncOperationsWithIndent:(NSString *)indent {
    NSArray *templates = @[
        // GCD 操作
        @"dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{\n    CGRect tempRect = CGRectMake(0, 0, 100, 50);\n    CGAffineTransform tempTransform = CGAffineTransformIdentity;\n    dispatch_async(dispatch_get_main_queue(), ^{\n        CGRect updatedRect = tempRect;\n        CGAffineTransform updatedTransform = tempTransform;\n    });\n});",
        
        // 延迟执行
        @"dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{\n    CGPoint targetPoint = CGPointMake(50, 25);\n    CGSize targetSize = CGSizeMake(100, 50);\n    CGRect targetRect = CGRectMake(targetPoint.x, targetPoint.y, targetSize.width, targetSize.height);\n});",
        
        // 组操作
        @"dispatch_group_t processGroup = dispatch_group_create();\ndispatch_group_enter(processGroup);\nCGFloat processedValue = M_PI;\ndispatch_group_leave(processGroup);\ndispatch_group_notify(processGroup, dispatch_get_main_queue(), ^{\n    CGFloat finalValue = processedValue;\n});",
        
        // 一次性操作
        @"static dispatch_once_t onceToken;\ndispatch_once(&onceToken, ^{\n    CGFloat initializedValue = M_E;\n    CGRect initializedRect = CGRectMake(0, 0, initializedValue * 50, initializedValue * 25);\n});",
        
        // 屏障操作
        @"dispatch_queue_t customQueue = dispatch_queue_create(\"custom.queue\", DISPATCH_QUEUE_CONCURRENT);\ndispatch_async(customQueue, ^{\n    CGFloat readValue = 3.14;\n});\ndispatch_barrier_async(customQueue, ^{\n    CGFloat writeValue = 2.71;\n});"
    ];
    
    NSString *template = templates[arc4random_uniform((uint32_t)templates.count)];
    return [self applyIndent:indent toCode:template];
}

+ (NSString *)generateUtilityOperationsWithIndent:(NSString *)indent {
    NSArray *templates = @[
        // 文件操作
        @"NSFileManager *fileManager = [NSFileManager defaultManager];\nNSString *tempDirectory = NSTemporaryDirectory();\nNSString *tempFilePath = [tempDirectory stringByAppendingPathComponent:@\"temp.data\"];\nBOOL fileExists = [fileManager fileExistsAtPath:tempFilePath];\nNSDictionary *fileAttributes = fileExists ? [fileManager attributesOfItemAtPath:tempFilePath error:NULL] : @{};",
        
        // 用户默认值
        @"NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];\n[userDefaults setFloat:M_PI forKey:@\"saved_constant\"];\n[userDefaults setBool:YES forKey:@\"configuration_flag\"];\nCGFloat retrievedValue = [userDefaults floatForKey:@\"saved_constant\"];\nBOOL retrievedFlag = [userDefaults boolForKey:@\"configuration_flag\"];",
        
        // 包操作
        @"NSBundle *mainBundle = [NSBundle mainBundle];\nNSString *bundleIdentifier = mainBundle.bundleIdentifier;\nNSDictionary *bundleInfo = mainBundle.infoDictionary;\nNSString *bundleVersion = bundleInfo[@\"CFBundleShortVersionString\"];\nNSString *bundleBuild = bundleInfo[(@\"CFBundleVersion\")];",
        
        // 进程信息
        @"NSProcessInfo *processInfo = [NSProcessInfo processInfo];\nNSUInteger processorCount = processInfo.processorCount;\nNSUInteger activeProcessorCount = processInfo.activeProcessorCount;\nNSTimeInterval systemUptime = processInfo.systemUptime;\nNSString *processName = processInfo.processName;",
        
        // 本地化
        @"NSLocale *currentLocale = [NSLocale currentLocale];\nNSString *localeIdentifier = currentLocale.localeIdentifier;\nNSString *languageCode = currentLocale.languageCode;\nNSString *countryCode = currentLocale.countryCode;\nNSString *currencyCode = currentLocale.currencyCode;\nNSArray *availableLocales = [NSLocale availableLocaleIdentifiers];"
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
