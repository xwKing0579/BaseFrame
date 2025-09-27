//
//  BFGrabWordsTool.m
//  BaseFrame
//
//  Created by 王祥伟 on 2025/4/10.
//

#import "BFGrabWordsTool.h"

NSString *const kDocumentPath = @"/Users/wangxiangwei/Desktop/BaseFrame/BaseFrame/Tools/Confound/hunxiao";

@implementation BFGrabWordsTool

+ (NSArray *)scanWordsInProjectAtPath:(NSString *)projectPath{
    return [self scanWordsInProjectAtPath:projectPath writeToFile:NO];
}

+ (NSArray *)scanWordsInProjectAtPath:(NSString *)projectPath writeToFile:(BOOL)write{
    NSArray *methods = [self scanMethodsInProjectAtPath:projectPath];
    NSMutableSet *set = [NSMutableSet set];
    for (NSString *method in methods) {
        [set addObjectsFromArray:[method splitCamelCaseComponents]];
    }
    
    NSArray *words = set.allObjects;
    
    if (write){
        NSString *filePath = [NSString stringWithFormat:@"%@/%@.txt",kDocumentPath,projectPath.lastPathComponent];
        NSError *error;
        NSString *stringToSave = [words componentsJoinedByString:@","];
        BOOL success = [stringToSave writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        
        if (!success) {
            NSLog(@"写入文件失败: %@", error.localizedDescription);
        } else {
            NSLog(@"文件保存成功，路径: %@", filePath);
        }
    }
    return words;
}

+ (NSArray *)scanMethodsInProjectAtPath:(NSString *)projectPath{
    NSMutableSet<NSString *> *methodNames = [NSMutableSet set];
    
   
    return @[];
}

+ (void)parseMethodsFromContent:(NSString *)content intoSet:(NSMutableSet<NSString *> *)methodSet {
    NSError *error = nil;
    NSString *pattern = @"[-+]\\s*\\([^\\)]+\\)\\s*([^\\s:]+)((?:\\s*:\\s*\\([^\\)]+\\)\\s*[^\\s:]+)*)";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    if (error) {
        NSLog(@"Regex error: %@", error.localizedDescription);
        return;
    }
    
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:content options:0 range:NSMakeRange(0, content.length)];
    for (NSTextCheckingResult *match in matches) {
        NSRange methodNameRange = [match rangeAtIndex:1]; // 第一个捕获组是方法名
        NSString *methodName = [content substringWithRange:methodNameRange];
        [methodSet addObject:methodName];
        
        // 如果有参数，继续提取
        if (match.numberOfRanges > 2) {
            NSRange paramRange = [match rangeAtIndex:2];
            if (paramRange.location != NSNotFound) {
                NSString *param = [content substringWithRange:paramRange];
                [methodSet addObject:param];
            }
        }
    }
}


+ (NSSet<NSString *> *)filterSystemMethods:(NSSet<NSString *> *)methods {
    // 系统方法常见前缀列表
    NSArray *systemPrefixes = @[
        @"_", @"init", @"set", @"get", @"is",
        @"copy", @"mutableCopy", @"description",
        @"alloc", @"new", @"retain", @"release",
        @"autorelease", @"dealloc", @"respondsToSelector",
        @"performSelector", @"class", @"superclass",
        @"isKindOfClass", @"isMemberOfClass", @"conformsToProtocol",
        @"methodForSelector", @"instanceMethodForSelector",
        @"doesNotRecognizeSelector", @"forwardInvocation",
        @"methodSignatureForSelector", @"awakeFromNib",
        @"prepareForInterfaceBuilder", @"encodeWithCoder",
        @"initWithCoder", @"load", @"initialize"
    ];
    
    NSMutableSet *customMethods = [NSMutableSet set];
    
    for (NSString *method in methods) {
        BOOL isSystemMethod = NO;
        
        // 检查是否包含系统前缀
        for (NSString *prefix in systemPrefixes) {
            if ([method hasPrefix:prefix]) {
                isSystemMethod = YES;
                break;
            }
        }
        
        // 检查是否包含系统保留字
        if (!isSystemMethod) {
            NSArray *reservedWords = @[@"void", @"id", @"BOOL", @"NSInteger", @"NSUInteger"];
            for (NSString *word in reservedWords) {
                if ([method containsString:word]) {
                    isSystemMethod = YES;
                    break;
                }
            }
        }
        
        if (!isSystemMethod) {
            [customMethods addObject:method];
        }
    }
    return customMethods;
}

+ (NSArray *)processStrings:(NSArray *)originalArray {
    // 1. 筛选最多包含一个"_"的字符串
    NSArray *step1 = [originalArray filteredArrayUsingPredicate:
                      [NSPredicate predicateWithBlock:^BOOL(NSString *str, NSDictionary *bindings) {
        return [self containsAtMostOneUnderscore:str];
    }]];
    
    // 2. 移除包含非字母字符的字符串
    NSArray *step2 = [step1 filteredArrayUsingPredicate:
                      [NSPredicate predicateWithBlock:^BOOL(NSString *str, NSDictionary *bindings) {
        // 先移除下划线，然后检查是否只包含字母
        NSString *tempStr = [str stringByReplacingOccurrencesOfString:@"_" withString:@""];
        return [self containsOnlyLetters:tempStr];
    }]];
    
    // 3. 对于包含"_"的字符串，取"_"后的部分
    NSArray *result = [step2 map:^id(NSString *str) {
        return [self substringAfterUnderscore:str];
    }];
    
    return result;
}

+ (BOOL)containsAtMostOneUnderscore:(NSString *)str {
    NSArray <NSString *>*temp = [str componentsSeparatedByString:@"_"];
    NSInteger count = [temp count] - 1;
    return count <= 1 && temp.lastObject.length >= 3;
}

+ (BOOL)containsOnlyLetters:(NSString *)str {
    // 创建只包含字母的字符集
    NSCharacterSet *letterCharacterSet = [NSCharacterSet letterCharacterSet];
    
    // 创建非字母字符集（即字母字符集的补集）
    NSCharacterSet *nonLetterCharacterSet = [letterCharacterSet invertedSet];
    
    // 检查字符串中是否包含非字母字符
    NSRange range = [str rangeOfCharacterFromSet:nonLetterCharacterSet];
    return range.location == NSNotFound;
}

+ (NSArray *)filterAlphabetOnlyStrings:(NSArray *)stringArray {
    return [stringArray filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^BOOL(NSString *str, NSDictionary *bindings) {
        return [self containsOnlyLetters:str];
    }]];
}

+ (NSString *)substringAfterUnderscore:(NSString *)str {
    NSRange range = [str rangeOfString:@"_"];
    if (range.location != NSNotFound && range.location + 1 < str.length) {
        return [str substringFromIndex:range.location + 1];
    }
    return str; // 如果不包含"_"或"_"在末尾，返回原字符串
}

+ (NSArray *)getAllTxtWordsWithType:(WordsType)type{
    // 创建文件管理器实例
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    // 获取目录中的所有文件和文件夹
    NSString *directoryPath = kDocumentPath;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
    if (error) {
        NSLog(@"Error: %@", error.localizedDescription);
        return @[];
    }
    
    NSMutableSet *set = [NSMutableSet set];
    // 遍历目录内容
    for (NSString *fileName in contents) {
        NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
        BOOL isDirectory;
        
        // 判断是否为文件夹
        if ([fileManager fileExistsAtPath:filePath isDirectory:&isDirectory] && !isDirectory) {
            // 检查文件扩展名是否为.txt
            if ([[fileName pathExtension] isEqualToString:@"txt"]) {
                // 读取文件内容
                NSString *fileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
                if (error) {
                    NSLog(@"Error reading file '%@': %@", fileName, error.localizedDescription);
                } else {
                    [set addObjectsFromArray:[fileContent componentsSeparatedByString:@","]];
                }
            }
        }
    }
    
    [set addObjectsFromArray:[BFWordsRackTool getWordsWithType:type]];
    return set.allObjects;
}

+ (NSDictionary *)replaceMethodNameWithOriginMethodList:(NSArray *)methodList words:(NSArray *)words{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSMutableArray *temp = [NSMutableArray arrayWithArray:words];
    
    for (NSString *method in methodList) {
        NSInteger index = arc4random()%temp.count;
        NSString *value = temp[index];
        [temp removeObject:value];
        [dict setValue:value forKey:method];
    }
    return dict;
}

@end


@implementation NSArray (Functional)
- (NSArray *)map:(id (^)(id obj))block {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    for (id obj in self) {
        [result addObject:block(obj) ?: [NSNull null]];
    }
    return result;
}
@end

@implementation NSString (CamelCaseSplit)

// 拆分驼峰命名字符串
- (NSArray<NSString *> *)splitCamelCaseComponents {
    if (self.length == 0) {
        return @[];
    }
    
    NSMutableArray *components = [NSMutableArray array];
    NSUInteger start = 0;
    NSArray *reservedWords = @[@"alloc", @"new", @"copy", @"mutableCopy", @"class"];
    for (NSUInteger i = 1; i < self.length; i++) {
        unichar current = [self characterAtIndex:i];
        unichar previous = [self characterAtIndex:i-1];
        
        BOOL isCurrentUpper = isupper(current);
        BOOL isPreviousUpper = isupper(previous);
        BOOL isNextLower = (i+1 < self.length) && islower([self characterAtIndex:i+1]);
        
        if ((isCurrentUpper && !isPreviousUpper) ||
            (isCurrentUpper && isNextLower)) {
            NSString *component = [self substringWithRange:NSMakeRange(start, i-start)];
            if (component.length > 2) {
                if (![reservedWords containsObject:component.lowercaseString]){
                    [components addObject:component.lowercaseString];
                }
            }
            start = i;
        }
    }
    
    // 添加最后一个组件
    NSString *lastComponent = [self substringWithRange:NSMakeRange(start, self.length-start)];
    if (lastComponent.length > 2){
        if (![reservedWords containsObject:lastComponent.lowercaseString]){
            [components addObject:lastComponent.lowercaseString];
        }
    }
    return components;
}

@end
