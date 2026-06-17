//
//  BFModifyProject.m
//  OCProject
//
//  Created by 王祥伟 on 2024/3/29.
//

#import "BFModifyProject.h"
#import "BFTinyPngManger.h"
#import <sys/stat.h>
@implementation BFModifyProject


+ (void)modifyProjectName:(NSString *)projectPath oldName:(NSString *)oldName newName:(NSString *)newName{
    [self modifyFilesClassName:projectPath oldName:[oldName stringByAppendingString:@"-Swift.h"] newName:[newName stringByAppendingString:@"-Swift.h"]];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDirectory;
    NSString *podfilePath = [projectPath stringByAppendingPathComponent:@"Podfile"];
    if ([fm fileExistsAtPath:podfilePath isDirectory:&isDirectory] && !isDirectory) {
        [self replacePodfileContent:podfilePath oldString:oldName newString:newName];
    }
    
    NSString *projectPathPath = [projectPath stringByAppendingPathComponent:oldName];
    NSString *xcodeprojFilePath = [projectPathPath stringByAppendingPathExtension:@"xcodeproj"];
    NSString *xcworkspaceFilePath = [projectPathPath stringByAppendingPathExtension:@"xcworkspace"];
    
    if ([fm fileExistsAtPath:xcodeprojFilePath isDirectory:&isDirectory] && isDirectory) {
        NSString *projectPbxprojFilePath = [xcodeprojFilePath stringByAppendingPathComponent:@"project.pbxproj"];
        if ([fm fileExistsAtPath:projectPbxprojFilePath]) {
            [self resetBridgingHeaderFileName:projectPbxprojFilePath oldName:[oldName stringByAppendingString:@"-Bridging-Header"] newName:[newName stringByAppendingString:@"-Bridging-Header"]];
            [self resetEntitlementsFileName:projectPbxprojFilePath oldName:oldName newName:newName];
            [self replaceProjectFileContent:projectPbxprojFilePath oldName:oldName newName:newName];
        }
        NSString *contentsXcworkspacedataFilePath = [xcodeprojFilePath stringByAppendingPathComponent:@"project.xcworkspace/contents.xcworkspacedata"];
        if ([fm fileExistsAtPath:contentsXcworkspacedataFilePath]) {
            [self replaceProjectFileContent:contentsXcworkspacedataFilePath oldName:oldName newName:newName];
        }
        NSString *xcuserdataFilePath = [xcodeprojFilePath stringByAppendingPathComponent:@"xcuserdata"];
        if ([fm fileExistsAtPath:xcuserdataFilePath]) {
            [fm removeItemAtPath:xcuserdataFilePath error:nil];
        }
        [self renameFile:xcodeprojFilePath newPath:[[projectPath stringByAppendingPathComponent:newName] stringByAppendingPathExtension:@"xcodeproj"]];
    }
    
    if ([fm fileExistsAtPath:xcworkspaceFilePath isDirectory:&isDirectory] && isDirectory) {
        NSString *contentsXcworkspacedataFilePath = [xcworkspaceFilePath stringByAppendingPathComponent:@"contents.xcworkspacedata"];
        if ([fm fileExistsAtPath:contentsXcworkspacedataFilePath]) {
            [self replaceProjectFileContent:contentsXcworkspacedataFilePath oldName:oldName newName:newName];
        }
        NSString *xcuserdataFilePath = [xcworkspaceFilePath stringByAppendingPathComponent:@"xcuserdata"];
        if ([fm fileExistsAtPath:xcuserdataFilePath]) {
            [fm removeItemAtPath:xcuserdataFilePath error:nil];
        }
        [self renameFile:xcworkspaceFilePath newPath:[[projectPath stringByAppendingPathComponent:newName] stringByAppendingPathExtension:@"xcworkspace"]];
    }
    
    if ([fm fileExistsAtPath:projectPathPath isDirectory:&isDirectory] && isDirectory) {
        [self renameFile:projectPathPath newPath:[projectPath stringByAppendingPathComponent:newName]];
    }
}

static NSMutableDictionary *_fileNameDict;
static NSMutableSet *_filePathSet;
+ (void)modifyFilePrefix:(NSString *)projectPath oldPrefix:(NSString *)oldPrefix newPrefix:(NSString *)newPrefix{
    [self modifyFilePrefix:projectPath otherPrefix:NO oldPrefix:oldPrefix newPrefix:newPrefix];
}

+ (void)modifyFilePrefix:(NSString *)projectPath otherPrefix:(BOOL)otherPrefix oldPrefix:(NSString *)oldPrefix newPrefix:(NSString *)newPrefix{
    _fileNameDict = [NSMutableDictionary dictionary];
    _filePathSet = [NSMutableSet set];
    [self modifyClassDict:projectPath otherPrefix:otherPrefix oldPrefix:oldPrefix newPrefix:newPrefix];
    
    [self modifyClassNamePrefix:projectPath classReplaceDict:_fileNameDict];
    for (NSString *filePath in _filePathSet.allObjects) {
        NSString *fileName = filePath.lastPathComponent;
        NSString *fileString = filePath.stringByDeletingLastPathComponent;
        [self renameFile:filePath newPath:[fileString stringByAppendingPathComponent:[fileName stringByReplacingOccurrencesOfString:oldPrefix withString:newPrefix]]];
    }
}

+ (void)modifyClassDict:(NSString *)projectPath otherPrefix:(BOOL)otherPrefix oldPrefix:(NSString *)oldPrefix newPrefix:(NSString *)newPrefix{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:projectPath error:nil];
    BOOL isDirectory;
    
    for (NSString *filePath in files) {
        if ([filePath isEqualToString:@"Pods"]) continue;
        NSString *path = [projectPath stringByAppendingPathComponent:filePath];
        
        if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
            [self modifyClassDict:path otherPrefix:otherPrefix oldPrefix:oldPrefix newPrefix:newPrefix];
            continue;
        }
        
        NSString *fileName = filePath.lastPathComponent;
        if ([fileName hasSuffix:@".h"] || [fileName hasSuffix:@".m"] || [fileName hasSuffix:@".mm"] || [fileName hasSuffix:@".pch"] || [fileName hasSuffix:@".swift"] || [fileName hasSuffix:@".xib"] || [fileName hasSuffix:@".storyboard"] || [fileName hasSuffix:@".xcodeproj"] || [fileName hasSuffix:@".bundle"]) {
            NSArray *classNames = [fileName.stringByDeletingPathExtension componentsSeparatedByString:@"+"];
            for (NSString *className in classNames) {
                if ([className hasPrefix:oldPrefix]){
                    NSString *newClassName = [className stringByReplacingOccurrencesOfString:oldPrefix withString:newPrefix];
                    if (className.suffixRemove.length > 2) [_fileNameDict setValue:newClassName.suffixRemove forKey:className.suffixRemove];
                    [_filePathSet addObject:path];
                }
            }
            
            if ([fileName hasSuffix:@".h"]){
                NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
                
                ///其他类
                NSArray *fileNames = [fileContent regexPattern:@"@interface\\s+([^:\\r\\n]+):"];
                for (NSString *string in fileNames) {
                    NSString *className = string.whitespace;
                    if ([className hasPrefix:oldPrefix]){
                        NSString *newClassName = [className stringByReplacingOccurrencesOfString:oldPrefix withString:newPrefix];
                        if (className.suffixRemove.length > 2) [_fileNameDict setValue:newClassName.suffixRemove forKey:className.suffixRemove];
                    }
                }
                
                ///其他类别
                NSArray *categoryFileNames = [fileContent regexPattern:@"@interface\\s+([^:\\r\\n]+)("];
                for (NSString *string in categoryFileNames) {
                    NSString *className = string.whitespace;
                    if ([className hasPrefix:oldPrefix]){
                        NSString *newClassName = [className stringByReplacingOccurrencesOfString:oldPrefix withString:newPrefix];
                        if (className.suffixRemove.length > 2) [_fileNameDict setValue:newClassName.suffixRemove forKey:className.suffixRemove];
                    }
                }
            }
            
            if (!otherPrefix) continue;
            [_fileNameDict setValue:[NSString stringWithFormat:@"%@_",newPrefix.lowercaseString] forKey:[NSString stringWithFormat:@"%@_",oldPrefix.lowercaseString]];
            if ([fileName hasSuffix:@".h"] || [fileName hasSuffix:@".m"] || [fileName hasSuffix:@".mm"] || [fileName hasSuffix:@".swift"] || [fileName hasSuffix:@".pch"] || [fileName hasSuffix:@".bundle"]) {
                NSError *error = nil;
                NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
                NSArray *words = [fileContent filterString];
                for (NSString *matchString in words) {
                    if ([matchString hasPrefix:oldPrefix]) {
                        NSString *newClassName = [matchString stringByReplacingOccurrencesOfString:oldPrefix withString:newPrefix];
                        if (matchString.suffixRemove.length > 2) [_fileNameDict setValue:newClassName.suffixRemove forKey:matchString.suffixRemove];
                    }
                }
            }
        }
    }
}

+ (void)modifyClassNamePrefix:(NSString *)projectPath classReplaceDict:(NSDictionary *)classReplaceDict{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:projectPath error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        if ([filePath isEqualToString:@"Pods"]) continue;
        NSString *path = [projectPath stringByAppendingPathComponent:filePath];
        if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
            [self modifyClassNamePrefix:path classReplaceDict:classReplaceDict];
            continue;
        }
        
        NSString *fileName = filePath.lastPathComponent;
        if ([fileName hasSuffix:@".h"] || [fileName hasSuffix:@".m"] || [fileName hasSuffix:@".mm"] || [fileName hasSuffix:@".pch"] || [fileName hasSuffix:@".swift"] || [fileName hasSuffix:@".xib"] || [fileName hasSuffix:@".storyboard"] || [fileName isEqualToString:@"project.pbxproj"]) {
            NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
            NSArray *allClassNames = classReplaceDict.allKeys;
            for (NSString *className in allClassNames) {
                if ([fileContent containsString:className]) fileContent = [fileContent stringByReplacingOccurrencesOfString:className withString:classReplaceDict[className]].mutableCopy;
            }
            [fileContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }
}

+ (void)modifyFilesClassName:(NSString *)projectPath oldName:(NSString *)oldName newName:(NSString *)newName{
    // 文件内容 Const > DDConst (h,m,swift,xib,storyboard)
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:projectPath error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        NSString *path = [projectPath stringByAppendingPathComponent:filePath];
        if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
            [self modifyFilesClassName:path oldName:oldName newName:newName];
            continue;
        }
        
        NSString *fileName = filePath.lastPathComponent;
        if ([fileName hasSuffix:@".h"] || [fileName hasSuffix:@".m"] || [fileName hasSuffix:@".mm"] || [fileName hasSuffix:@".swift"] || [fileName hasSuffix:@".xib"] || [fileName hasSuffix:@".storyboard"]) {
            
            NSError *error = nil;
            NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                NSLog(@"打开文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
                abort();
            }
            
            NSString *regularExpression = [NSString stringWithFormat:@"\\b%@\\b", oldName];
            BOOL isChanged = [self regularReplacement:regularExpression oldString:fileContent newString:newName];
            if (!isChanged) continue;
            error = nil;
            [fileContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                NSLog(@"保存文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
                abort();
            }
        }
    }
}

+ (BOOL)regularReplacement:(NSString *)regular oldString:(NSMutableString *)oldString newString:(NSString *)newString{
    __block BOOL isChanged = NO;
    BOOL isGroupNo = [newString isEqualToString:@"\\1"];
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regular options:NSRegularExpressionAnchorsMatchLines|NSRegularExpressionUseUnixLineSeparators error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:oldString options:0 range:NSMakeRange(0, oldString.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!isChanged) {
            isChanged = YES;
        }
        if (isGroupNo) {
            NSString *withString = [oldString substringWithRange:[obj rangeAtIndex:1]];
            [oldString replaceCharactersInRange:obj.range withString:withString];
        } else {
            [oldString replaceCharactersInRange:obj.range withString:newString];
        }
    }];
    return isChanged;
}

+ (void)replacePodfileContent:(NSString *)filePath oldString:(NSString *)oldString newString:(NSString *)newString{
    NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *regularExpression = [NSString stringWithFormat:@"target +'%@", oldString];
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:0 error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:fileContent options:0 range:NSMakeRange(0, fileContent.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [fileContent replaceCharactersInRange:obj.range withString:[NSString stringWithFormat:@"target '%@", newString]];
    }];
    
    regularExpression = [NSString stringWithFormat:@"project +'%@.", oldString];
    expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:0 error:nil];
    matches = [expression matchesInString:fileContent options:0 range:NSMakeRange(0, fileContent.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [fileContent replaceCharactersInRange:obj.range withString:[NSString stringWithFormat:@"project '%@.", newString]];
    }];
    
    [fileContent writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

+ (void)resetBridgingHeaderFileName:(NSString *)projectPbxprojFilePath oldName:(NSString *)oldName newName:(NSString *)newName{
    NSString *rootPath = projectPbxprojFilePath.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent;
    NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:projectPbxprojFilePath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *regularExpression = @"SWIFT_OBJC_BRIDGING_HEADER = \"?([^\";]+)";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:0 error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:fileContent options:0 range:NSMakeRange(0, fileContent.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *entitlementsPath = [fileContent substringWithRange:[obj rangeAtIndex:1]];
        NSString *entitlementsName = entitlementsPath.lastPathComponent.stringByDeletingPathExtension;
        if (![entitlementsName isEqualToString:oldName]) return;
        entitlementsPath = [rootPath stringByAppendingPathComponent:entitlementsPath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:entitlementsPath]) return;
        NSString *newPath = [entitlementsPath.stringByDeletingLastPathComponent stringByAppendingPathComponent:[newName stringByAppendingPathExtension:@"h"]];
        [self renameFile:entitlementsPath newPath:newPath];
    }];
}

+ (void)renameFile:(NSString *)oldPath newPath:(NSString *)newPath{
    NSError *error;
    NSFileManager *fm = [NSFileManager defaultManager];
    mode_t mode = 0644;
    const char *cFilePath = [oldPath fileSystemRepresentation];
    if (chmod(cFilePath, mode) == 0) {
        NSLog(@"文件权限已成功更改。");
    } else {
        NSLog(@"文件权限更改失败。");
    }
    if ([fm fileExistsAtPath:newPath]) return;
    
    [fm moveItemAtPath:oldPath toPath:newPath error:&error];
    if (error) {
        NSLog(@"修改文件名称失败。\n  oldPath=%s\n  newPath=%s\n  ERROR:%s\n", oldPath.UTF8String, newPath.UTF8String, error.localizedDescription.UTF8String);
        if (error.code != 516) abort();
    }
}

+ (void)resetEntitlementsFileName:(NSString *)projectPbxprojFilePath oldName:(NSString *)oldName newName:(NSString *)newName{
    NSString *rootPath = projectPbxprojFilePath.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent;
    NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:projectPbxprojFilePath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *regularExpression = @"CODE_SIGN_ENTITLEMENTS = \"?([^\";]+)";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:0 error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:fileContent options:0 range:NSMakeRange(0, fileContent.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *entitlementsPath = [fileContent substringWithRange:[obj rangeAtIndex:1]];
        NSString *entitlementsName = entitlementsPath.lastPathComponent.stringByDeletingPathExtension;
        if (![entitlementsName isEqualToString:oldName]) return;
        entitlementsPath = [rootPath stringByAppendingPathComponent:entitlementsPath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:entitlementsPath]) return;
        NSString *newPath = [entitlementsPath.stringByDeletingLastPathComponent stringByAppendingPathComponent:[newName stringByAppendingPathExtension:@"entitlements"]];
        [self renameFile:entitlementsPath newPath:newPath];
    }];
}

+ (void)replaceProjectFileContent:(NSString *)filePath oldName:(NSString *)oldName newName:(NSString *)newName{
    NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *regularExpression = [NSString stringWithFormat:@"\\b%@\\b", oldName];
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:0 error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:fileContent options:0 range:NSMakeRange(0, fileContent.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *string = [fileContent substringWithRange:NSMakeRange(obj.range.location+obj.range.length, 2)];
        if ([string containsString:@".h"] || [string containsString:@".m"] || [string containsString:@".swift"]){
            return;
        }
        [fileContent replaceCharactersInRange:obj.range withString:newName];
    }];
    
    [fileContent writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

+ (void)clearCodeComment:(NSString *)projectPath ignoreDirNames:(NSArray<NSString *> * __nullable)ignoreDirNames{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:projectPath error:nil];
    BOOL isDirectory;
    for (NSString *fileName in files) {
        if ([ignoreDirNames containsObject:fileName]) continue;
        NSString *filePath = [projectPath stringByAppendingPathComponent:fileName];
        if ([fm fileExistsAtPath:filePath isDirectory:&isDirectory] && isDirectory) {
            [self clearCodeComment:filePath ignoreDirNames:ignoreDirNames];
            continue;
        }
        if (![fileName hasSuffix:@".h"] && ![fileName hasSuffix:@".m"] && ![fileName hasSuffix:@".mm"] && ![fileName hasSuffix:@".swift"]) continue;
        NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        NSDictionary *replaceDict = @{@"([^:/])//.*":@"\\1",@"^//.*":@" ",@"/\\*{1,2}[\\s\\S]*?\\*/":@" ",@"^\\s*\\n":@" "};
        for (NSString *key in replaceDict) {
            [self regularReplacement:key oldString:fileContent newString:replaceDict[key]];
        }
        
        [fileContent writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

static NSMutableSet *_searchResultSet;
+ (void)searchProjectName:(NSString *)projectPath keyWord:(NSString *)keyWord{
    _searchResultSet = [NSMutableSet set];
    [self searchProjectPath:projectPath keyWord:keyWord];
   
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *fileDir = [NSString stringWithFormat:@"/Users/wangxiangwei/Desktop/翻译/%@",projectPath.lastPathComponent];
    NSString *fileStrings = [NSString stringWithFormat:@"%@.strings",fileDir];
    [fm createDirectoryAtPath:fileDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSMutableString *mutableString = [NSMutableString string];
    NSArray *allObjects = _searchResultSet.allObjects;
    for (NSString *str in allObjects) {
        //[mutableString appendFormat:@"\"%@\" = \"%@\";\n",str,str];
        if ([str isEqualToString:allObjects.lastObject]){
            [mutableString appendFormat:@"%@",str];
        }else{
            [mutableString appendFormat:@"%@\n",str];
        }
    }
    
    NSError *error;
    [mutableString writeToFile:fileStrings atomically:YES encoding:NSUTF8StringEncoding error:&error];
    NSLog(@"%@",error);
}

+ (void)searchProjectPath:(NSString *)projectPath keyWord:(NSString *)keyWord{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:projectPath error:nil];
    BOOL isDirectory;
    
    for (NSString *filePath in files) {
        if ([filePath isEqualToString:@"Pods"]) continue;
        NSString *path = [projectPath stringByAppendingPathComponent:filePath];
        
        if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
            [self searchProjectPath:path keyWord:keyWord];
            continue;
        }
        
        NSString *fileName = filePath.lastPathComponent;
        if ([fileName hasSuffix:@".h"] || [fileName hasSuffix:@".m"] || [fileName hasSuffix:@".mm"] || [fileName hasSuffix:@".swift"] || [fileName hasSuffix:@".xib"] || [fileName hasSuffix:@".storyboard"] || [fileName hasSuffix:@".plist"]) {
            NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
            NSArray *logStrings = [fileContent regexPattern:keyWord];
           
            for (NSString *logString in logStrings) {
                fileContent = [fileContent stringByReplacingOccurrencesOfString:logString withString:@""].mutableCopy;
            }
            
            if ([fileContent containsString:keyWord]){
                NSLog(@"%@",path);
            }
            NSArray *stringNames = [fileContent regexPattern:@">(.*?)<"];
            for (NSString *string in stringNames) {
                if ([self containsChinese:string]){
                    [_searchResultSet addObject:[NSString stringWithFormat:@">%@<",string]];
                }
            }
        }
    }
}

+ (BOOL)containsChinese:(NSString *)string {
    for (int i = 0; i < string.length; i++) {
        unichar c = [string characterAtIndex:i];
        if ((c >= 0x4E00) && (c <= 0x9FFF)) {
            return YES; // 包含中文
        }
    }
    return NO; // 不包含中文
}



+ (NSDictionary *)jiexiplist:(NSString *)fileContent{
    NSArray *d1 = [fileContent componentsSeparatedByString:@"\";"];
    NSMutableDictionary *rd1 = [NSMutableDictionary dictionary];
    for (NSString *string in d1) {
        NSArray *r1 = [string componentsSeparatedByString:@"\" = \""];
        if (r1.count != 2) continue;;
        
        NSString *Key = r1.firstObject;
        NSString *value = r1.lastObject;
        
        NSString *a = [Key.whitespace stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        a = [a stringByReplacingOccurrencesOfString:@";" withString:@""];
        
        NSString *b = [value.whitespace stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        b = [b stringByReplacingOccurrencesOfString:@";" withString:@""];
        if ([rd1 valueForKey:a]){
            NSLog(@"重复===>>>%@---%@",value,Key);
        }else{
            [rd1 setValue:b forKey:a];
        }
    }
    NSLog(@"键值对===>>>%ld",rd1.allKeys.count);
    return rd1;
}


+ (BOOL)containsKoreanCharacters:(NSString *)string {
    if (!string) return NO;
      
    // 使用 NSRegularExpression 来检查 Unicode 范围内的韩文
    // 这里我们主要检查 Hangul Syllables 范围 AC00-D7AF
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[\uAC00-\uD7AF]+" options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        NSLog(@"Regex compilation error: %@", error);
        return NO;
    }
      
    // 检查是否匹配  
    NSTextCheckingResult *match = [regex firstMatchInString:string options:0 range:NSMakeRange(0, [string length])];
    return match != nil;
}

static NSMutableSet *_file2Name;
static NSMutableSet *_filePath2Set;
+ (void)modify2FilePrefix:(NSString *)projectPath newPrefix:(NSString *)newPrefix{
    _file2Name = [NSMutableSet set];
    _filePath2Set = [NSMutableSet set];
    [self modify2ClassDict:projectPath newPrefix:newPrefix];
    [self modify2ClassNamePrefix:projectPath];
    for (NSString *filePath in _filePath2Set.allObjects) {
        NSString *fileName = [filePath.lastPathComponent stringByReplacingOccurrencesOfString:@".h" withString:@""];
        NSString *fileString = filePath.stringByDeletingLastPathComponent;
        NSString *h = [fileString stringByAppendingPathComponent:[NSString stringWithFormat:@"LSQ%@.h",fileName]];
        NSString *mfilePath = [filePath stringByReplacingOccurrencesOfString:@".h" withString:@".m"];
        NSString *m = [fileString stringByAppendingPathComponent:[NSString stringWithFormat:@"LSQ%@.m",fileName]];
        [self renameFile:filePath newPath:h];
        [self renameFile:mfilePath newPath:m];
        
        NSString *xib = [filePath stringByReplacingOccurrencesOfString:@".h" withString:@".xib"];
        NSMutableString *xfileContent = [NSMutableString stringWithContentsOfFile:xib encoding:NSUTF8StringEncoding error:nil];
        
        if (xfileContent.length){
            NSString *nxib = [fileString stringByAppendingPathComponent:[NSString stringWithFormat:@"LSQ%@.xib",fileName]];
            [self renameFile:xib newPath:nxib];
        }
    }

}

+ (void)modify2ClassDict:(NSString *)projectPath newPrefix:(NSString *)newPrefix{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:projectPath error:nil];
    BOOL isDirectory;
    
    for (NSString *filePath in files) {
        if ([filePath isEqualToString:@"Pods"]) continue;
        if ([filePath isEqualToString:@"meiyan"]) continue;
        if ([filePath isEqualToString:@"DGBackgroudDownloadManagers"]) continue;
        NSString *path = [projectPath stringByAppendingPathComponent:filePath];
        
        if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
            [self modify2ClassDict:path newPrefix:newPrefix];
            continue;
        }
        
        NSString *fileName = filePath.lastPathComponent;
        if ([fileName hasSuffix:@".h"] && ![fileName containsString:@"+"]){
            NSString *mfile = [path stringByReplacingOccurrencesOfString:@".h" withString:@".m"];
            NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:mfile encoding:NSUTF8StringEncoding error:nil];
            if (fileContent.length){
                NSMutableString *hfileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
                NSArray *fileNames = [hfileContent regexPattern:@"@interface\\s+([^:\\r\\n]+):"];
                for (NSString *class in fileNames) {
                    [_file2Name addObject:class.whitespace];
                }
                [_filePath2Set addObject:path.whitespace];
            }
            
        }
    }
}

+ (void)modify2ClassNamePrefix:(NSString *)projectPath{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:projectPath error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        if ([filePath isEqualToString:@"Pods"]) continue;
        if ([filePath isEqualToString:@"meiyan"]) continue;
        if ([filePath isEqualToString:@"DGBackgroudDownloadManagers"]) continue;
        NSString *path = [projectPath stringByAppendingPathComponent:filePath];
        if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
            [self modify2ClassNamePrefix:path];
            continue;
        }
       
        NSString *fileName = filePath.lastPathComponent;
        if ([fileName hasSuffix:@".h"] || [fileName hasSuffix:@".m"] || [fileName hasSuffix:@".mm"] || [fileName hasSuffix:@".pch"] || [fileName hasSuffix:@".swift"] || [fileName hasSuffix:@".xib"] || [fileName hasSuffix:@".storyboard"]) {
            NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
            if (fileContent.length){
                for (NSString *class in _file2Name.allObjects) {
                    NSString *newClass = [NSString stringWithFormat:@"LSQ%@",class];
                    fileContent = replaceIndependentWord(fileContent, class, newClass);
                }
                [fileContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
            }
        }
        
        if ([fileName isEqualToString:@"project.pbxproj"]){
            NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
            for (NSString *class in _file2Name.allObjects) {
                NSString *h = [NSString stringWithFormat:@"%@.h",class];
                NSString *m = [NSString stringWithFormat:@"%@.m",class];
                NSString *x = [NSString stringWithFormat:@"%@.xib",class];
                NSString *newh = [NSString stringWithFormat:@"LSQ%@.h",class];
                NSString *newm = [NSString stringWithFormat:@"LSQ%@.m",class];
                NSString *xewm = [NSString stringWithFormat:@"LSQ%@.xib",class];
                fileContent = replaceIndependentWord(fileContent, h, newh);
                fileContent = replaceIndependentWord(fileContent, m, newm);
                fileContent = replaceIndependentWord(fileContent, x, xewm);
            }
            [fileContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }
}

NSMutableString *replaceIndependentWord(NSString *string, NSString *target, NSString *replacement) {
    NSMutableString *mutableString = [string mutableCopy];
    NSRange range = NSMakeRange(0, mutableString.length);
      
    while (range.location != NSNotFound) {
        range = [mutableString rangeOfString:target options:NSLiteralSearch range:range];
          
        if (range.location != NSNotFound) {
            // 检查前面是否是单词边界（例如空格、标点符号等）
            BOOL isStartOfWord = (range.location == 0 || ![[NSCharacterSet letterCharacterSet] characterIsMember:[mutableString characterAtIndex:range.location - 1]]);
              
            // 检查后面是否是单词边界
            BOOL isEndOfWord = (range.location + target.length == mutableString.length || ![[NSCharacterSet letterCharacterSet] characterIsMember:[mutableString characterAtIndex:range.location + target.length]]);
              
            if (isStartOfWord && isEndOfWord) {
                // 替换独立出现的 target
                [mutableString replaceCharactersInRange:range withString:replacement];
                // 更新搜索范围，避免替换到已经替换过的地方
                range = NSMakeRange(range.location + replacement.length, mutableString.length - (range.location + replacement.length));
            } else {
                // 移动搜索范围以跳过当前的 target
                range = NSMakeRange(range.location + target.length, mutableString.length - (range.location + target.length));
            }
        }
    }
      
    return mutableString;
}

+ (void)copyImagesInDirectory:(NSString *)directory toDirectory:(NSString *)todirectory{
    NSMutableArray *images = [self getImagesInDirectory:directory];
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    for (NSString *string in images) {
        [dic setValue:string forKey:string.lastPathComponent];
    }
    NSMutableArray *toImages = [self getImagesInDirectory:todirectory];
    for (NSString *string in toImages) {
        NSString *name = string.lastPathComponent;
        if ([dic.allKeys containsObject:name]){
            NSData *imageData = [NSData dataWithContentsOfFile:string];
            if (imageData){
                NSError *error = nil;
                BOOL success = [imageData writeToFile:dic[name] options:NSDataWritingAtomic error:&error];
                if (!success){
                    NSLog(@"拷贝图片时出错：%@\n图片路径：%@",error.localizedDescription,dic[name]);
                }
            }else{
                NSLog(@"图片读取失败");
            }
        }
    }
    return;
    
    //重名 不做处理
    NSLog(@"%ld",images.count);
    NSMutableArray *temp = [NSMutableArray array];
    NSMutableSet *set = [NSMutableSet set];
    for (NSString *string in images) {
        NSString *name = string.lastPathComponent;
        if ([temp containsObject:name]){
            [set addObject:name];
        }else{
            [temp addObject:name];
        }
    }
    
    //移除重名图片
    [images removeObjectsInArray:set.allObjects];
    
    NSString *wfilePath = todirectory;
    for (NSString *filePath in images) {
        NSData *imageData = [NSData dataWithContentsOfFile:filePath];
        if (imageData){
            NSError *error = nil;
            NSString *fileName = [wfilePath stringByAppendingPathComponent:filePath.lastPathComponent];
            BOOL success = [imageData writeToFile:fileName options:NSDataWritingAtomic error:&error];
            if (!success){
                NSLog(@"拷贝图片时出错：%@\n图片路径：%@",error.localizedDescription,filePath);
            }
        }else{
            NSLog(@"图片读取失败");
        }
    }
}

+ (NSMutableArray *)getImagesInDirectory:(NSString *)directory{
    NSMutableArray<NSString *> *imageFiles = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directory];
    
    NSString *fileName;
    while ((fileName = [enumerator nextObject]) != nil) {
        if ([fileName containsString:@"Pods"]) continue;
        NSString *filePath = [directory stringByAppendingPathComponent:fileName];
        if ([[filePath pathExtension] isEqualToString:@"png"] ||
            [[filePath pathExtension] isEqualToString:@"jpg"] ||
            [[filePath pathExtension] isEqualToString:@"jpeg"]) {
            [imageFiles addObject:filePath];
        }
    }
    return imageFiles;
}

+ (void)searchBigFileInDirectory:(NSString *)directory minSize:(NSString *)size{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *directoryEnumerator = [fm enumeratorAtPath:directory];
    for (NSString *fileName in directoryEnumerator) {
        NSString *filePath = [directory stringByAppendingPathComponent:fileName];
        NSDictionary<NSFileAttributeKey, id> *attributes = [fm attributesOfItemAtPath:filePath error:nil];
        NSNumber *fileSizeNumber = attributes[NSFileSize];
        
        long long int compareSize = [size longLongValue];
        if ([fileSizeNumber compare:@(compareSize)] == NSOrderedDescending) {
            NSLog(@"文件 '%@' ，大小为 %lld 字节", filePath, fileSizeNumber.longLongValue);
        }
    }
}

+ (void)fileToReadWrite{
    
}

@end



@implementation ChineseStringsCollector
  
- (instancetype)init {
    self = [super init];
    if (self) {
        _chineseStrings = [NSMutableSet set];
    }
    return self;
}
  
- (void)collectChineseStringsFromFile:(NSString *)filePath {
    NSError *error;
    NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (content == nil) {
        NSLog(@"Error reading file %@: %@", filePath, [error localizedDescription]);
        return;
    }
      
    [self.chineseStrings addObjectsFromArray:[self extractChineseStringsFromString:content]];
}

- (NSArray<NSString *> *)extractChineseStringsFromString:(NSString *)string {
    NSMutableArray *chineseStrings = [NSMutableArray array];
      
    // 定义中文字符的正则表达式范围（这里只包含了基本汉字范围，根据需要可以扩展）
    NSString *pattern = @"[\\u4e00-\\u9fff]+";
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
      
    if (error) {
        NSLog(@"Error creating regular expression: %@", [error localizedDescription]);
        return nil;
    }
      
    // 执行正则表达式匹配
    NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
      
    // 遍历匹配结果
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match rangeAtIndex:0];
        NSString *chineseString = [string substringWithRange:matchRange];
        [chineseStrings addObject:chineseString];
    }
      
    return chineseStrings;
}
 
+ (void)traverseDirectoryAndCollectChineseStrings:(NSString *)directory {
    ChineseStringsCollector *collector = [[ChineseStringsCollector alloc] init];
      
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *directoryEnumerator = [fm enumeratorAtPath:directory];
    for (NSString *fileName in directoryEnumerator) {
        NSString *filePath = [directory stringByAppendingPathComponent:fileName];
        [collector collectChineseStringsFromFile:filePath];
    }

      
    // 输出或处理收集到的中文字符串
    NSLog(@"Collected Chinese strings:");
    for (NSString *str in collector.chineseStrings) {
        NSLog(@"%@", str);
    }
    NSString *fileDir = [NSString stringWithFormat:@"/Users/wangxiangwei/Desktop/翻译/%@",directory.lastPathComponent];
    NSString *fileStrings = [NSString stringWithFormat:@"%@.strings",fileDir];
    [fm createDirectoryAtPath:fileDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSMutableString *mutableString = [NSMutableString string];
    NSArray *allObjects = collector.chineseStrings.allObjects;
    for (NSString *str in allObjects) {
        //[mutableString appendFormat:@"\"%@\" = \"%@\";\n",str,str];
        if ([str isEqualToString:allObjects.lastObject]){
            [mutableString appendFormat:@"%@",str];
        }else{
            [mutableString appendFormat:@"%@\n",str];
        }
    }
    
    NSError *error;
    [mutableString writeToFile:fileStrings atomically:YES encoding:NSUTF8StringEncoding error:&error];
    NSLog(@"%@",error);
}

+ (void)fanyizhongwen:(NSString *)directory fromFile:(NSString *)filePath{
    NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"%@",[BFModifyProject jiexiplist:fileContent]);
    NSDictionary *dic = [BFModifyProject jiexiplist:fileContent];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *directoryEnumerator = [fm enumeratorAtPath:directory];
    for (NSString *fileName in directoryEnumerator) {
        NSString *fullfilePath = [directory stringByAppendingPathComponent:fileName];
        NSString *content = [NSString stringWithContentsOfFile:fullfilePath encoding:NSUTF8StringEncoding error:nil];
        
        NSArray *sortedStrings = [dic.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString * _Nonnull obj2) {
            return obj1.length < obj2.length;
        }];
        for (NSString *key in sortedStrings) {
            content = [content stringByReplacingOccurrencesOfString:key withString:dic[key]];
            NSLog(@"===>>>");
        }
        [content writeToFile:fullfilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

@end
  

