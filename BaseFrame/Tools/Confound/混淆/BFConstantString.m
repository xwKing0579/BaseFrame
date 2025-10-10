//
//  BFConstantString.m
//  BaseFrame
//
//  Created by 王祥伟 on 2025/7/14.
//

#import "BFConstantString.h"
#import "BFConfuseManager.h"

@implementation BFConstantString

+ (NSDictionary *)mapConstantStringDict{
    return [self parseModuleMappingJSON:@"constantString"];
}

+ (NSDictionary *)mapConstantStringDict1{
    return [self parseModuleMappingJSON:@"constantString_xixi"];
}

+ (NSDictionary *)mapConstantStringDict4{
    return [self parseModuleMappingJSON:@"constantString_jingyuege"];
}

+ (NSDictionary *)mapConstantStringDict103{
    return [self parseModuleMappingJSON:@"constantString_yueyi 3"];
}

+ (void)safeReplaceContentInDirectory:(NSString *)directoryPath
                        renameMapping:(NSDictionary<NSString *, NSString *> *)renameMapping{
    NSString *methodMap = [BFConfuseManager readObfuscationMappingFileAtPath:directoryPath name:@"常量字符串映射"];
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
    
    [BFConfuseManager writeData:renameMapping toPath:directoryPath fileName:@"混淆/常量字符串映射"];
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




+ (void)replaceStringsInProjectAtPath:(NSString *)projectPath{
    [self replaceStringsInProjectAtPath:projectPath withDictionary:[self parseModuleMappingJSON:@"constant"] excludePodfiles:YES];
}

+ (void)replaceStringsInProjectAtPath:(NSString *)projectPath
                      withDictionary:(NSDictionary *)replacementDict
                     excludePodfiles:(BOOL)excludePods {
    
    // 获取项目目录下所有 .m 和 .swift 文件（排除Pods目录）
    NSArray *fileExtensions = @[@"m", @"swift"];
    NSArray *files = [self findFilesInDirectory:projectPath
                                withExtensions:fileExtensions
                               excludePodfiles:excludePods];
    
    // 遍历所有文件
    for (NSString *filePath in files) {
        [self processFileAtPath:filePath withDictionary:replacementDict];
    }
}

+ (NSArray *)findFilesInDirectory:(NSString *)directoryPath
                   withExtensions:(NSArray *)extensions
                  excludePodfiles:(BOOL)excludePods {
    
    NSMutableArray *foundFiles = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directoryPath];
    NSString *filePath;
    
    while ((filePath = [enumerator nextObject])) {
        // 跳过Pods目录（如果启用排除）
        if (excludePods && [filePath containsString:@"/Pods/"]) {
            [enumerator skipDescendants]; // 跳过整个Pods目录
            continue;
        }
        
        NSString *fileExtension = [filePath pathExtension].lowercaseString;
        
        if ([extensions containsObject:fileExtension]) {
            NSString *fullPath = [directoryPath stringByAppendingPathComponent:filePath];
            [foundFiles addObject:fullPath];
        }
    }
    
    return [foundFiles copy];
}

// 以下 processFileAtPath:withDictionary: 方法与之前相同
+ (void)processFileAtPath:(NSString *)filePath withDictionary:(NSDictionary *)replacementDict {
    NSError *error;
    NSMutableString *fileContents = [NSMutableString stringWithContentsOfFile:filePath
                                                                    encoding:NSUTF8StringEncoding
                                                                       error:&error];
    if (error) {
        NSLog(@"Error reading file %@: %@", filePath, error.localizedDescription);
        return;
    }
    
    BOOL fileModified = NO;
    
    for (NSString *key in replacementDict.allKeys) {
        NSString *value = replacementDict[key];
        NSString *searchString = [NSString stringWithFormat:@"@\"%@\"", value];
        NSString *replacementString = [NSString stringWithFormat:@"DBConstantString.%@", key];
        
        NSUInteger replaceCount = [fileContents replaceOccurrencesOfString:searchString
                                                               withString:replacementString
                                                                  options:NSLiteralSearch
                                                                    range:NSMakeRange(0, fileContents.length)];
        
        if (replaceCount > 0) {
            fileModified = YES;
            NSLog(@"Replaced %lu occurrence(s) of '%@' with '%@' in %@",
                  (unsigned long)replaceCount, value, replacementString, filePath.lastPathComponent);
        }
    }
    
    if (fileModified) {
        [fileContents writeToFile:filePath
                       atomically:YES
                         encoding:NSUTF8StringEncoding
                            error:&error];
        
        if (error) {
            NSLog(@"Error writing file %@: %@", filePath, error.localizedDescription);
        }
    }
}



//搜索 #define修饰的单词
+ (NSArray<NSString *> *)findMacrosInProjectPath:(NSString *)projectPath {
    NSMutableArray<NSString *> *macros = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 排除的目录
    NSArray *excludedDirectories = @[@"Pods", @".framework"];
    
    // 获取项目路径下所有文件
    NSArray *allFiles = [self getAllFilesInDirectory:projectPath excludedDirectories:excludedDirectories fileManager:fileManager];
    
    // 宏定义的正则表达式模式
    NSString *pattern = @"^\\s*#define\\s+([a-zA-Z_][a-zA-Z0-9_]*)\\b";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionAnchorsMatchLines error:nil];
    
    for (NSString *filePath in allFiles) {
        // 只检查头文件和实现文件
        if ([self isSourceFile:filePath]) {
            NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
            if (content) {
                [self findMacrosInContent:content withRegex:regex addToArray:macros];
            }
        }
    }
    
    // 去重并排序
    NSArray *uniqueMacros = [[[NSSet setWithArray:macros] allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    return uniqueMacros;
}

#pragma mark - Helper Methods

// 递归获取目录下所有文件，排除指定目录
+ (NSArray<NSString *> *)getAllFilesInDirectory:(NSString *)directoryPath
                           excludedDirectories:(NSArray<NSString *> *)excludedDirectories
                                   fileManager:(NSFileManager *)fileManager {
    
    NSMutableArray *allFiles = [NSMutableArray array];
    NSURL *directoryURL = [NSURL fileURLWithPath:directoryPath];
    
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:directoryURL
                                          includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                             options:NSDirectoryEnumerationSkipsHiddenFiles
                                                        errorHandler:^BOOL(NSURL *url, NSError *error) {
        return YES;
    }];
    
    for (NSURL *fileURL in enumerator) {
        NSNumber *isDirectory;
        [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
        
        if (![isDirectory boolValue]) {
            NSString *filePath = [fileURL path];
            
            // 检查是否在排除目录中
            BOOL shouldExclude = NO;
            for (NSString *excludedDir in excludedDirectories) {
                if ([filePath containsString:excludedDir]) {
                    shouldExclude = YES;
                    break;
                }
            }
            
            if (!shouldExclude) {
                [allFiles addObject:filePath];
            }
        }
    }
    
    return [allFiles copy];
}

// 判断是否为源代码文件
+ (BOOL)isSourceFile:(NSString *)filePath {
    NSString *extension = [[filePath pathExtension] lowercaseString];
    NSArray *sourceExtensions = @[@"h", @"m", @"mm", @"c", @"cpp", @"cc", @"cxx"];
    return [sourceExtensions containsObject:extension];
}

// 在文件内容中查找宏定义
+ (void)findMacrosInContent:(NSString *)content
                  withRegex:(NSRegularExpression *)regex
                 addToArray:(NSMutableArray<NSString *> *)macros {
    
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:content
                                                              options:0
                                                                range:NSMakeRange(0, content.length)];
    
    for (NSTextCheckingResult *match in matches) {
        if (match.numberOfRanges > 1) {
            NSRange macroNameRange = [match rangeAtIndex:1];
            NSString *macroName = [content substringWithRange:macroNameRange];
            
            if (macroName.length > 0) {
                [macros addObject:macroName];
            }
        }
    }
}

@end
