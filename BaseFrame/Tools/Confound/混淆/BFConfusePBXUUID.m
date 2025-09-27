//
//  BFConfusePBXUUID.m
//  BaseFrame
//
//  Created by 王祥伟 on 2025/7/30.
//

#import "BFConfusePBXUUID.h"
#import <CommonCrypto/CommonCrypto.h>
@implementation BFConfusePBXUUID
+ (void)obfuscateUUIDsInProjectAtPath:(NSString *)projectPath {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDirectory;
    
    if (![fm fileExistsAtPath:projectPath isDirectory:&isDirectory]) {
        NSLog(@"❌ Path does not exist: %@", projectPath);
        return;
    }
    
    if ([projectPath.pathExtension isEqualToString:@"xcodeproj"] && isDirectory) {
        NSString *pbxPath = [projectPath stringByAppendingPathComponent:@"project.pbxproj"];
        [self obfuscateUUIDsInPBXFile:pbxPath];
    } else if (isDirectory) {
        [self recursiveFindAndObfuscatePBXFilesInDirectory:projectPath];
    } else {
        NSLog(@"⚠️ Invalid project path: %@", projectPath);
    }
}

+ (void)obfuscateUUIDsInPBXFile:(NSString *)filePath {
    if (![filePath.lastPathComponent isEqualToString:@"project.pbxproj"]) {
        NSLog(@"⚠️ Not a project.pbxproj file: %@", filePath);
        return;
    }
    
    NSLog(@"🔧 Processing: %@", filePath);
    
    // 创建备份
    if (![self createBackupForFile:filePath]) {
        return;
    }
    
    // 读取内容
    NSError *error;
    NSMutableString *content = [NSMutableString stringWithContentsOfFile:filePath
                                                              encoding:NSUTF8StringEncoding
                                                                 error:&error];
    if (error) {
        NSLog(@"❌ Error reading file: %@", error);
        return;
    }
    
    // 执行替换
    NSInteger replaceCount = [self replaceAllUUIDsInContent:content];
    
    // 保存文件
    if (replaceCount > 0) {
        [content writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            NSLog(@"❌ Error writing file: %@", error);
        } else {
            NSLog(@"✅ Replaced %ld UUIDs in %@", (long)replaceCount, filePath.lastPathComponent);
        }
    } else {
        NSLog(@"ℹ️ No UUIDs found in %@", filePath.lastPathComponent);
    }
}

#pragma mark - Private Methods

+ (NSString *)generateXcodeUUID {
    uuid_t uuid;
    uuid_generate_random(uuid);
    NSMutableString *uuidString = [NSMutableString stringWithCapacity:24];
    for (int i = 0; i < 12; i++) {
        [uuidString appendFormat:@"%02X", uuid[i]];
    }
    return [uuidString substringToIndex:24];
}

+ (BOOL)createBackupForFile:(NSString *)filePath {
    NSString *backupPath = [filePath stringByAppendingString:@".backup"];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if ([fm fileExistsAtPath:backupPath]) {
        NSLog(@"ℹ️ Backup already exists: %@", backupPath);
        return YES;
    }
    
    NSError *error;
    [fm copyItemAtPath:filePath toPath:backupPath error:&error];
    if (error) {
        NSLog(@"❌ Failed to create backup: %@", error);
        return NO;
    }
    
    return YES;
}

+ (NSInteger)replaceAllUUIDsInContent:(NSMutableString *)content {
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[0-9A-F]{24}"
                                                                         options:0
                                                                           error:&error];
    if (error) {
        NSLog(@"❌ Regex error: %@", error);
        return 0;
    }
    
    __block NSInteger replaceCount = 0;
    NSMutableDictionary *uuidMap = [NSMutableDictionary dictionary];
    
    [regex enumerateMatchesInString:content
                           options:0
                             range:NSMakeRange(0, content.length)
                        usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSString *oldUUID = [content substringWithRange:result.range];
        
        if (!uuidMap[oldUUID]) {
            uuidMap[oldUUID] = [self generateXcodeUUID];
            replaceCount++;
        }
    }];
    
    [uuidMap enumerateKeysAndObjectsUsingBlock:^(NSString *oldUUID, NSString *newUUID, BOOL *stop) {
        [content replaceOccurrencesOfString:oldUUID
                                withString:newUUID
                                   options:0
                                     range:NSMakeRange(0, content.length)];
    }];
    
    return replaceCount;
}

+ (void)recursiveFindAndObfuscatePBXFilesInDirectory:(NSString *)directory {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:directory];
    
    for (NSString *path in enumerator) {
        if ([path.lastPathComponent isEqualToString:@"project.pbxproj"]) {
            NSString *fullPath = [directory stringByAppendingPathComponent:path];
            [self obfuscateUUIDsInPBXFile:fullPath];
            
            // 跳过 Pods 目录
            if ([path containsString:@"Pods/"]) {
                [enumerator skipDescendants];
            }
        }
    }
}
@end
