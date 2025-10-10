//
//  BFConfuseModel.m
//  BaseFrame
//
//  Created by 王祥伟 on 2025/7/29.
//

#import "BFConfuseModel.h"
#import "BFConfuseManager.h"

//[interfaceContent containsString:@": FinalizerHabaneroFrameworkBlueprint"]
@implementation BFConfuseModel

+ (NSDictionary *)mapModelDict{
    return [self parseModuleMappingJSON:@"model"];
}

+ (NSDictionary *)mapModelDict1{
    return [self parseModuleMappingJSON:@"model_xixi"];
}

+ (NSDictionary *)mapModelDict2{
    return [self parseModuleMappingJSON:@"model_jingyuege"];
}

+ (NSDictionary *)mapModelDict103{
    return [self parseModuleMappingJSON:@"model_yueyi 3"];
}

+ (void)auditAndFixProjectAtPath:(NSString *)projectPath
                propertyMappings:(NSDictionary<NSString *, NSString *> *)mappings
                  whitelistedPods:(NSArray<NSString *> *)whitelistedPods {
    NSString *modeMap = [BFConfuseManager readObfuscationMappingFileAtPath:projectPath name:@"Model变量映射"];
    if (modeMap){
        NSData *jsonData = [modeMap dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
        mappings = dict;
    }
    
    // 1. 参数检查
    if (projectPath.length == 0 || mappings.count == 0) {
        return;
    }
    
    // 2. 获取所有需要处理的.h文件（Model结尾且不在白名单）
    NSArray *headerFiles = [self findAllModelHeaderFilesAtPath:projectPath whitelistedPods:whitelistedPods];
    
    // 3. 处理每个.h文件
    for (NSString *headerPath in headerFiles) {
        [self processHeaderFile:headerPath mappings:mappings whitelistedPods:whitelistedPods];
    }
    
    [self performGlobalReplacementsInProject:projectPath mappings:mappings whitelistedPods:whitelistedPods];
    
    [BFConfuseManager writeData:modeMap toPath:projectPath fileName:@"混淆/Model变量映射"];
}

#pragma mark - 核心步骤实现

// 查找所有Model头文件
+ (NSArray *)findAllModelHeaderFilesAtPath:(NSString *)projectPath whitelistedPods:(NSArray *)whitelistedPods {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *headerFiles = [NSMutableArray array];
    
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:projectPath];
    NSString *filePath;
    
    while ((filePath = [enumerator nextObject])) {
        // 跳过白名单路径
        if ([self isPath:filePath whitelisted:whitelistedPods]) {
            continue;
        }
        
        
        // 只处理Model.h文件
//        if ([filePath hasSuffix:@"Model.h"]) {
            NSString *fullPath = [projectPath stringByAppendingPathComponent:filePath];
            [headerFiles addObject:fullPath];
//        }
    }
    
    return [headerFiles copy];
}

// 处理单个头文件
+ (void)processHeaderFile:(NSString *)headerPath mappings:(NSDictionary *)mappings whitelistedPods:(NSArray *)whitelistedPods {
    NSError *error;
    NSString *headerContent = [NSString stringWithContentsOfFile:headerPath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"读取头文件失败: %@", headerPath);
        return;
    }
    
    // 1. 获取头文件中的所有类声明
    NSArray *classDeclarations = [self findAllClassDeclarationsInHeader:headerContent];
    if (classDeclarations.count == 0) {
        return;
    }
    
    // 2. 查找对应的.m文件
    NSString *implementationPath = [self findImplementationFileForHeader:headerPath];
    if (!implementationPath) {
        return;
    }
    
    // 3. 处理.m文件中的每个类
    for (NSString *className in classDeclarations) {
        // 获取该类需要映射的属性
        NSDictionary *classMappings = [self findMappingsForClass:className inHeader:headerContent mappings:mappings];
        if (classMappings.count == 0) {
            continue;
        }
        
        // 在.m文件中为这个类添加映射方法
        [self addModelCustomPropertyMapperForClass:className
                                      inFile:implementationPath
                                    mappings:classMappings];
    }
}

// 在头文件中查找所有类声明
+ (NSArray *)findAllClassDeclarationsInHeader:(NSString *)headerContent {
    NSMutableArray *classes = [NSMutableArray array];
    
    // 匹配 @interface ClassName : 或 @interface ClassName (
    NSString *pattern = @"@interface\\s+(\\w+)\\s*[:{]";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    
    NSArray *matches = [regex matchesInString:headerContent options:0 range:NSMakeRange(0, headerContent.length)];
    for (NSTextCheckingResult *match in matches) {
        if (match.numberOfRanges >= 2) {
            NSString *className = [headerContent substringWithRange:[match rangeAtIndex:1]];
            [classes addObject:className];
        }
    }
    
    return [classes copy];
}

// 查找对应的实现文件
+ (NSString *)findImplementationFileForHeader:(NSString *)headerPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 尝试查找.m文件
    NSString *mPath = [[headerPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"m"];
    if ([fileManager fileExistsAtPath:mPath]) {
        return mPath;
    }
    
    // 尝试查找.mm文件
    NSString *mmPath = [[headerPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"mm"];
    if ([fileManager fileExistsAtPath:mmPath]) {
        return mmPath;
    }
    
    return nil;
}

// 查找类中需要映射的属性
+ (NSDictionary *)findMappingsForClass:(NSString *)className
                            inHeader:(NSString *)headerContent
                           mappings:(NSDictionary *)mappings {
    
    NSMutableDictionary *classMappings = [NSMutableDictionary dictionary];
    
    // 改进后的正则表达式，可以匹配包含泛型等复杂属性声明
    NSString *pattern = @"@property\\s*\\([^)]*\\)\\s*(?:\\w+\\s*<[^>]+>\\s*\\*?|\\w+\\s*\\*?)\\s*(\\w+)\\s*;";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    
    NSArray *matches = [regex matchesInString:headerContent options:0 range:NSMakeRange(0, headerContent.length)];
    for (NSTextCheckingResult *match in matches) {
        if (match.numberOfRanges >= 2) {
            NSString *propertyName = [headerContent substringWithRange:[match rangeAtIndex:1]];
            
            // 检查是否需要映射
            NSString *newName = mappings[propertyName];
            if (newName) {
                classMappings[newName] = propertyName;
            }
        }
    }
    
    return [classMappings copy];
}

// 在实现文件中为特定类添加映射方法
+ (void)addModelCustomPropertyMapperForClass:(NSString *)className
                                  inFile:(NSString *)filePath
                                mappings:(NSDictionary *)mappings {
    
    NSError *error;
    NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"读取实现文件失败: %@", filePath);
        return;
    }
    
    // 1. 查找类的@implementation部分
    NSString *implementationPattern = [NSString stringWithFormat:@"@implementation\\s+%@", className];
    NSRegularExpression *implRegex = [NSRegularExpression regularExpressionWithPattern:implementationPattern options:0 error:nil];
    NSRange implRange = [implRegex rangeOfFirstMatchInString:fileContent options:0 range:NSMakeRange(0, fileContent.length)];
    
    if (implRange.location == NSNotFound) {
        return;
    }
    
    // 2. 查找类的@end位置
    NSRange endRange = [fileContent rangeOfString:@"@end" options:0 range:NSMakeRange(implRange.location, fileContent.length - implRange.location)];
    if (endRange.location == NSNotFound) {
        return;
    }
    
    // 3. 检查是否已存在modelCustomPropertyMapper方法
    NSString *methodPattern = [NSString stringWithFormat:@"\\+\\s*\\(NSDictionary\\s*\\*\\s*\\)\\s*modelCustomPropertyMapper\\s*\\{[^}]*\\}"];
    NSRegularExpression *methodRegex = [NSRegularExpression regularExpressionWithPattern:methodPattern options:0 error:nil];
    NSRange methodRange = [methodRegex rangeOfFirstMatchInString:fileContent options:0 range:NSMakeRange(implRange.location, endRange.location - implRange.location)];
    
    if (methodRange.location != NSNotFound) {
        // 已存在则更新
        NSString *existingMethod = [fileContent substringWithRange:methodRange];
        NSString *newMethod = [self updateExistingModelCustomPropertyMapper:existingMethod withMappings:mappings];
        [fileContent replaceCharactersInRange:methodRange withString:newMethod];
    } else {
        // 不存在则添加
        NSString *newMethod = [self createModelCustomPropertyMapperMethodWithMappings:mappings];
        [fileContent insertString:newMethod atIndex:endRange.location];
    }
    
    // 4. 写回文件
    [fileContent writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"写入实现文件失败: %@", filePath);
    }
}

// 创建新的modelCustomPropertyMapper方法
+ (NSString *)createModelCustomPropertyMapperMethodWithMappings:(NSDictionary *)mappings {
    NSMutableString *methodString = [NSMutableString stringWithString:@"\n+ (NSDictionary *)modelCustomPropertyMapper {\n    return @{"];
    
    NSArray *allKeys = mappings.allKeys;
    for (NSInteger i = 0; i < allKeys.count; i++) {
        NSString *newName = allKeys[i];
        NSString *oldName = mappings[newName];
        
        [methodString appendFormat:@"@\"%@\": @[@\"%@\", @\"%@\"]", newName, oldName, newName];
        
        if (i < allKeys.count - 1) {
            [methodString appendString:@", "];
        }
    }
    
    [methodString appendString:@"};\n}\n"];
    return [methodString copy];
}

// 更新已存在的modelCustomPropertyMapper方法
+ (NSString *)updateExistingModelCustomPropertyMapper:(NSString *)existingMethod withMappings:(NSDictionary *)newMappings {
    // 1. 提取原有字典内容
    NSRange braceRange = [existingMethod rangeOfString:@"{" options:NSBackwardsSearch];
    NSRange endBraceRange = [existingMethod rangeOfString:@"}" options:NSBackwardsSearch];
    
    if (braceRange.location == NSNotFound || endBraceRange.location == NSNotFound) {
        return existingMethod;
    }
    
    NSRange dictRange = NSMakeRange(braceRange.location + 1, endBraceRange.location - braceRange.location - 1);
    NSString *dictContent = [existingMethod substringWithRange:dictRange];
    
    // 2. 解析原有映射
    NSMutableDictionary *existingMappings = [NSMutableDictionary dictionary];
    NSArray *components = [dictContent componentsSeparatedByString:@","];
    for (NSString *component in components) {
        NSArray *keyValue = [component componentsSeparatedByString:@":"];
        if (keyValue.count == 2) {
            NSString *key = [keyValue[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *value = [keyValue[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            // 清理字符串
            key = [key stringByReplacingOccurrencesOfString:@"@" withString:@""];
            key = [key stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            value = [value stringByReplacingOccurrencesOfString:@"@" withString:@""];
            value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            
            if (key.length > 0 && value.length > 0) {
                existingMappings[key] = value;
            }
        }
    }
    
    // 3. 合并新映射（不覆盖已有映射）
    for (NSString *key in newMappings) {
        if (!existingMappings[key]) {
            existingMappings[key] = newMappings[key];
        }
    }
    
    // 4. 重建方法
    NSMutableString *newMethod = [existingMethod mutableCopy];
    [newMethod replaceCharactersInRange:dictRange withString:[self stringFromDictionary:existingMappings]];
    
    return [newMethod copy];
}

// 辅助方法：从字典生成字符串
+ (NSString *)stringFromDictionary:(NSDictionary *)dictionary {
    NSMutableString *result = [NSMutableString string];
    NSArray *allKeys = dictionary.allKeys;
    
    for (NSInteger i = 0; i < allKeys.count; i++) {
        NSString *key = allKeys[i];
        NSString *value = dictionary[key];
        [result appendFormat:@"@\"%@\": @\"%@\"", key, value];
        
        if (i < allKeys.count - 1) {
            [result appendString:@", "];
        }
    }
    
    return [result copy];
}

// 检查路径是否在白名单中
+ (BOOL)isPath:(NSString *)path whitelisted:(NSArray *)whitelistedPods {
    for (NSString *whitelistedPod in whitelistedPods) {
        if ([path containsString:whitelistedPod]) {
            return YES;
        }
    }
    return NO;
}

+ (void)performGlobalReplacementsInProject:(NSString *)projectPath
                                 mappings:(NSDictionary<NSString *, NSString *> *)mappings
                           whitelistedPods:(NSArray<NSString *> *)whitelistedPods {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:projectPath];
    NSString *filePath;
    
    while ((filePath = [enumerator nextObject])) {
        // 跳过白名单路径
        if ([self isPath:filePath whitelisted:whitelistedPods]) {
            continue;
        }
        
        // 处理源代码文件
        NSString *extension = [filePath pathExtension];
        if ([extension isEqualToString:@"h"] ||
            [extension isEqualToString:@"m"] ||
            [extension isEqualToString:@"mm"] ||
            [extension isEqualToString:@"cpp"] ||
            [extension isEqualToString:@"c"]) {
            
            NSString *fullPath = [projectPath stringByAppendingPathComponent:filePath];
            [self safeReplaceInFile:fullPath mappings:mappings];
        }
    }
}

+ (void)safeReplaceInFile:(NSString *)filePath mappings:(NSDictionary *)mappings {
    NSError *error;
    NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"读取文件失败: %@", filePath);
        return;
    }
    
    // 1. 定位并保护所有modelCustomPropertyMapper方法的完整内容
    NSArray *protectedRanges = [self findCompleteMethodRangesInContent:fileContent];
    
    // 2. 执行全局替换（完全跳过被保护的方法）
    BOOL fileModified = NO;
    for (NSString *oldName in mappings.allKeys) {
        NSString *newName = mappings[oldName];
        
        NSString *pattern = [NSString stringWithFormat:@"\\b%@\\b", oldName];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        
        NSArray *matches = [regex matchesInString:fileContent options:0 range:NSMakeRange(0, fileContent.length)];
        
        for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
            BOOL isProtected = NO;
            
            // 检查是否在任何被保护的方法范围内
            for (NSValue *rangeValue in protectedRanges) {
                if (NSLocationInRange(match.range.location, [rangeValue rangeValue])) {
                    isProtected = YES;
                    break;
                }
            }
            
            if (!isProtected) {
                [fileContent replaceCharactersInRange:match.range withString:newName];
                fileModified = YES;
            }
        }
    }
    
    if (fileModified) {
        [fileContent writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            NSLog(@"写入文件失败: %@", filePath);
        }
    }
}

// 定位完整的modelCustomPropertyMapper方法范围（包括方法签名和实现体）
+ (NSArray *)findCompleteMethodRangesInContent:(NSString *)content {
    NSMutableArray *protectedRanges = [NSMutableArray array];
    
    // 匹配完整的modelCustomPropertyMapper方法（从方法声明开始到结束大括号）
    NSString *methodPattern = @"\\+\\s*\\(NSDictionary\\s*\\*\\s*\\)\\s*modelCustomPropertyMapper\\s*\\{[^}]*\\}";
    NSRegularExpression *methodRegex = [NSRegularExpression regularExpressionWithPattern:methodPattern options:0 error:nil];
    
    NSArray *matches = [methodRegex matchesInString:content options:0 range:NSMakeRange(0, content.length)];
    for (NSTextCheckingResult *match in matches) {
        [protectedRanges addObject:[NSValue valueWithRange:match.range]];
    }
    
    return [protectedRanges copy];
}







/////其他的
+ (NSArray<NSString *> *)extractModelPropertiesFromProjectPath:(NSString *)projectPath
                                                  pathWhitelist:(NSArray<NSString *> *)whitelist
                                                  pathBlacklist:(NSArray<NSString *> *)blacklist {
    // 1. 获取所有Model后缀的.h文件
    NSArray<NSString *> *modelHeaderFiles = [self findAllModelHeaderFilesInDirectory:projectPath
                                                                       pathWhitelist:whitelist
                                                                       pathBlacklist:blacklist];
    
    if (modelHeaderFiles.count == 0) {
        NSLog(@"No Model suffix .h files found in directory: %@", projectPath);
        return @[];
    }
    
    NSLog(@"Found %lu Model files:", (unsigned long)modelHeaderFiles.count);
    for (NSString *path in modelHeaderFiles) {
        NSLog(@"- %@", path.lastPathComponent);
    }
    
    // 2. 提取所有属性名（自动去重）
    NSMutableSet<NSString *> *propertyNamesSet = [NSMutableSet set];
    
    for (NSString *filePath in modelHeaderFiles) {
        NSArray<NSString *> *properties = [self extractPropertyNamesFromHeaderFile:filePath];
        [propertyNamesSet addObjectsFromArray:properties];
    }
    
    // 3. 排序后返回
    return [[propertyNamesSet allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

#pragma mark - Helper Methods

// 递归查找所有Model后缀的.h文件（支持白名单和黑名单）
+ (NSArray<NSString *> *)findAllModelHeaderFilesInDirectory:(NSString *)directory
                                              pathWhitelist:(NSArray<NSString *> *)whitelist
                                              pathBlacklist:(NSArray<NSString *> *)blacklist {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray<NSString *> *modelHeaderFiles = [NSMutableArray array];
    
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directory];
    
    NSString *filePath;
    while ((filePath = [enumerator nextObject])) {
        // 检查是否在黑名单中
        BOOL shouldSkip = NO;
        for (NSString *blackPath in blacklist) {
            if ([filePath containsString:blackPath]) {
                [enumerator skipDescendants];
                shouldSkip = YES;
                break;
            }
        }
        if (shouldSkip) continue;
        
        // 如果有白名单，检查是否在白名单中
        if (whitelist.count > 0) {
            BOOL inWhitelist = NO;
            for (NSString *whitePath in whitelist) {
                if ([filePath containsString:whitePath]) {
                    inWhitelist = YES;
                    break;
                }
            }
            if (!inWhitelist) {
                continue;
            }
        }
        
        // 检查是否是.h文件且以Model结尾
        if ([filePath.pathExtension isEqualToString:@"h"] && [self isModelFile:filePath.lastPathComponent]) {
            NSString *fullPath = [directory stringByAppendingPathComponent:filePath];
            [modelHeaderFiles addObject:fullPath];
        }
    }
    
    return [modelHeaderFiles copy];
}

// 从单个.h文件提取属性名
+ (NSArray<NSString *> *)extractPropertyNamesFromHeaderFile:(NSString *)filePath {
    NSError *error = nil;
    NSString *fileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"Error reading file %@: %@", filePath, error.localizedDescription);
        return @[];
    }
    
    NSMutableArray<NSString *> *propertyNames = [NSMutableArray array];
    
    // 增强版正则表达式，处理更多属性声明情况
    NSString *pattern = @"@property\\s*(\\([^)]+\\))?\\s*(\\w+(?:<[^>]+>)?\\s*\\*?\\s*\\*?)\\s*(\\w+)\\s*;";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    
    if (error) {
        NSLog(@"Error creating regex: %@", error.localizedDescription);
        return @[];
    }
    
    [regex enumerateMatchesInString:fileContent options:0 range:NSMakeRange(0, fileContent.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        if (result.numberOfRanges >= 4) {
            NSString *propertyName = [fileContent substringWithRange:[result rangeAtIndex:3]];
            [propertyNames addObject:propertyName];
        }
    }];
    
    return [propertyNames copy];
}

// 判断文件名是否以Model结尾（不区分大小写）
+ (BOOL)isModelFile:(NSString *)fileName {
    NSString *fileNameWithoutExtension = [fileName stringByDeletingPathExtension];
    NSRange suffixRange = [fileNameWithoutExtension rangeOfString:@"Model" options:NSLiteralSearch];
    return suffixRange.location != NSNotFound &&
           suffixRange.location == fileNameWithoutExtension.length - 5;
}
@end
