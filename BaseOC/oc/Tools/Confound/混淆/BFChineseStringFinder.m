//
//  BFChineseStringFinder.m
//  BaseFrame
//
//  Created by 王祥伟 on 2025/6/9.
//

#import "BFChineseStringFinder.h"
#import "BFConfuseManager.h"
#import "BFConfuseFile.h"
@implementation BFChineseStringFinder

+ (BOOL)isChineseCharacter:(unichar)character {
    // 中文字符的Unicode范围
    if ((character >= 0x4E00 && character <= 0x9FFF) || // 基本汉字
        (character >= 0x3400 && character <= 0x4DBF) || // 扩展A
        (character >= 0x20000 && character <= 0x2A6DF) || // 扩展B
        (character >= 0x2A700 && character <= 0x2B73F) || // 扩展C
        (character >= 0x2B740 && character <= 0x2B81F) || // 扩展D
        (character >= 0x2B820 && character <= 0x2CEAF) || // 扩展E
        (character >= 0xF900 && character <= 0xFAFF) || // 兼容汉字
        (character >= 0x3300 && character <= 0x33FF)) { // 兼容符号
        return YES;
    }
    return NO;
}

+ (BOOL)containsChineseCharacters:(NSString *)string {
    for (int i = 0; i < [string length]; i++) {
        unichar character = [string characterAtIndex:i];
        if ([self isChineseCharacter:character]) {
            return YES;
        }
    }
    return NO;
}

+ (void)extractQuotedStringsFromLine:(NSString *)line results:(NSMutableSet *)results {
    NSError *error = nil;
    // 正则表达式匹配 @"" 内的内容
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"@\"(.*?)\""
                                                                         options:0
                                                                           error:&error];
    if (error) {
        NSLog(@"正则表达式错误: %@", error);
        return;
    }
    
    NSArray *matches = [regex matchesInString:line
                                     options:0
                                       range:NSMakeRange(0, [line length])];
    
    for (NSTextCheckingResult *match in matches) {
        if (match.numberOfRanges > 1) {
            NSRange range = [match rangeAtIndex:1]; // 获取第一个捕获组的内容
            NSString *quotedString = [line substringWithRange:range];
            
            if ([self containsChineseCharacters:quotedString]) {
                [results addObject:quotedString];
            }
        }
    }
}

+ (void)processFileAtPath:(NSString *)filePath results:(NSMutableSet *)results {
    NSError *error = nil;
    NSString *fileContent = [NSString stringWithContentsOfFile:filePath
                                                     encoding:NSUTF8StringEncoding
                                                        error:&error];
    
    if (error) {
        // 尝试其他编码
        fileContent = [NSString stringWithContentsOfFile:filePath
                                               encoding:NSUTF16StringEncoding
                                                  error:&error];
        if (error) {
            NSLog(@"无法读取文件: %@, 错误: %@", filePath, error);
            return;
        }
    }
    
    NSArray *lines = [fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    for (NSString *line in lines) {
        [self extractQuotedStringsFromLine:line results:results];
    }
}

+ (BOOL)shouldSkipDirectory:(NSString *)filePath {
    NSArray *skipDirectories = @[@"Pods/", @"ThirdParty/", @"Vendor/", @"Carthage/"];
    for (NSString *dir in skipDirectories) {
        if ([filePath containsString:dir]) {
            return YES;
        }
    }
    return NO;
}

+ (void)findChineseStringsInDirectory:(NSString *)directoryPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableSet *results = [NSMutableSet set]; // 使用Set自动去重
    
    // 只处理.h和.m文件
    NSArray *validExtensions = @[@"h", @"m", @"mm"];
    
    // 获取目录下所有文件
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directoryPath];
    NSString *file;
    
    while ((file = [enumerator nextObject])) {
        if ([self shouldSkipDirectory:file]) {
            [enumerator skipDescendants];
            continue;
        }
        NSString *fullPath = [directoryPath stringByAppendingPathComponent:file];
        BOOL isDirectory;
        [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
        
        if (!isDirectory && [validExtensions containsObject:[file pathExtension]]) {
            [self processFileAtPath:fullPath results:results];
        }
    }
    
    // 打印结果
    NSLog(@"找到 %lu 条包含中文字符串的引用内容(已去重):", (unsigned long)results.count);
    NSMutableDictionary *finderDict = [NSMutableDictionary dictionary];
    for (NSString *word in results) {
        [finderDict setValue:word forKey:word];
    }
  
    [BFConfuseManager writeData:finderDict.yy_modelToJSONString toPath:directoryPath fileName:@"检索中文"];
}


@end
