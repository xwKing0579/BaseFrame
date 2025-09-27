//
//  BFConfuseVariable.m
//  BaseFrame
//
//  Created by 王祥伟 on 2025/6/25.
//

#import "BFConfuseVariable.h"
#import "BFConfuseManager.h"

@implementation BFConfuseVariable

+ (NSDictionary *)mapVariableDict{
    return [self parseModuleMappingJSON:@"ivar"];
}

+ (NSDictionary *)mapVariableDict1{
    return [self parseModuleMappingJSON:@"ivar_xixi"];
}

+ (NSDictionary *)mapVariableDict4{
    return [self parseModuleMappingJSON:@"ivar_jingyuege"];
}

+ (NSDictionary *)mapSetVariableDict{
    return [self parseModuleMappingJSON:@"set"];
}

+ (NSDictionary *)mapSetVariableDict1{
    return [self parseModuleMappingJSON:@"set_xixi"];
}

+ (NSDictionary *)mapSetVariableDict4{
    return [self parseModuleMappingJSON:@"set_jingyuege"];
}

+ (void)safeReplaceContentInDirectory:(NSString *)directoryPath
                        renameMapping:(NSDictionary<NSString *, NSString *> *)renameMapping{
    NSString *methodMap = [BFConfuseManager readObfuscationMappingFileAtPath:directoryPath name:@"局部变量映射"];
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
    
    [BFConfuseManager writeData:renameMapping toPath:directoryPath fileName:@"混淆/局部变量映射"];
}

+ (void)safeReplaceContentInDirectory:(NSString *)directoryPath
                     renameSetMapping:(NSDictionary<NSString *, NSString *> *)renameSetMapping{
    NSString *methodMap = [BFConfuseManager readObfuscationMappingFileAtPath:directoryPath name:@"set变量量映射"];
    if (methodMap){
        NSData *jsonData = [methodMap dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
        renameSetMapping = dict;
    }
    
    // Validate inputs
    if (directoryPath.length == 0 || renameSetMapping.count == 0) {
        NSLog(@"Invalid parameters");
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directoryPath];
    
    // Pre-sort keys by length (longest first) to prevent partial replacements
    NSArray *sortedKeys = [renameSetMapping.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *key1, NSString *key2) {
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
                [self processFileAtPath:fullPath withSortedKeys:sortedKeys renameMapping:renameSetMapping];
            }
        }
    }
    
    [BFConfuseManager writeData:renameSetMapping toPath:directoryPath fileName:@"混淆/set变量量映射"];
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


+ (NSArray <NSString *> *)scanVariablesInDirectory:(NSString *)directoryPath {
    NSMutableSet<NSString *> *variables = [NSMutableSet set];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 1. 遍历目录下的所有 .m 和 .swift 文件（跳过 Pods 目录）
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directoryPath];
    NSString *filePath;
    while ((filePath = [enumerator nextObject])) {
        // 跳过 Pods 目录
        if ([filePath containsString:@"/Pods/"] || [filePath hasPrefix:@"Pods/"]) {
            [enumerator skipDescendants]; // 不递归遍历 Pods 子目录
            continue;
        }
        
        BOOL isDirectory = NO;
        NSString *fullPath = [directoryPath stringByAppendingPathComponent:filePath];
        [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
        
        if (!isDirectory && ([filePath hasSuffix:@".m"] || [filePath hasSuffix:@".swift"])) {
            // 2. 读取文件内容
            NSString *fileContent = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil];
            if (!fileContent) continue;
            
            // 3. 提取变量名（使用正则表达式）
            NSError *error = nil;
            NSRegularExpression *regex;
            
            if ([filePath hasSuffix:@".m"]) {
                // Objective-C 变量匹配（如 NSString *varName; 或 int varName;）
                regex = [NSRegularExpression regularExpressionWithPattern:@"\\b(?:NSString|NSArray|NSDictionary|int|float|BOOL)\\s*\\*?\\s*(\\w+)\\s*[;=,)]" options:0 error:&error];
            } else if ([filePath hasSuffix:@".swift"]) {
                // Swift 变量匹配（如 let varName = ... 或 var varName: Type）
                regex = [NSRegularExpression regularExpressionWithPattern:@"\\b(?:let|var)\\s+(\\w+)\\s*(?::|=)" options:0 error:&error];
            }
            
            if (error) {
                NSLog(@"Regex error: %@", error.localizedDescription);
                continue;
            }
            
            // 4. 匹配并存储变量名（过滤掉 _ 开头的变量）
            [regex enumerateMatchesInString:fileContent options:0 range:NSMakeRange(0, fileContent.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                if (result.range.location != NSNotFound) {
                    NSString *variableName = [fileContent substringWithRange:[result rangeAtIndex:1]];
                    if (![variableName hasPrefix:@"_"]) { // 忽略 _ 开头的变量
                        [variables addObject:variableName];
                    }
                }
            }];
        }
    }
    
    return variables.allObjects; // 返回去重后的变量集合
}



+ (NSArray *)needReplaceVariableName{
    return @[@"predicateFormat",@"data1",@"data2",@"data3",@"booksCache",@"sourceList",@"hero",@"passwordAgain",@"usbStr",@"vpnStr",@"titleLabels",@"afterContents",@"textList",@"replyMore",@"linkUrl",@"sourceSite",@"cmdString",@"secondTime",@"baseStr",@"arraySubViews",@"ipList",@"rString",@"gString",@"bString",@"base64String",@"adArray",@"auther",@"bookType",@"appStoreInfo",@"mobileRegex",@"uuidStr",@"propertyList",@"aesDecryptString",@"moreString",@"interfaceString",@"menuList",@"newPassword1",@"newPassword2",@"numberMap",@"shareURL",@"adLoaders",@"stringsPath",@"domainString",@"apiString",@"officialString",@"scoped",@"netCache",@"cacheList",@"matchIpMap",@"receiptPath",@"proxySettings",@"combine",@"isConvention",@"shareSwitch",@"dataString",@"spaceString",@"aString",@"readTime",@"sourceUrl",@"launchIV",@"bottomButtons",@"requestList",@"tobeString",@"readString",@"beforeContents",@"qrCodeUrl",@"profilePath",@"fontPath",@"firstTime",@"loginDict",@"collectBooks",@"respDict",@"readCount",@"catalogId",@"numberStr",@"timeArray"];
}


@end

