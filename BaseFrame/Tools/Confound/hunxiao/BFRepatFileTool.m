//
//  BFRepatFileTool.m
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/1.
//

#import "BFRepatFileTool.h"

@implementation BFRepatFileTool

+ (NSDictionary *)findAllDuplicatesInProjectAtPath:(NSString *)projectPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableDictionary *fileMap = [NSMutableDictionary dictionary];
    
    // 递归遍历项目目录
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:projectPath];
    NSString *filePath;
    
    while ((filePath = [enumerator nextObject])) {
        NSString *fileNameWithExtension = [filePath lastPathComponent];
        
        // 跳过Pods目录（如果需要）
        if ([filePath containsString:@"/Pods/"]) {
            continue;
        }
        
        // 只检查特定类型的文件
        NSString *extension = [fileNameWithExtension pathExtension];
        if ([@[@"h", @"m", @"mm", @"c", @"cpp", @"swift", @"png", @"jpg", @"xib"] containsObject:extension.lowercaseString]) {
            
            if (!fileMap[fileNameWithExtension]) {
                fileMap[fileNameWithExtension] = [NSMutableArray array];
            }
            [fileMap[fileNameWithExtension] addObject:[projectPath stringByAppendingPathComponent:filePath]];
        }
    }
    
    // 过滤出真正的重复文件（相同完整文件名）
    NSMutableDictionary *trueDuplicates = [NSMutableDictionary dictionary];
    for (NSString *fileName in fileMap.allKeys) {
        NSArray *filePaths = fileMap[fileName];
        if (filePaths.count > 1) {
            trueDuplicates[fileName] = filePaths;
        }
    }
    
    return [trueDuplicates copy];
}

#pragma mark - 具体检查方法

// 查找重复文件名
+ (NSDictionary *)findDuplicateFilenamesAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableDictionary *filenameMap = [NSMutableDictionary dictionary];
    
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:path];
    NSString *filePath;
    
    while ((filePath = [enumerator nextObject])) {
        NSString *filename = [filePath lastPathComponent];
        NSString *extension = [filename pathExtension];
        
        // 只检查特定类型的文件
        if ([@[@"h", @"m", @"mm", @"c", @"cpp"] containsObject:extension.lowercaseString]) {
            NSString *basename = [filename stringByDeletingPathExtension];
            
            if (!filenameMap[basename]) {
                filenameMap[basename] = [NSMutableArray array];
            }
            [filenameMap[basename] addObject:[path stringByAppendingPathComponent:filePath]];
        }
    }
    
    return [self filterDuplicatesFromMap:filenameMap];
}

// 查找重复类定义
+ (NSArray *)findDuplicateClassDefinitions {
    NSMutableArray *duplicateClasses = [NSMutableArray array];
    NSMutableDictionary *classCountMap = [NSMutableDictionary dictionary];
    
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    for (int i = 0; i < numClasses; i++) {
        Class cls = classes[i];
        NSString *className = NSStringFromClass(cls);
        
        NSNumber *count = classCountMap[className];
        classCountMap[className] = @(count ? [count integerValue] + 1 : 1);
    }
    
    free(classes);
    
    for (NSString *className in classCountMap.allKeys) {
        if ([classCountMap[className] integerValue] > 1) {
            [duplicateClasses addObject:className];
        }
    }
    
    return [duplicateClasses copy];
}

// 查找重复资源文件
+ (NSDictionary *)findDuplicateResourceFilesAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableDictionary *resourceMap = [NSMutableDictionary dictionary];
    
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:path];
    NSString *filePath;
    
    while ((filePath = [enumerator nextObject])) {
        NSString *filename = [filePath lastPathComponent];
        NSString *extension = [filename pathExtension];
        
        // 检查常见资源文件类型
        if ([@[@"png", @"jpg", @"jpeg", @"gif", @"xib", @"storyboard", @"plist"] containsObject:extension.lowercaseString]) {
            if (!resourceMap[filename]) {
                resourceMap[filename] = [NSMutableArray array];
            }
            [resourceMap[filename] addObject:[path stringByAppendingPathComponent:filePath]];
        }
    }
    
    return [self filterDuplicatesFromMap:resourceMap];
}

// 检查重复符号（需要项目编译后）
+ (NSDictionary *)checkForDuplicateSymbolsAtPath:(NSString *)projectPath {
    NSString *linkMapPath = [projectPath stringByAppendingPathComponent:@"Build/Intermediates.noindex/YourProject.build/Debug/YourProject.build/YourProject-LinkMap-normal-arm64.txt"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:linkMapPath]) {
        NSLog(@"LinkMap文件不存在，请在Xcode中启用Write Link Map File选项");
        return @{};
    }
    
    NSString *linkMapContent = [NSString stringWithContentsOfFile:linkMapPath encoding:NSUTF8StringEncoding error:nil];
    NSMutableDictionary *symbolMap = [NSMutableDictionary dictionary];
    
    if (linkMapContent) {
        NSArray *lines = [linkMapContent componentsSeparatedByString:@"\n"];
        
        for (NSString *line in lines) {
            if ([line rangeOfString:@"0x"].location != NSNotFound) {
                NSArray *components = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if (components.count >= 3) {
                    NSString *symbol = components.lastObject;
                    NSNumber *count = symbolMap[symbol];
                    symbolMap[symbol] = @(count ? [count integerValue] + 1 : 1);
                }
            }
        }
    }
    
    return [self filterDuplicatesFromMap:symbolMap];
}

#pragma mark - 辅助方法

// 从字典中过滤出重复项
+ (NSDictionary *)filterDuplicatesFromMap:(NSDictionary *)map {
    NSMutableDictionary *duplicates = [NSMutableDictionary dictionary];
    
    for (NSString *key in map.allKeys) {
        NSArray *items = map[key];
        if (items.count > 1) {
            duplicates[key] = items;
        }
    }
    
    return [duplicates copy];
}



+ (void)removeCommentLinesInDirectory:(NSString *)directoryPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directoryPath];
    
    NSString *filePath;
    while ((filePath = [enumerator nextObject])) {
        // 跳过 Pods 目录
        if ([filePath containsString:@"/Pods/"]) {
            continue;
        }
        
        NSString *fullPath = [directoryPath stringByAppendingPathComponent:filePath];
        NSString *fileExtension = [filePath pathExtension];
        
        // 只处理 Objective-C/C/C++ 源文件
        if ([@[@"h", @"m", @"mm", @"c", @"cpp"] containsObject:fileExtension]) {
            [self processFileAtPath:fullPath];
        }
    }
}

+ (void)processFileAtPath:(NSString *)filePath {
    NSError *error;
    NSString *fileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"读取文件失败: %@, 错误: %@", filePath, error.localizedDescription);
        return;
    }
    
    NSMutableArray *lines = [NSMutableArray arrayWithArray:[fileContent componentsSeparatedByString:@"\n"]];
    NSMutableArray *cleanLines = [NSMutableArray array];
    BOOL fileModified = NO;
    
    for (NSString *line in lines) {
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // 保留不以 "//:" 开头的行
        if (![trimmedLine hasPrefix:@"//:"]) {
            [cleanLines addObject:line];
        } else {
            fileModified = YES;
        }
    }
    
    if (fileModified) {
        NSString *newContent = [cleanLines componentsJoinedByString:@"\n"];
        [newContent writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        
        if (error) {
            NSLog(@"写入文件失败: %@, 错误: %@", filePath, error.localizedDescription);
        } else {
            NSLog(@"已清理文件: %@", filePath);
        }
    }
}
@end
