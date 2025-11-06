#import "BFCodeFormatter.h"

@implementation BFCodeFormatter

+ (void)formatProjectAtPath:(NSString *)projectPath {
    [self formatProjectAtPath:projectPath excludePods:YES preserveLogic:YES];
}

+ (void)formatProjectAtPath:(NSString *)projectPath excludePods:(BOOL)excludePods preserveLogic:(BOOL)preserveLogic {
    if (![[NSFileManager defaultManager] fileExistsAtPath:projectPath]) {
        NSLog(@"❌ 项目路径不存在: %@", projectPath);
        return;
    }
    
    NSLog(@"🔄 开始格式化项目: %@", projectPath);
    
    // 获取所有.h和.m文件
    NSArray *sourceFiles = [self findSourceFilesAtPath:projectPath excludePods:excludePods];
    
    for (NSString *filePath in sourceFiles) {
        [self formatFileComments:filePath preserveLogic:preserveLogic];
    }
    
    NSLog(@"✅ 代码格式化完成! 共处理 %lu 个文件", (unsigned long)sourceFiles.count);
}

+ (NSArray *)findSourceFilesAtPath:(NSString *)path excludePods:(BOOL)excludePods {
    NSMutableArray *sourceFiles = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:path];
    NSString *filePath;
    
    while ((filePath = [enumerator nextObject])) {
        // 排除Pods目录
        if (excludePods && [filePath containsString:@"Pods"]) {
            continue;
        }
        
        // 只处理.h和.m文件
        if ([[filePath pathExtension] isEqualToString:@"h"] ||
            [[filePath pathExtension] isEqualToString:@"m"]) {
            [sourceFiles addObject:[path stringByAppendingPathComponent:filePath]];
        }
    }
    
    return [sourceFiles copy];
}

+ (void)formatFileComments:(NSString *)filePath preserveLogic:(BOOL)preserveLogic {
    NSError *error;
    NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    if (error || !content) {
        NSLog(@"⚠️ 无法读取文件: %@", filePath);
        return;
    }
    
    // 按行分割
    NSMutableArray *lines = [[content componentsSeparatedByString:@"\n"] mutableCopy];
    BOOL hasChanges = NO;
    
    for (NSInteger i = 0; i < lines.count; i++) {
        NSString *originalLine = lines[i];
        NSString *formattedLine = [self formatCommentLine:originalLine];
        
        if (![formattedLine isEqualToString:originalLine]) {
            lines[i] = formattedLine;
            hasChanges = YES;
        }
    }
    
    // 如果有修改，写回文件
    if (hasChanges) {
        NSString *formattedContent = [lines componentsJoinedByString:@"\n"];
        [formattedContent writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        
        if (!error) {
            NSLog(@"✅ 已格式化: %@", [filePath lastPathComponent]);
        }
    }
}

+ (NSString *)formatCommentLine:(NSString *)line {
    // 移除首尾空格
    NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // 处理单行注释对齐
    if ([trimmedLine hasPrefix:@"//"]) {
        return [self formatSingleLineComment:trimmedLine];
    }
    
    // 处理多行注释对齐
    if ([trimmedLine hasPrefix:@"/*"] || [trimmedLine hasPrefix:@"*"]) {
        return [self formatMultiLineComment:trimmedLine];
    }
    
    // 非注释行保持原样
    return line;
}

+ (NSString *)formatSingleLineComment:(NSString *)comment {
    // 简单的注释对齐逻辑
    NSString *cleanComment = [comment stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // 确保注释符号后有一个空格
    if ([cleanComment hasPrefix:@"//"]) {
        NSString *afterSlashes = [cleanComment substringFromIndex:2];
        NSString *trimmedAfter = [afterSlashes stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (trimmedAfter.length > 0) {
            return [NSString stringWithFormat:@"// %@", trimmedAfter];
        }
    }
    
    return cleanComment;
}

+ (NSString *)formatMultiLineComment:(NSString *)comment {
    // 简单的多行注释对齐
    NSString *cleanComment = [comment stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([cleanComment hasPrefix:@"/*"]) {
        NSString *afterSymbol = [cleanComment substringFromIndex:2];
        NSString *trimmedAfter = [afterSymbol stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (trimmedAfter.length > 0 && ![trimmedAfter hasSuffix:@"*/"]) {
            return [NSString stringWithFormat:@"/* %@", trimmedAfter];
        }
    } else if ([cleanComment hasPrefix:@"*"]) {
        NSString *afterStar = [cleanComment substringFromIndex:1];
        NSString *trimmedAfter = [afterStar stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (trimmedAfter.length > 0) {
            return [NSString stringWithFormat:@"* %@", trimmedAfter];
        }
    }
    
    return cleanComment;
}


@end
