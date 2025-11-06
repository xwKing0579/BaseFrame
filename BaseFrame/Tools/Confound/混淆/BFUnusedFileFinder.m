#import "BFUnusedFileFinder.h"


@implementation BFUnusedFileFinder

+ (NSArray<NSString *> *)findUnusedFilesInProject:(NSString *)projectPath {
    return [self findUnusedFilesInProject:projectPath excludeDirectories:@[@"Pods", @".git", @"DerivedData", @"Carthage"]];
}

+ (NSArray<NSString *> *)findUnusedFilesInProject:(NSString *)projectPath excludeDirectories:(NSArray<NSString *> *)excludedDirs {
    NSMutableSet<NSString *> *allClasses = [NSMutableSet set];
    NSMutableSet<NSString *> *usedClasses = [NSMutableSet set];
    NSMutableDictionary<NSString *, NSString *> *classToFileMap = [NSMutableDictionary dictionary];
    
    // 收集所有类文件
    [self enumerateFilesInPath:projectPath excludedDirs:excludedDirs handler:^(NSString *filePath, BOOL *stop) {
        NSString *extension = [[filePath pathExtension] lowercaseString];
        if ([@[@"m", @"mm", @"h", @"swift"] containsObject:extension]) {
            NSString *className = [[filePath lastPathComponent] stringByDeletingPathExtension];
            [allClasses addObject:className];
            classToFileMap[className] = filePath;
        }
    }];
    
    // 分析使用情况
    [self enumerateFilesInPath:projectPath excludedDirs:excludedDirs handler:^(NSString *filePath, BOOL *stop) {
        NSString *extension = [[filePath pathExtension] lowercaseString];
        if ([@[@"m", @"mm", @"h", @"swift", @"xib", @"storyboard"] containsObject:extension]) {
            [self analyzeFileReferences:filePath usedClasses:usedClasses];
        }
    }];
    
    // 找出未使用的文件
    NSMutableArray<NSString *> *unusedFiles = [NSMutableArray array];
    for (NSString *className in allClasses) {
        if (![usedClasses containsObject:className] && classToFileMap[className]) {
            [unusedFiles addObject:classToFileMap[className]];
        }
    }
    
    return [unusedFiles sortedArrayUsingSelector:@selector(compare:)];
}

+ (NSArray<NSString *> *)findUnusedLibrariesInProject:(NSString *)projectPath {
    NSMutableArray<NSString *> *unusedLibraries = [NSMutableArray array];
    
    // 查找 Podfile.lock
    NSString *podfileLockPath = [projectPath stringByAppendingPathComponent:@"Podfile.lock"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:podfileLockPath]) {
        NSSet<NSString *> *allPods = [self parsePodDependencies:podfileLockPath];
        NSSet<NSString *> *usedPods = [self findUsedDependenciesInProject:projectPath];
        
        for (NSString *pod in allPods) {
            if (![usedPods containsObject:pod]) {
                [unusedLibraries addObject:pod];
            }
        }
    }
    
    return [unusedLibraries sortedArrayUsingSelector:@selector(compare:)];
}

#pragma mark - 私有方法

+ (void)enumerateFilesInPath:(NSString *)path excludedDirs:(NSArray<NSString *> *)excludedDirs handler:(void(^)(NSString *filePath, BOOL *stop))handler {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:path];
    
    BOOL shouldStop = NO;
    for (NSString *file in enumerator) {
        if (shouldStop) break;
        
        NSString *fullPath = [path stringByAppendingPathComponent:file];
        
        // 检查是否在排除目录中
        BOOL shouldExclude = NO;
        for (NSString *excludedDir in excludedDirs) {
            if ([fullPath containsString:excludedDir]) {
                shouldExclude = YES;
                [enumerator skipDescendants];
                break;
            }
        }
        if (shouldExclude) continue;
        
        BOOL isDirectory;
        [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
        
        if (!isDirectory) {
            handler(fullPath, &shouldStop);
        }
    }
}

+ (void)analyzeFileReferences:(NSString *)filePath usedClasses:(NSMutableSet<NSString *> *)usedClasses {
    NSError *error;
    NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (error) return;
    
    // 匹配各种导入和使用模式
    NSArray<NSString *> *patterns = @[
        @"#import\\s+[\"<]([^\"</>]+?)(?:\\.h)?[\">]",  // #import "Class" 或 #import <Framework/Class>
        @"@import\\s+([^;]+);",                         // @import Module;
        @"\\[([A-Za-z_][A-Za-z0-9_]*)\\s+",            // [Class alloc]
        @"([A-Za-z_][A-Za-z0-9_]*)\\s*\\*",            // Class *variable
        @"class\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*:",     // @interface Class :
        @"@objc\\s*\\(([^)]+)\\)",                     // @objc(ClassName)
        @"initWithNibName:@?\"([^\"]+)\""              // 加载XIB
    ];
    
    for (NSString *pattern in patterns) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        if (!regex) continue;
        
        [regex enumerateMatchesInString:content options:0 range:NSMakeRange(0, content.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            for (int i = 1; i < result.numberOfRanges; i++) {
                if ([result rangeAtIndex:i].location != NSNotFound) {
                    NSString *className = [content substringWithRange:[result rangeAtIndex:i]];
                    // 清理可能的框架前缀
                    if ([className containsString:@"/"]) {
                        className = [[className componentsSeparatedByString:@"/"] lastObject];
                    }
                    [usedClasses addObject:className];
                }
            }
        }];
    }
}

+ (NSSet<NSString *> *)parsePodDependencies:(NSString *)podfileLockPath {
    NSMutableSet<NSString *> *dependencies = [NSMutableSet set];
    
    NSError *error;
    NSString *content = [NSString stringWithContentsOfFile:podfileLockPath encoding:NSUTF8StringEncoding error:&error];
    if (error) return dependencies;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"-\\s+([^\\s/]+)" options:0 error:nil];
    [regex enumerateMatchesInString:content options:0 range:NSMakeRange(0, content.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        if (result.range.location != NSNotFound) {
            NSString *podName = [content substringWithRange:[result rangeAtIndex:1]];
            [dependencies addObject:podName];
        }
    }];
    
    return dependencies;
}

+ (NSSet<NSString *> *)findUsedDependenciesInProject:(NSString *)projectPath {
    NSMutableSet<NSString *> *usedDependencies = [NSMutableSet set];
    
    [self enumerateFilesInPath:projectPath excludedDirs:@[@"Pods", @".git", @"DerivedData"] handler:^(NSString *filePath, BOOL *stop) {
        NSString *extension = [[filePath pathExtension] lowercaseString];
        if ([@[@"m", @"mm", @"h", @"swift"] containsObject:extension]) {
            NSError *error;
            NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
            if (!error) {
                // 查找框架导入
                NSRegularExpression *frameworkRegex = [NSRegularExpression regularExpressionWithPattern:@"@import\\s+([^;]+);|#import\\s+[<]([^/]+)/" options:0 error:nil];
                [frameworkRegex enumerateMatchesInString:content options:0 range:NSMakeRange(0, content.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                    for (int i = 1; i < result.numberOfRanges; i++) {
                        if ([result rangeAtIndex:i].location != NSNotFound) {
                            NSString *framework = [content substringWithRange:[result rangeAtIndex:i]];
                            [usedDependencies addObject:framework];
                        }
                    }
                }];
            }
        }
    }];
    
    return usedDependencies;
}

@end
