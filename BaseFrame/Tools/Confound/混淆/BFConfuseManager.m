//
//  BFConfuseManager.m
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/1.
//

#import "BFConfuseManager.h"
#import "BFWordsRackTool.h"

@implementation BFConfuseManager

+ (id)searchDirectory:(NSString *)directory
           exceptDirs:(NSArray *)exceptDirs
         includeFiles:(NSArray *)includeFiles
         regexPattern:(NSString *)pattern returnPatten:(BOOL)returnPatten
               error:(NSError **)error {
    
    // 1. 验证目录有效性
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    if (![fileManager fileExistsAtPath:directory isDirectory:&isDirectory] || !isDirectory) {
        if (error) {
            *error = [NSError errorWithDomain:@"FileSearcherErrorDomain"
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid directory path"}];
        }
        return nil;
    }
    
    // 2. 准备文件扩展名过滤集合（小写）
    NSSet *fileExtensions = nil;
    if (includeFiles.count > 0) {
        NSMutableSet *extSet = [NSMutableSet set];
        for (NSString *ext in includeFiles) {
            [extSet addObject:[ext lowercaseString]];
        }
        fileExtensions = [extSet copy];
    }
    
    // 3. 编译正则表达式
    NSRegularExpression *regex = nil;
    if (pattern.length > 0) {
        NSError *regexError = nil;
        regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                         options:0
                                                           error:&regexError];
        if (regexError) {
            if (error) {
                *error = regexError;
            }
            return nil;
        }
    } else if (returnPatten) {
        // 如果要返回匹配内容但没提供正则表达式
        if (error) {
            *error = [NSError errorWithDomain:@"FileSearcherErrorDomain"
                                         code:1002
                                     userInfo:@{NSLocalizedDescriptionKey: @"Returning matched content requires a regex pattern"}];
        }
        return nil;
    }
    
    // 4. 遍历目录
    NSMutableArray *results = [NSMutableArray array];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directory];
    
    for (NSString *relativePath in enumerator) {
        // 检查是否在排除目录中 - 修复逻辑
        BOOL shouldSkip = NO;
        for (NSString *excludeDir in exceptDirs) {
            // 检查相对路径的任何部分是否包含排除目录
            NSArray *pathComponents = [relativePath pathComponents];
            for (NSString *component in pathComponents) {
                if ([component isEqualToString:excludeDir]) {
                    shouldSkip = YES;
                    [enumerator skipDescendants];
                    break;
                }
            }
            if (shouldSkip) break;
        }
        if (shouldSkip) continue;
        
        // 跳过.framework文件
        if ([relativePath hasSuffix:@".framework"] || [relativePath.pathExtension isEqualToString:@"framework"]) {
            [enumerator skipDescendants];
            continue;
        }
        
        NSString *fullPath = [directory stringByAppendingPathComponent:relativePath];
        BOOL isDir = NO;
        [fileManager fileExistsAtPath:fullPath isDirectory:&isDir];
        
        // 如果是目录，检查是否是.framework目录（双重检查）
        if (isDir && ([fullPath hasSuffix:@".framework"] || [relativePath hasSuffix:@".framework"])) {
            [enumerator skipDescendants];
            continue;
        }
        
        if (!isDir) {
            // 检查文件扩展名
            if (fileExtensions) {
                NSString *fileExt = [[relativePath pathExtension] lowercaseString];
                if (![fileExtensions containsObject:fileExt]) {
                    continue;
                }
            }
            
            // 如果不需要匹配内容且没有正则，直接添加路径
            if (!returnPatten && !regex) {
                [results addObject:fullPath];
                continue;
            }
            
            // 读取文件内容（只有在需要匹配内容或有正则时才读取）
            NSError *readError = nil;
            NSString *fileContent = [NSString stringWithContentsOfFile:fullPath
                                                            encoding:NSUTF8StringEncoding
                                                               error:&readError];
            
            if (readError) {
                NSLog(@"Failed to read file: %@, error: %@", fullPath, readError);
                continue;
            }
            
            if (regex) {
                // 获取所有匹配结果
                NSArray *matches = [regex matchesInString:fileContent
                                                options:0
                                                  range:NSMakeRange(0, fileContent.length)];
                
                if (matches.count > 0) {
                    if (returnPatten) {
                        // 只返回匹配的字符串
                        for (NSTextCheckingResult *match in matches) {
                            NSString *matchedString = [fileContent substringWithRange:match.range];
                            [results addObject:matchedString];
                        }
                    } else {
                        // 只返回文件路径
                        [results addObject:fullPath];
                    }
                }
            }
        }
    }
    
    return [results copy];
}


+ (NSArray *)searchAndProcessArray:(NSArray *)array withPrefixes:(NSArray<NSString *> *)prefixes {
    // 1. 过滤：只保留以任意prefix开头的字符串（如果prefixes不为空）
    NSArray *filtered = array;
    if (prefixes.count > 0) {
        NSMutableArray *predicates = [NSMutableArray array];
        for (NSString *prefix in prefixes) {
            [predicates addObject:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", prefix]];
        }
        NSPredicate *compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
        filtered = [array filteredArrayUsingPredicate:compoundPredicate];
    }
    
    // 2. 排序：将abcd排在abc前面
    NSArray *sorted = [filtered sortedArrayUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
        if ([str1 hasPrefix:str2] && str1.length > str2.length) {
            return NSOrderedAscending; // str1比str2长且以str2开头，str1排前面
        } else if ([str2 hasPrefix:str1] && str2.length > str1.length) {
            return NSOrderedDescending; // str2比str1长且以str1开头，str2排前面
        }
        return [str1 compare:str2]; // 默认字母顺序
    }];
    
    // 3. 去重
    NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:sorted];
    
    return [orderedSet array];
}


+ (NSArray<NSString *> *)splitClassName:(NSString *)className {
    if (className.length == 0) {
        return @[];
    }
    
    NSMutableArray *components = [NSMutableArray array];
    NSMutableString *currentWord = [NSMutableString string];
    BOOL hasUppercase = NO;
    BOOL hasLowercase = NO;
    
    for (NSInteger i = 0; i < className.length; i++) {
        unichar c = [className characterAtIndex:i];
        BOOL isUppercase = [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:c];
        BOOL isLowercase = [[NSCharacterSet lowercaseLetterCharacterSet] characterIsMember:c];
        
        if (isUppercase) {
            // 遇到大写字母时的处理
            if (hasLowercase) {
                // 如果已有小写字母，说明当前大写字母是新单词开始
                if (currentWord.length > 0) {
                    [components addObject:[currentWord copy]];
                    [currentWord setString:@""];
                    hasLowercase = NO;
                }
            }
            [currentWord appendFormat:@"%C", c];
            hasUppercase = YES;
        }
        else if (isLowercase) {
            // 遇到小写字母时的处理
            [currentWord appendFormat:@"%C", c];
            hasLowercase = YES;
        }
        else {
            // 非字母字符，重置状态
            if (currentWord.length > 0 && hasUppercase && hasLowercase) {
                [components addObject:[currentWord copy]];
            }
            [currentWord setString:@""];
            hasUppercase = NO;
            hasLowercase = NO;
        }
    }
    
    // 处理最后一个单词
    if (currentWord.length > 0 && hasUppercase && hasLowercase) {
        [components addObject:[currentWord copy]];
    }
    
    return components;
}

+ (NSArray<NSString *> *)splitClassNameList:(NSArray *)nameList{
    NSMutableSet *set = [NSMutableSet set];
    for (NSString *name in nameList) {
        [set addObjectsFromArray:[BFConfuseManager splitClassName:name]];
    }
    return set.allObjects;
}

+ (NSString *)readObfuscationMappingFileAtPath:(NSString *)basePath {
    return [self readObfuscationMappingFileAtPath:basePath name:@"文件名映射"];
}
    
+ (NSString *)readObfuscationMappingFileAtPath:(NSString *)basePath name:(NSString *)name{
    // 1. 构建完整文件路径
    NSString *mappingFilePath = [basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"混淆/%@",name]];
    
    // 2. 检查文件是否存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:mappingFilePath]) {
        NSLog(@"映射文件不存在: %@", mappingFilePath);
        return nil;
    }
    
    // 3. 读取文件内容（直接返回原始文本）
    NSError *error;
    NSString *fileContent = [NSString stringWithContentsOfFile:mappingFilePath
                                                     encoding:NSUTF8StringEncoding
                                                        error:&error];
    if (error || !fileContent) {
        NSLog(@"读取映射文件失败: %@", error.localizedDescription);
        return nil;
    }
    
    return fileContent; // 直接返回文件内容的字符串
}

+ (NSString *)word:(NSString *)word prefix:(NSString *)prefix replaceList:(NSArray *)replaceList exceptList:(NSArray *)exceptList replactDict:(NSDictionary *)replacrDict{
    if (word.length == 0) {
        return word;
    }
    
    NSArray *splitWords = [self splitClassName:word];
    
    NSMutableArray *result = [NSMutableArray array];
    NSArray *list = replacrDict.allKeys;
    for (NSString *wordString in splitWords) {
        if ([list containsObject:wordString]){
            [result addObject:replacrDict[wordString]];
        }else if ([exceptList containsObject:wordString]){
            [result addObject:wordString];
        }else{
            [result addObject:[self whiteWords:result replaceList:replaceList]];
        }
    }
    
    [result insertObject:prefix atIndex:0];
    return [result componentsJoinedByString:@""];
}

+ (NSDictionary *)wordList:(NSArray *)wordList prefix:(NSString *)prefix replaceList:(NSArray *)replaceList exceptList:(NSArray *)exceptList replactDict:(NSDictionary *)replacrDict{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSMutableArray *temp = [NSMutableArray array];
    for (NSString *word in wordList) {
        NSString *string = [self word:word prefix:prefix replaceList:replaceList exceptList:exceptList replactDict:replacrDict matchList:temp];
        [temp addObject:string];
        [dict setValue:string forKey:word];
    }
    return dict;
}

+ (NSString *)word:(NSString *)word prefix:(NSString *)prefix replaceList:(NSArray *)replaceList exceptList:(NSArray *)exceptList replactDict:(NSDictionary *)replacrDict matchList:(NSArray *)matchList{
    NSString *string = [self word:word prefix:prefix replaceList:replaceList exceptList:exceptList replactDict:replacrDict];
    if ([matchList containsObject:string]){
        return [self word:word prefix:prefix replaceList:replaceList exceptList:exceptList replactDict:replacrDict matchList:matchList];
    }else{
        return string;
    }
}

+ (NSString *)whiteWords:(NSArray *)whiteWords replaceList:(NSArray *)replaceList{
    NSString *randomElement = [self randomWord:replaceList];
    if ([whiteWords containsObject:randomElement]){
        return [self whiteWords:whiteWords replaceList:replaceList];
    }else{
        return randomElement;
    }
}

+ (NSString *)randomWord:(NSArray *)array{
    return array[arc4random_uniform((uint32_t)array.count)];
}

+ (void)writeData:(id)data toPath:(NSString *)path fileName:(NSString *)fileName {
    // 1. 检查数据有效性
    if (!data) {
        NSLog(@"⚠️ 数据为空，无法写入");
        return;
    }
    
    // 2. 检查路径是否存在，不存在则创建
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    if (![fileManager fileExistsAtPath:path isDirectory:&isDirectory]) {
        NSError *createDirError;
        BOOL success = [fileManager createDirectoryAtPath:path
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:&createDirError];
        if (!success) {
            NSLog(@"❌ 创建目录失败: %@", createDirError.localizedDescription);
            return;
        }
    }
    
    // 3. 处理 fileName，分离目录和文件名（支持 "a/b.txt" 格式）
    NSString *fullPath = [path stringByAppendingPathComponent:fileName];
    NSString *directoryPath = [fullPath stringByDeletingLastPathComponent];

    // 4. 如果 fileName 包含子目录（如 "a/b.txt"），确保子目录存在
    if (![directoryPath isEqualToString:path]) {
        NSError *createSubDirError;
        BOOL success = [fileManager createDirectoryAtPath:directoryPath
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:&createSubDirError];
        if (!success) {
            NSLog(@"❌ 创建子目录失败: %@", createSubDirError.localizedDescription);
            return;
        }
    }
    
    // 5. 根据数据类型转换为 NSData
    NSData *fileData;
    if ([data isKindOfClass:[NSDictionary class]] || [data isKindOfClass:[NSArray class]]) {
        // 字典/数组 → JSON 格式
        NSError *jsonError;
        fileData = [NSJSONSerialization dataWithJSONObject:data
                                                  options:NSJSONWritingPrettyPrinted
                                                    error:&jsonError];
        if (!fileData) {
            NSLog(@"❌ JSON 转换失败: %@", jsonError.localizedDescription);
            return;
        }
    } else if ([data isKindOfClass:[NSString class]]) {
        // NSString → UTF-8 编码
        fileData = [(NSString *)data dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([data isKindOfClass:[NSData class]]) {
        // NSData → 直接使用
        fileData = (NSData *)data;
    } else {
        NSLog(@"❌ 不支持的数据类型: %@", [data class]);
        return;
    }
    
    // 6. 写入文件
    NSError *writeError;
    BOOL success = [fileData writeToFile:fullPath
                                options:NSDataWritingAtomic
                                  error:&writeError];
    
    if (success) {
        NSLog(@"✅ 文件写入成功: %@", fullPath);
    } else {
        NSLog(@"❌ 文件写入失败: %@", writeError.localizedDescription);
    }
}


+ (void)deleteTildeFilesInDirectory:(NSString *)directory {
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
        if (!isDirectory && ([relativePath hasSuffix:@"~.h"] || [relativePath hasSuffix:@"~.m"] || [relativePath hasSuffix:@"~.swift"])) {
        
            // 删除文件
            NSError *removeError = nil;
            BOOL success = [fileManager removeItemAtPath:fullPath error:&removeError];
            
            if (success) {
                NSLog(@"Deleted: %@", fullPath);
            } else {
                NSLog(@"Failed to delete %@: %@", fullPath, removeError.localizedDescription);
            }
        }
    }
}





+ (void)replaceInDirectory:(NSString *)sourceDir withJSONRuleFile:(NSString *)jsonPath excludeDirs:(NSArray<NSString *> *)excludeDirs {
    
    // 1. 加载替换规则
    NSDictionary *rules = [self loadReplacementDictFromJSON:jsonPath];
    if (!rules) return;
    
    // 2. 配置参数
    NSArray *extensions = @[@"h", @"m", @"swift"];
    NSFileManager *fm = NSFileManager.defaultManager;
    
    // 3. 遍历文件
    NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:sourceDir];
    for (NSString *relativePath in enumerator) {
        @autoreleasepool {
            // 跳过排除目录
            if ([self shouldSkipPath:relativePath excludeDirs:excludeDirs]) {
                [enumerator skipDescendants];
                continue;
            }
            
            // 处理目标文件
            NSString *ext = relativePath.pathExtension.lowercaseString;
            if ([extensions containsObject:ext]) {
                NSString *fullPath = [sourceDir stringByAppendingPathComponent:relativePath];
                [self processFile:fullPath withRules:rules];
            }
        }
    }
}

#pragma mark - 核心逻辑


// 文件处理（关键修改点）
+ (void)processFile:(NSString *)filePath withRules:(NSDictionary *)rules {
    NSError *error;
    NSMutableString *content = [NSMutableString stringWithContentsOfFile:filePath
                                                               encoding:NSUTF8StringEncoding
                                                                  error:&error];
    if (error) {
        NSLog(@"❌ 文件读取失败: %@", filePath.lastPathComponent);
        return;
    }
    
    __block NSUInteger replaceCount = 0;
    NSString *originalContent = content.copy;
    
    [rules enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        // 构建带@""的搜索模式和替换字符串
        NSString *searchPattern = [NSString stringWithFormat:@"@\"%@\"", value];
        NSString *replacement = [NSString stringWithFormat:@"DBConstantString.%@", key];
        
        NSRange searchRange = NSMakeRange(0, content.length);
        while (searchRange.location < content.length) {
            NSRange foundRange = [content rangeOfString:searchPattern
                                               options:NSLiteralSearch
                                                 range:searchRange];
            
            if (foundRange.location == NSNotFound) break;
            
            // 精确匹配检查（防止误替换）
            BOOL isExactMatch = YES;
            if (foundRange.location > 0) {
                unichar prevChar = [content characterAtIndex:foundRange.location - 1];
                isExactMatch = !isalnum(prevChar) && prevChar != '_';
            }
            
            if (isExactMatch) {
                [content replaceCharactersInRange:foundRange withString:replacement];
                replaceCount++;
                searchRange.location = foundRange.location + replacement.length;
            } else {
                searchRange.location = NSMaxRange(foundRange);
            }
            searchRange.length = content.length - searchRange.location;
        }
    }];
    
    // 保存修改
    if (replaceCount > 0) {
        if ([content writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            NSLog(@"✅ %@: 替换 %lu 处", filePath.lastPathComponent, (unsigned long)replaceCount);
        } else {
            NSLog(@"❌ %@: 写入失败 - %@", filePath, error.localizedDescription);
            // 恢复原始内容
            [originalContent writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }
}

#pragma mark - 辅助方法

// 检查是否跳过目录（新增白名单逻辑）
+ (BOOL)shouldSkipPath:(NSString *)path excludeDirs:(NSArray *)excludeDirs {
    for (NSString *dir in excludeDirs) {
        if ([path containsString:dir]) {
            NSLog(@"⏩ 跳过目录: %@", path);
            return YES;
        }
    }
    return NO;
}


+ (NSDictionary *)loadReplacementDictFromJSON:(NSString *)jsonPath {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:jsonPath ofType:@"json"];
    NSData *jsonData = [[NSData alloc] initWithContentsOfFile:filePath];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                            options:kNilOptions
                                                              error:nil];
    return dict;
}





+ (NSArray<NSString *> *)detectStringsInDirectory:(NSString *)directoryPath
                                  targetStrings:(NSArray<NSString *> *)targetStrings {
    
    NSMutableArray<NSString *> *results = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 检查目录是否存在
    BOOL isDirectory = NO;
    BOOL exists = [fileManager fileExistsAtPath:directoryPath isDirectory:&isDirectory];
    
    if (!exists || !isDirectory) {
        NSLog(@"错误：目录不存在或不是目录 - %@", directoryPath);
        return @[];
    }
    
    // 获取目录下所有文件
    NSArray *files = [self getAllFilesInDirectory:directoryPath excludingPods:YES];
    
    for (NSString *filePath in files) {
        if ([self isTextFile:filePath]) {
            NSError *error = nil;
            NSString *fileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
            
            if (error) {
                // 尝试其他编码
                fileContent = [NSString stringWithContentsOfFile:filePath usedEncoding:nil error:&error];
                if (error) {
                    continue;
                }
            }
            
            if (fileContent) {
                for (NSString *targetString in targetStrings) {
                    // 使用更精确的匹配方法
                    NSArray *matches = [self findExactMatchesOfString:targetString inContent:fileContent filePath:filePath];
                    [results addObjectsFromArray:matches];
                }
            }
        }
    }
    

    return [results copy];
}

#pragma mark - 精确匹配方法

/// 精确查找字符串匹配
+ (NSArray<NSString *> *)findExactMatchesOfString:(NSString *)targetString
                                        inContent:(NSString *)content
                                         filePath:(NSString *)filePath {
    
    NSMutableArray<NSString *> *matches = [NSMutableArray array];
    
    // 构建要搜索的精确模式：@"目标字符串"
    NSString *exactPattern = [NSString stringWithFormat:@"@\"%@\"", targetString];
    
    // 使用正则表达式进行精确匹配，避免部分匹配
    NSError *regexError = nil;
    
    // 注意：这里需要对目标字符串中的特殊正则字符进行转义
    NSString *escapedTargetString = [NSRegularExpression escapedPatternForString:targetString];
    NSString *regexPattern = [NSString stringWithFormat:@"@\"%@\"", escapedTargetString];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern
                                                                           options:0
                                                                             error:&regexError];
    
    if (regexError) {
        NSLog(@"正则表达式错误: %@", regexError);
        return @[];
    }
    
    // 获取所有匹配
    NSArray<NSTextCheckingResult *> *regexMatches = [regex matchesInString:content
                                                                   options:0
                                                                     range:NSMakeRange(0, content.length)];
    
    if (regexMatches.count > 0) {
        // 按行分析，提供更精确的位置信息
        NSArray *lines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
        NSUInteger currentLocation = 0;
        for (NSUInteger lineNumber = 0; lineNumber < lines.count; lineNumber++) {
            NSString *line = lines[lineNumber];
            NSRange lineRange = NSMakeRange(currentLocation, line.length);
            
            // 检查这一行是否有匹配
            for (NSTextCheckingResult *match in regexMatches) {
                if (NSLocationInRange(match.range.location, lineRange)) {
                    // 清理文件路径，只显示相对路径
                    NSString *relativePath = [self relativePathFromAbsolutePath:filePath];
                    NSString *result = [NSString stringWithFormat:@"文件: %@ 包含: %@",
                                      relativePath.lastPathComponent, exactPattern];
                    if (![matches containsObject:result]){
                        [matches addObject:result];
                    }
                }
            }
            
            currentLocation += line.length + 1; // +1 用于换行符
        }
    }
    
    return [matches copy];
}

#pragma mark - 辅助方法

/// 获取目录下所有文件路径（递归）
+ (NSArray<NSString *> *)getAllFilesInDirectory:(NSString *)directoryPath excludingPods:(BOOL)excludePods {
    NSMutableArray<NSString *> *allFiles = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSURL *directoryURL = [NSURL fileURLWithPath:directoryPath];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:directoryURL
                                          includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                             options:0
                                                        errorHandler:^BOOL(NSURL *url, NSError *error) {
        NSLog(@"遍历错误: %@", error);
        return YES;
    }];
    
    for (NSURL *fileURL in enumerator) {
        NSNumber *isDirectory;
        [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
        
        NSString *filePath = [fileURL path];
        
        // 排除Pods目录
        if (excludePods && [filePath containsString:@"/Pods/"]) {
            [enumerator skipDescendants];
            continue;
        }
        
        if (![isDirectory boolValue]) {
            [allFiles addObject:filePath];
        }
    }
    
    return [allFiles copy];
}

/// 判断是否为文本文件
+ (BOOL)isTextFile:(NSString *)filePath {
    NSString *fileExtension = [[filePath pathExtension] lowercaseString];
    
    // 常见的文本文件扩展名
    NSSet *textFileExtensions = [NSSet setWithArray:@[
        @"m", @"mm", @"h", @"c", @"cpp", @"swift",
        @"json", @"plist", @"xml", @"html", @"css", @"js",
        @"txt", @"md", @"strings", @"storyboard", @"xib"
    ]];
    
    return [textFileExtensions containsObject:fileExtension];
}

/// 从绝对路径获取相对路径（用于美化输出）
+ (NSString *)relativePathFromAbsolutePath:(NSString *)absolutePath {
    NSString *currentDirectory = [[NSFileManager defaultManager] currentDirectoryPath];
    if ([absolutePath hasPrefix:currentDirectory]) {
        return [absolutePath substringFromIndex:currentDirectory.length + 1];
    }
    return absolutePath;
}
@end
