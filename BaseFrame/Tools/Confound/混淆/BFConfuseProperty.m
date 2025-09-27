//
//  BFConfuseProperty.m
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/3.
//

#import "BFConfuseProperty.h"
#import "BFConfuseManager.h"
#import "BFConfuseMarker.h"
@implementation BFConfuseProperty

+ (NSDictionary *)mapPropertyDict{
    return [self parseModuleMappingJSON:@"property"];
}

+ (NSDictionary *)mapPropertyDict1{
    return [self parseModuleMappingJSON:@"property_xixi"];
}

+ (NSDictionary *)mapPropertyDict2{
    return [self parseModuleMappingJSON:@"property_wsg"];
}

+ (NSDictionary *)mapPropertyDict4{
    return [self parseModuleMappingJSON:@"property_jingyuege"];
}

+ (NSArray<NSString *> *)scanProjectAtPath:(NSString *)projectPath {
    NSLog(@"开始扫描项目: %@", projectPath);
    NSDate *startTime = [NSDate date];
    
    // 使用局部变量存储结果（避免静态变量线程安全问题）
    NSMutableSet *foundProperties = [NSMutableSet set];
    
    // 获取并处理所有源文件
    NSArray *sourceFiles = [self findSourceFilesInProject:projectPath];
    [self processFiles:sourceFiles intoSet:foundProperties];
    
    // 输出统计信息
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:startTime];
    NSLog(@"✅ 扫描完成，共找到 %lu 个属性，耗时 %.2f 秒",
          (unsigned long)foundProperties.count, elapsed);
    return foundProperties;
    // 返回排序后的数组
    return [[foundProperties allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

#pragma mark - 私有方法

/// 查找项目中的所有源文件
+ (NSArray<NSString *> *)findSourceFilesInProject:(NSString *)projectPath {
    NSMutableArray *sourceFiles = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:projectPath];
    NSString *filePath;
    
    while ((filePath = [enumerator nextObject])) {
        // 跳过Pods和其他第三方目录
        if ([self shouldSkipDirectory:filePath]) {
            [enumerator skipDescendants];
            continue;
        }
        
        // 收集.h和.m文件
        if ([self isSourceFile:filePath]) {
            [sourceFiles addObject:[projectPath stringByAppendingPathComponent:filePath]];
        }
    }
    
    return [sourceFiles copy];
}

/// 判断是否应该跳过目录
+ (BOOL)shouldSkipDirectory:(NSString *)filePath {
    NSArray *skipDirectories = @[@"Pods/", @"ThirdParty/", @"Vendor/", @"Carthage/"];
    for (NSString *dir in skipDirectories) {
        if ([filePath containsString:dir]) {
            return YES;
        }
    }
    return NO;
}

/// 判断是否是源文件
+ (BOOL)isSourceFile:(NSString *)filePath {
    return [filePath hasSuffix:@".h"] || [filePath hasSuffix:@".m"];
}

/// 处理多个文件并将结果存入指定集合
+ (void)processFiles:(NSArray<NSString *> *)filePaths intoSet:(NSMutableSet *)resultSet {
    for (NSString *filePath in filePaths) {
        @autoreleasepool {
            NSError *error;
            NSString *fileContent = [NSString stringWithContentsOfFile:filePath
                                                              encoding:NSUTF8StringEncoding
                                                                 error:&error];
            if (error) {
                NSLog(@"⚠️ 读取文件失败: %@, 错误: %@", filePath, error);
                continue;
            }
            
            [self extractPropertiesFromContent:fileContent intoSet:resultSet];
        }
    }
}

/// 从文件内容中提取属性并存入集合
+ (void)extractPropertiesFromContent:(NSString *)content intoSet:(NSMutableSet *)resultSet {
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"@property\\s*\\([^)]+\\)\\s+[\\w<>,]+\\s+\\*(\\w+)\\s*;"
                                  options:0
                                  error:nil];
    
    [regex enumerateMatchesInString:content
                            options:0
                              range:NSMakeRange(0, content.length)
                         usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        if (result.numberOfRanges > 1) {
            NSString *propertyName = [content substringWithRange:[result rangeAtIndex:1]];
            if (![self shouldSkipProperty:propertyName]) {
                [resultSet addObject:propertyName];
            }
        }
    }];
}

/// 判断是否应该跳过该属性
+ (BOOL)shouldSkipProperty:(NSString *)propertyName {
    // 跳过UI开头的属性（不区分大小写）
    return [propertyName.lowercaseString hasPrefix:@"ui"];
}




//===========================================================
+ (void)safeReplaceContentInDirectory:(NSString *)directoryPath
                        renameMapping:(NSDictionary<NSString *, NSString *> *)renameMapping {
    
    
    NSString *methodMap = [BFConfuseManager readObfuscationMappingFileAtPath:directoryPath name:@"参数名映射"];
    if (methodMap){
        NSData *jsonData = [methodMap dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
        renameMapping = dict;
    }
    
    // Validate inputs
    if (directoryPath.length == 0 || renameMapping.count == 0) {
        NSLog(@"Invalid parameters");
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directoryPath];
    
    // Pre-sort keys by length (longest first) to prevent partial replacements
    NSArray *sortedKeys = [renameMapping.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *key1, NSString *key2) {
        return key2.length - key1.length;
    }];
    
    for (NSString *relativePath in enumerator) {
        @autoreleasepool {
            // Skip Pods directory and its contents
            if ([relativePath containsString:@"Pods/"] || [relativePath hasPrefix:@"Pods/"]) {
                [enumerator skipDescendants];
                continue;
            }
            
            NSString *fullPath = [directoryPath stringByAppendingPathComponent:relativePath];
            BOOL isDirectory;
            if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory] && !isDirectory) {
                [self processFileAtPath:fullPath withSortedKeys:sortedKeys renameMapping:renameMapping];
            }
        }
    }
    
    [BFConfuseManager writeData:renameMapping toPath:directoryPath fileName:@"混淆/参数名映射"];
}

+ (void)processFileAtPath:(NSString *)filePath
           withSortedKeys:(NSArray *)sortedKeys
            renameMapping:(NSDictionary *)renameMapping {
    
    NSError *error;
    NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:filePath
                                                                    encoding:NSUTF8StringEncoding
                                                                       error:&error];
    if (error || !fileContent) {
        NSLog(@"Failed to read file: %@", filePath);
        return;
    }
    
    BOOL contentChanged = NO;
    
    for (NSString *originalKey in sortedKeys) {
        NSString *replacement = renameMapping[originalKey];
        
        // Create case-sensitive regular expression pattern
        NSString *pattern = [NSString stringWithFormat:@"(?<![a-zA-Z0-9])%@(?![a-zA-Z0-9])",
                             [NSRegularExpression escapedPatternForString:originalKey]];
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:0
                                                                                 error:&error];
        if (error) {
            NSLog(@"Regex error for key '%@': %@", originalKey, error);
            continue;
        }
        
        NSUInteger matches = [regex replaceMatchesInString:fileContent
                                                   options:0
                                                     range:NSMakeRange(0, fileContent.length)
                                              withTemplate:replacement];
        
        if (matches > 0) {
            contentChanged = YES;
            NSLog(@"Replaced %lu occurrences of '%@' with '%@' in %@",
                  (unsigned long)matches, originalKey, replacement, filePath);
        }
    }
    
    if (contentChanged) {
        // Preserve original file attributes
        NSDictionary *originalAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        
        // Write changes back to file
        if (![fileContent writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            NSLog(@"Failed to write file: %@, error: %@", filePath, error);
        } else {
            // Restore original attributes
            if (originalAttributes) {
                [[NSFileManager defaultManager] setAttributes:originalAttributes ofItemAtPath:filePath error:nil];
            }
        }
    }
}





+ (void)insertRandomPropertiesInDirectory:(NSString *)directory
                                 namePool:(NSArray<NSString *> *)propertyNames
                             averageCount:(NSInteger)averageCount {
    
    // 1. 参数验证和默认值
    if (averageCount <= 0) averageCount = 10;
    if (propertyNames.count == 0) return;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    if (![fileManager fileExistsAtPath:directory isDirectory:&isDirectory] || !isDirectory) {
        NSLog(@"Error: Directory does not exist at path: %@", directory);
        return;
    }
    
    // 2. 遍历目录查找 Model 文件
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directory];
    NSString *filePath;
    
    while ((filePath = [enumerator nextObject])) {
        // 跳过Pods目录和非.h文件
        if ([filePath containsString:@"Pods/"] || ![filePath hasSuffix:@".h"] || [filePath containsString:@".framework"] || [filePath containsString:@".xcframework"]) {
            continue;
        }
        
        NSString *fullPath = [directory stringByAppendingPathComponent:filePath];
        if ([self fileContainsClassDeclaration:fullPath]) {
            [self processModelFileAtPath:fullPath namePool:propertyNames averageCount:averageCount];
        }

    }
}

+ (BOOL)fileContainsClassDeclaration:(NSString *)filePath {
    NSError *error = nil;
    NSString *fileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"读取文件失败: %@", error.localizedDescription);
        return NO;
    }
    
    // 正则表达式匹配 "@interface ClassName : NSObject"
    NSString *pattern = @"@interface\\s+\\w+\\s*:\\s*NSObject";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    
    if (error) {
        NSLog(@"正则表达式错误: %@", error.localizedDescription);
        return NO;
    }
    
    NSRange range = [regex rangeOfFirstMatchInString:fileContent options:0 range:NSMakeRange(0, fileContent.length)];
    return (range.location != NSNotFound);
}

+ (void)processModelFileAtPath:(NSString *)filePath
                      namePool:(NSArray<NSString *> *)namePool
                  averageCount:(NSInteger)averageCount {
    
    NSMutableDictionary *propertyDict = [NSMutableDictionary dictionary];
    NSDictionary *dict = [self addRandomPropertiesToInterfacesAtPath:filePath namePool:namePool averageCount:averageCount];

    for (NSString *key in dict.allKeys) {
        NSArray *names = dict[key];
        NSMutableArray *temp = [NSMutableArray array];
        for (NSString *propertyName in names) {
            NSString *result = [self generateRandomPropertyWithName:propertyName];
            [temp addObject:result];
        }
        [propertyDict setValue:[temp componentsJoinedByString:@"\n"] forKey:key];
    }
    
    
    NSError *error;
    NSString *fileContent = [NSString stringWithContentsOfFile:filePath
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
    if (error) {
        NSLog(@"读取文件失败: %@", error.localizedDescription);
        return;
    }
    

    NSArray *interfaceBlocks = [self extractAllInterfaceBlocksFromFile:filePath];

    for (NSString *block in interfaceBlocks) {
        NSString *className = [self extractClassNameFromInterfaceBlock:block];
        NSString *value = [NSString stringWithFormat:@"\n\n%@\n\n",propertyDict[className]];
        NSString *result = [self replaceRandomNewlineInString:block withValue:value];
        fileContent = [fileContent stringByReplacingOccurrencesOfString:block withString:result];
    }
    
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

+ (NSString *)replaceRandomNewlineInString:(NSString *)originalString withValue:(NSString *)value {
    if (!originalString || originalString.length == 0) {
        return originalString; // 空字符串直接返回
    }

    // 1. 查找所有 `\n` 的位置
    NSMutableArray<NSValue *> *newlineRanges = [NSMutableArray array];
    NSRange searchRange = NSMakeRange(0, originalString.length);
    while (searchRange.location < originalString.length) {
        NSRange newlineRange = [originalString rangeOfString:@"\n" options:0 range:searchRange];
        if (newlineRange.location == NSNotFound) {
            break;
        }
        [newlineRanges addObject:[NSValue valueWithRange:newlineRange]];
        searchRange.location = newlineRange.location + 1;
        searchRange.length = originalString.length - searchRange.location;
    }

    if (newlineRanges.count == 0) {
        return originalString; // 没有换行符
    }

    // 2. 随机选择一个 `\n` 的位置
    NSUInteger randomIndex = arc4random_uniform((uint32_t)newlineRanges.count);
    NSRange selectedRange = [newlineRanges[randomIndex] rangeValue];

    // 3. 替换选中的 `\n`
    NSMutableString *mutableString = [originalString mutableCopy];
    [mutableString replaceCharactersInRange:selectedRange withString:value ?: @""];

    return [mutableString copy];
}

+ (NSDictionary<NSString *, NSArray<NSString *> *> *)addRandomPropertiesToInterfacesAtPath:(NSString *)filePath
                                                                                  namePool:(NSArray<NSString *> *)namePool
                                                                              averageCount:(NSInteger)averageCount {
    NSMutableDictionary *originalData = [[self getAllInterfacesAndProperties:filePath] mutableCopy];
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    for (NSString *key in originalData.allKeys) {
        NSMutableArray *temp = [NSMutableArray array];
        for (int i = 0; i < averageCount; i++) {
            NSString *randomName = [self randomStringInNamePool:namePool whiteList:originalData.allValues newList:temp];
            [temp addObject:randomName];
        }
        [result setValue:temp forKey:key];
    }
    
    return result;
}

+ (NSString *)randomStringInNamePool:(NSArray<NSString *> *)namePool whiteList:(NSArray *)whiteList newList:(NSArray *)newList{
    NSString *randomName = namePool[arc4random_uniform((uint32_t)namePool.count)];
    if ([whiteList containsObject:randomName] || [newList containsObject:randomName]){
        return [self randomStringInNamePool:namePool whiteList:whiteList newList:newList];
    }
    return randomName;
}

+ (NSDictionary<NSString *, NSArray<NSString *> *> *)getAllInterfacesAndProperties:(NSString *)filePath {
    NSArray *interfaceBlocks = [self extractAllInterfaceBlocksFromFile:filePath];
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    for (NSString *block in interfaceBlocks) {
        NSString *className = [self extractClassNameFromInterfaceBlock:block];
        if (className) {
            NSArray *properties = [self extractPropertyNamesFromInterfaceBlock:block];
            result[className] = properties;
        }
    }
    return [result copy];
}

+ (NSArray<NSString *> *)extractAllInterfaceBlocksFromFile:(NSString *)filePath {
    NSError *error;
    NSString *fileContent = [NSString stringWithContentsOfFile:filePath
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
    if (error) {
        NSLog(@"读取文件失败: %@", error.localizedDescription);
        return @[];
    }
    
    // 正则匹配所有 @interface 块（含类名和实现）
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:
                                  @"@interface\\s+(\\w+)\\s*(?:\\(.*?\\))?\\s*:[\\s\\S]*?@end"
                                                                           options:0
                                                                             error:&error];
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:fileContent
                                                              options:0
                                                                range:NSMakeRange(0, fileContent.length)];
    
    NSMutableArray *blocks = [NSMutableArray array];
    for (NSTextCheckingResult *match in matches) {
        [blocks addObject:[fileContent substringWithRange:match.range]];
    }
    
    return [blocks copy];
}

+ (NSString *)extractClassNameFromInterfaceBlock:(NSString *)block {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:
                                  @"@interface\\s+(\\w+)"
                                                                           options:0
                                                                             error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:block
                                                    options:0
                                                      range:NSMakeRange(0, block.length)];
    if (match && match.numberOfRanges >= 2) {
        return [block substringWithRange:[match rangeAtIndex:1]];
    }
    return nil;
}

+ (NSArray<NSString *> *)extractPropertyNamesFromInterfaceBlock:(NSString *)block {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"@property\\s*\\(.*?\\)\\s+\\w+\\s+\\*(\\w+);"
                                                                             options:0
                                                                               error:nil];
        NSArray *matches = [regex matchesInString:block
                                         options:0
                                           range:NSMakeRange(0, block.length)];
        
        NSMutableArray *properties = [NSMutableArray array];
        for (NSTextCheckingResult *match in matches) {
            NSString *propertyName = [block substringWithRange:[match rangeAtIndex:1]];
            [properties addObject:propertyName];
        }
        
        return [properties copy];
}

//根据属性名生成随机属性声明
+ (NSString *)generateRandomPropertyWithName:(NSString *)propertyName {
    // 随机类型配置
    NSArray *objectTypes = @[@"NSString", @"NSArray", @"NSDictionary", @"NSDate", @"NSNumber"];
    NSArray *primitiveTypes = @[@"NSInteger", @"NSUInteger", @"CGFloat", @"BOOL", @"int"];
    
    // 随机决定是否为对象类型 (60%概率)
    BOOL isObjectType = arc4random_uniform(10) < 6;
    
    // 生成类型
    NSString *type;
    if (isObjectType) {
        type = [NSString stringWithFormat:@"%@*", objectTypes[arc4random_uniform((uint32_t)objectTypes.count)]];
    } else {
        type = primitiveTypes[arc4random_uniform((uint32_t)primitiveTypes.count)];
    }
    
    // 修饰词组合
    NSMutableArray *attributes = [NSMutableArray arrayWithObject:@"nonatomic"];
    
    // 内存管理修饰词
    if (isObjectType) {
        NSArray *memoryAttributes = @[@"strong", @"weak", @"copy"];
        [attributes addObject:memoryAttributes[arc4random_uniform((uint32_t)memoryAttributes.count)]];
    } else {
        [attributes addObject:@"assign"];
    }
    
    // 构建属性声明
    return [NSString stringWithFormat:@"@property (%@) %@ %@;",
            [attributes componentsJoinedByString:@", "],
            type,
            propertyName];
}





@end
