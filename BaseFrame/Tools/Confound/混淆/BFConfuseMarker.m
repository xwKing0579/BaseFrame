//
//  BFConfuseMarker.m
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/2.
//

#import "BFConfuseMarker.h"

@implementation BFConfuseMarker
+ (void)deleteCommentsInDirectory:(NSString *)directory ignoreDirNames:(NSArray<NSString *> *)ignoreDirNames {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:directory error:&error];
    
    if (error) {
        NSLog(@"Error reading directory: %@", error.localizedDescription);
        return;
    }
    
    BOOL isDirectory;
    for (NSString *fileName in files) {
        // Skip ignored directories
        if ([ignoreDirNames containsObject:fileName]) {
            continue;
        }
        
        NSString *filePath = [directory stringByAppendingPathComponent:fileName];
        
        // Check if it's a directory
        if ([fm fileExistsAtPath:filePath isDirectory:&isDirectory] && isDirectory) {
            [self deleteCommentsInDirectory:filePath ignoreDirNames:ignoreDirNames];
            continue;
        }
        
        // Only process source code files
        if (![fileName.pathExtension.lowercaseString isEqualToString:@"h"] &&
            ![fileName.pathExtension.lowercaseString isEqualToString:@"m"] &&
            ![fileName.pathExtension.lowercaseString isEqualToString:@"mm"] &&
            ![fileName.pathExtension.lowercaseString isEqualToString:@"swift"]) {
            continue;
        }
        
        // Read file content
        NSError *readError = nil;
        NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:filePath
                                                                      encoding:NSUTF8StringEncoding
                                                                         error:&readError];
        if (readError || !fileContent) {
            NSLog(@"Error reading file %@: %@", fileName, readError.localizedDescription);
            continue;
        }
        
        // Remove comments
        [self removeCommentsFromString:fileContent];
        
        // Write back to file
        NSError *writeError = nil;
        [fileContent writeToFile:filePath
                      atomically:YES
                        encoding:NSUTF8StringEncoding
                           error:&writeError];
        if (writeError) {
            NSLog(@"Error writing file %@: %@", fileName, writeError.localizedDescription);
        }
    }
}

+ (void)removeCommentsFromString:(NSMutableString *)originalString {
    NSRegularExpression *stringRegex = [NSRegularExpression regularExpressionWithPattern:@"@\"(?:\\\\\"|[^\"])*?\"" options:0 error:nil];
    NSArray<NSTextCheckingResult *> *stringMatches = [stringRegex matchesInString:originalString options:0 range:NSMakeRange(0, originalString.length)];
    
    // 反向替换以避免影响后续匹配的范围
    NSMutableDictionary *stringLiterals = [NSMutableDictionary dictionary];
    for (NSTextCheckingResult *result in [stringMatches reverseObjectEnumerator]) {
        NSString *placeholder = [NSString stringWithFormat:@"__STRING_LITERAL_%lu__", (unsigned long)stringLiterals.count];
        stringLiterals[placeholder] = [originalString substringWithRange:result.range];
        [originalString replaceCharactersInRange:result.range withString:placeholder];
    }
    
    // 现在安全地删除注释
    // 1. 删除单行注释 (//) 但不包括 :// (如 http://)
    [self regularReplacement:originalString
                    pattern:@"(?<!:)\\/\\/[^\n]*"
                 replacement:@""];
    
    // 2. 删除多行注释 (/* */)
    [self regularReplacement:originalString
                    pattern:@"\\/\\*[^*]*\\*+(?:[^/*][^*]*\\*+)*\\/"
                 replacement:@""];
    
    // 3. 删除文档注释 (/** */)
    [self regularReplacement:originalString
                    pattern:@"\\/\\*\\*[^*]*\\*+(?:[^/*][^*]*\\*+)*\\/"
                 replacement:@""];
    
    NSArray<NSString *> *sortedPlaceholders = [[stringLiterals allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *key1, NSString *key2) {
        return [key2 compare:key1]; // 降序排序
    }];
    
    for (NSString *placeholder in sortedPlaceholders) {
        [originalString replaceOccurrencesOfString:placeholder
                                       withString:stringLiterals[placeholder]
                                          options:NSLiteralSearch
                                            range:NSMakeRange(0, originalString.length)];
    }
}



+ (BOOL)regularReplacement:(NSMutableString *)originalString
                  pattern:(NSString *)pattern
               replacement:(NSString *)replacement {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                          options:NSRegularExpressionAnchorsMatchLines
                                                                            error:nil];
    if (!regex) return NO;
    
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:originalString
                                                             options:0
                                                               range:NSMakeRange(0, originalString.length)];
    
    // Process matches in reverse to avoid range issues
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        [originalString replaceCharactersInRange:match.range withString:replacement];
    }
    
    return matches.count > 0;
}




+ (void)cleanSemicolonCommentsInProject:(NSString *)rootPath {
    NSArray *files = [self findAllSourceFilesInPath:rootPath excludePods:YES];
    
    for (NSString *filePath in files) {
        [self processFileLineByLine:filePath];
    }
    
    NSLog(@"✅ 清理完成！共处理 %lu 个文件", (unsigned long)files.count);
}

#pragma mark - 核心行处理逻辑

+ (void)processFileLineByLine:(NSString *)filePath {
    NSError *error;
    NSString *fileContent = [NSString stringWithContentsOfFile:filePath
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
    if (error) {
        NSLog(@"⚠️ 读取失败: %@", filePath.lastPathComponent);
        return;
    }
    
    NSMutableArray *lines = [NSMutableArray arrayWithArray:[fileContent componentsSeparatedByString:@"\n"]];
    BOOL hasChanges = NO;
    
    for (NSInteger i = 0; i < lines.count; i++) {
        NSString *originalLine = lines[i];
        NSString *processedLine = [self processLine:originalLine];
        
        if (![processedLine isEqualToString:originalLine]) {
            lines[i] = processedLine;
            hasChanges = YES;
        }
    }
    
    if (hasChanges) {
        NSString *newContent = [lines componentsJoinedByString:@"\n"];
        [newContent writeToFile:filePath
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:&error];
    }
}

+ (NSString *)processLine:(NSString *)line {
    // 查找分号位置
    NSRange semicolonRange = [line rangeOfString:@";"];
    if (semicolonRange.location == NSNotFound) {
        return line;
    }
    
    // 检查分号后是否跟着//
    NSString *remainingString = [line substringFromIndex:semicolonRange.location + 1];
    remainingString = [remainingString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([remainingString hasPrefix:@"//"]) {
        // 返回分号之前的内容（保留原始空格）
        return [line substringToIndex:semicolonRange.location + 1];
    }
    
    return line;
}

#pragma mark - 文件遍历（保持不变）

+ (NSArray<NSString *> *)findAllSourceFilesInPath:(NSString *)path excludePods:(BOOL)excludePods {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSMutableArray *files = [NSMutableArray array];
    NSString *resolvedPath = [path stringByStandardizingPath];
    
    NSDirectoryEnumerator *enumerator = [fm enumeratorAtURL:[NSURL fileURLWithPath:resolvedPath]
                                 includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                    options:NSDirectoryEnumerationSkipsHiddenFiles
                                               errorHandler:nil];
    
    for (NSURL *fileURL in enumerator) {
        NSNumber *isDir;
        [fileURL getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:nil];
        
        if ([isDir boolValue]) {
            if (excludePods && [fileURL.lastPathComponent isEqualToString:@"Pods"]) {
                [enumerator skipDescendants];
            }
            continue;
        }
        
        if ([self isSourceFile:fileURL.path]) {
            [files addObject:fileURL.path];
        }
    }
    
    return [files copy];
}

+ (BOOL)isSourceFile:(NSString *)path {
    NSString *ext = [[path pathExtension] lowercaseString];
    return [@[@"h"] containsObject:ext];
}











+ (void)processFile:(NSString *)filePath {
    if ([self shouldSkipFile:filePath]) {
        return;
    }
    
    NSError *error;
    NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"❌ 读取文件失败: %@", filePath);
        return;
    }
    
    // 匹配方法实现和方法声明
    NSRegularExpression *methodRegex = [NSRegularExpression
                                        regularExpressionWithPattern:@"-\\s*\\([^\\)]+\\)\\s*[^\\s;{]+.*?(?=\\s*[;{])"
                                        options:NSRegularExpressionDotMatchesLineSeparators
                                        error:&error];
    
    if (error) {
        NSLog(@"❌ 正则表达式错误: %@", error);
        return;
    }
    
    // 逆序处理匹配结果
    NSArray<NSTextCheckingResult *> *matches = [methodRegex
                                                matchesInString:fileContent
                                                options:0
                                                range:NSMakeRange(0, fileContent.length)];
    
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        NSString *methodDeclaration = [fileContent substringWithRange:match.range];
        
        // 提取方法信息
        NSDictionary *methodInfo = [self extractMethodInfo:methodDeclaration];
        if (methodInfo.count == 0) {
            continue; // 跳过系统方法
        }
        
        // 检查是否在白名单中
        if ([self isMethodInWhitelist:methodInfo[@"methodName"]]) {
            continue;
        }
        
        // 检查是否已有注释
        if (![self methodHasComment:methodDeclaration inContent:fileContent]) {
            NSString *comment = [self generateSmartCommentForMethod:methodDeclaration];
            
            // 找到方法前的合适插入位置
            NSUInteger insertLocation = [self findCommentInsertLocation:match.range.location inContent:fileContent];
            
            // 插入注释
            [fileContent insertString:[NSString stringWithFormat:@"%@\n", comment] atIndex:insertLocation];
        }
    }
    
    // 写回文件
    [fileContent writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"❌ 写入文件失败: %@", filePath);
    } else {
        NSLog(@"✅ 处理完成: %@", filePath);
    }
}

#pragma mark - Helper Methods

// 检查方法是否在白名单中
+ (BOOL)isMethodInWhitelist:(NSString *)methodName {
    static NSArray *whitelist;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        whitelist = @[
            @"dealloc",
            @"init",
            @"initWithFrame",
            @"initialize",
            @"load",
            @"awakeFromNib",
            
            // UIViewController 生命周期
            @"viewDidLoad",
            @"viewWillAppear:",
            @"viewDidAppear:",
            @"viewWillDisappear:",
            @"viewDidDisappear:",
            @"didReceiveMemoryWarning",
            
            // UITableView 数据源/代理
            @"tableView:numberOfRowsInSection:",
            @"tableView:cellForRowAtIndexPath:",
            @"numberOfSectionsInTableView:",
            
            // 其他常见方法
            @"setSelected:animated:",
            @"layoutSubviews",
            @"drawRect:"
        ];
    });
    
    return [whitelist containsObject:methodName];
}

// 找到合适的注释插入位置
+ (NSUInteger)findCommentInsertLocation:(NSUInteger)methodLocation inContent:(NSString *)content {
    NSUInteger location = methodLocation;
    
    // 向前查找第一个非空行
    while (location > 0) {
        unichar c = [content characterAtIndex:location - 1];
        
        if (c == '\n') {
            // 检查上一行是否为空行
            NSRange lineRange = [content lineRangeForRange:NSMakeRange(location - 1, 0)];
            NSString *line = [content substringWithRange:lineRange];
            
            if ([line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
                return location;
            }
        }
        
        location--;
    }
    
    return methodLocation;
}

+ (NSString *)generateSmartCommentForMethod:(NSString *)methodDeclaration {
    NSDictionary *methodInfo = [self extractMethodInfo:methodDeclaration];
    
    NSString *methodName = methodInfo[@"methodName"];
    NSArray *params = methodInfo[@"params"];
    
    NSMutableString *comment = [NSMutableString stringWithString:@"/**\n * "];
    [comment appendString:[BFSmartCommentGenerator generateMethodDescription:methodName]];
    
    if (params.count > 0) {
        [comment appendString:@"\n *\n"];
        
        // 添加参数说明
        for (NSDictionary *param in params) {
            NSString *paramName = param[@"name"];
            NSString *paramType = param[@"type"];
            
            [comment appendFormat:@" * @param %@ %@\n",
             paramName,
             [BFSmartCommentGenerator generateParamDescriptionForParam:paramType]];
        }
        
        // 检查是否有block参数
        BOOL hasBlock = NO;
        for (NSDictionary *param in params) {
            if ([param[@"type"] containsString:@"Block"] ||
                [param[@"type"] containsString:@"^"]) {
                hasBlock = YES;
                break;
            }
        }
        
        if (hasBlock) {
            [comment appendString:[BFSmartCommentGenerator generateCallbackNote]];
        }
    }
    
    // 添加返回值说明
    if (methodInfo[@"returnType"] && ![methodInfo[@"returnType"] isEqualToString:@"void"]) {
        [comment appendFormat:@" * @return %@\n", [BFSmartCommentGenerator generateReturnDescription]];
    }
    
    [comment appendString:@" */"];
    return comment;
}

+ (NSDictionary *)extractMethodInfo:(NSString *)methodDeclaration {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    // 1. 提取返回类型和方法名部分
    NSRegularExpression *methodRegex = [NSRegularExpression
        regularExpressionWithPattern:@"-\\s*\\(([^\\)]+)\\)\\s*([^\\s;{]+)"
        options:0
        error:nil];
    
    NSTextCheckingResult *methodMatch = [methodRegex
        firstMatchInString:methodDeclaration
        options:0
        range:NSMakeRange(0, methodDeclaration.length)];
    
    // 安全验证匹配结果
    if (!methodMatch || methodMatch.numberOfRanges < 3) {
        return @{};
    }
    
    NSString *returnType = [methodDeclaration substringWithRange:[methodMatch rangeAtIndex:1]];
    NSString *methodNamePart = [methodDeclaration substringWithRange:[methodMatch rangeAtIndex:2]];
    
    // 2. 过滤系统方法和特殊方法
    if ([self shouldSkipMethod:methodNamePart returnType:returnType]) {
        return @{};
    }
    
    [info setObject:returnType forKey:@"returnType"];
    [info setObject:methodNamePart forKey:@"methodName"];
    
    // 3. 精确提取参数信息
    NSMutableArray *params = [NSMutableArray array];
    if ([methodNamePart containsString:@":"]) {
        // 改进的参数提取正则
        NSRegularExpression *paramRegex = [NSRegularExpression
            regularExpressionWithPattern:@"(\\w+):\\s*\\(([^\\)]+)\\)\\s*(\\w+)"
            options:0
            error:nil];
        
        NSArray *paramMatches = [paramRegex
            matchesInString:methodDeclaration
            options:0
            range:NSMakeRange(0, methodDeclaration.length)];
        
        for (NSTextCheckingResult *paramMatch in paramMatches) {
            if (paramMatch.numberOfRanges >= 4) {
                NSString *paramPrefix = [methodDeclaration substringWithRange:[paramMatch rangeAtIndex:1]]; // 方法名前缀
                NSString *paramType = [methodDeclaration substringWithRange:[paramMatch rangeAtIndex:2]];   // 参数类型
                NSString *paramName = [methodDeclaration substringWithRange:[paramMatch rangeAtIndex:3]];  // 参数名
                
                if (![self shouldSkipParamWithType:paramType]) {
                    [params addObject:@{
                        @"name": paramName,
                        @"type": paramType,
                        @"prefix": paramPrefix // 保留方法名前缀用于完整性
                    }];
                }
            }
        }
    }
    
    if (params.count > 0) {
        [info setObject:params forKey:@"params"];
    }
    
    return info;
}

+ (BOOL)shouldSkipMethod:(NSString *)methodName returnType:(NSString *)returnType {
    // 系统框架返回类型
    NSArray *systemTypePrefixes = @[@"NS", @"UI", @"CG", @"CF", @"CA", @"AB", @"MK", @"CL", @"AV"];
    for (NSString *prefix in systemTypePrefixes) {
        if ([returnType hasPrefix:prefix]) {
            return YES;
        }
    }
    
    // 特殊方法名
    NSArray *excludedMethods = @[
        @"dealloc", @"init", @"initialize", @"load", @"awakeFromNib",
        @"viewDidLoad", @"viewWillAppear:", @"viewDidAppear:",
        @"viewWillDisappear:", @"viewDidDisappear:", @"didReceiveMemoryWarning",
        @"setSelected:animated:", @"layoutSubviews", @"drawRect:"
    ];
    
    if ([excludedMethods containsObject:methodName]) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)shouldSkipParamWithType:(NSString *)paramType {
    // 系统类型参数
    NSArray *systemTypePrefixes = @[@"NS", @"UI", @"CG", @"CF", @"CA"];
    for (NSString *prefix in systemTypePrefixes) {
        if ([paramType hasPrefix:prefix]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)shouldSkipFile:(NSString *)filePath {
    NSArray *excludedPaths = @[@"/Pods/", @"/ThirdParty/", @"/Generated/", @"/Vendor/"];
    for (NSString *excluded in excludedPaths) {
        if ([filePath containsString:excluded]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)methodHasComment:(NSString *)methodDeclaration inContent:(NSString *)content {
    NSRange methodRange = [content rangeOfString:methodDeclaration];
    if (methodRange.location == NSNotFound) return YES;
    
    // 检查方法前的注释标记
    NSUInteger checkLocation = methodRange.location - 1;
    while (checkLocation > 0) {
        unichar c = [content characterAtIndex:checkLocation];
        
        if (c == '\n') {
            NSRange lineRange = [content lineRangeForRange:NSMakeRange(checkLocation, 0)];
            NSString *line = [content substringWithRange:lineRange];
            
            if ([line containsString:@"//"] || [line containsString:@"/*"] ||
                [line containsString:@"*/"] || [line containsString:@"*"]) {
                return YES;
            }
            
            if ([line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
                checkLocation--;
                continue;
            }
            
            return NO;
        }
        
        checkLocation--;
    }
    
    return NO;
}

+ (NSString *)extractMethodName:(NSString *)methodDeclaration {
    // 提取方法名部分
    NSArray *parts = [methodDeclaration componentsSeparatedByString:@")"];
    if (parts.count < 2) return @"unknown";
    
    NSString *namePart = [parts[1] componentsSeparatedByString:@"{"][0];
    namePart = [namePart stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return namePart;
}

+ (NSArray *)extractParamTypes:(NSString *)methodDeclaration {
    // 简化实现，实际项目需要更复杂的解析
    NSMutableArray *paramTypes = [NSMutableArray array];
    
    // 检查是否有参数
    if ([methodDeclaration containsString:@":"]) {
        // 简单假设所有参数都是id类型
        NSUInteger paramCount = [[methodDeclaration componentsSeparatedByString:@":"] count] - 1;
        for (NSUInteger i = 0; i < paramCount; i++) {
            [paramTypes addObject:@"id"];
        }
    }
    
    return paramTypes;
}

+ (void)addCommentsToProjectAtPath:(NSString *)projectPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtPath:projectPath];
    
    for (NSString *relativePath in enumerator) {
        NSString *fullPath = [projectPath stringByAppendingPathComponent:relativePath];
        
        // 只处理.h和.m文件，跳过Pods目录
        if (([fullPath hasSuffix:@".h"] || [fullPath hasSuffix:@".m"]) &&
            ![fullPath containsString:@"/Pods/"]) {
            [self processFile:fullPath];
        }
    }
    
    NSLog(@"🎉 项目注释添加完成!");
}


@end


@implementation BFSmartCommentGenerator


+ (NSArray *)actionVerbs {
    return @[
        @"处理", @"执行", @"开始", @"完成", @"初始化",@"终止", @"继续", @"暂停", @"恢复", @"取消",
        @"验证", @"检查", @"准备", @"清理", @"重置",@"更新", @"刷新", @"加载", @"保存", @"提交",
        @"获取", @"设置", @"转换", @"比较", @"过滤",@"合并", @"拆分", @"解析", @"加密", @"解密",
        @"计算", @"评估", @"统计", @"分析", @"格式化",@"编码", @"解码", @"压缩", @"解压", @"序列化",
        @"请求", @"响应", @"下载", @"上传", @"连接",@"断开", @"重试", @"缓存", @"代理", @"重定向",
        @"显示", @"隐藏", @"创建", @"销毁", @"布局",@"绘制", @"渲染", @"动画", @"过渡", @"缩放",
        @"监听", @"通知", @"广播", @"注册", @"注销",@"调度", @"排队", @"同步", @"异步", @"线程化",
        @"发展", @"人民", @"国家", @"社会", @"经济",
         @"文化", @"科技", @"教育", @"历史", @"传统",
         @"创新", @"改革", @"开放", @"政策", @"法律",
         @"制度", @"环境", @"资源", @"能源", @"农业",
         @"工业", @"商业", @"金融", @"市场", @"企业",
         @"生产", @"消费", @"投资", @"贸易", @"增长",
         @"稳定", @"安全", @"和平", @"战争", @"国际",
         @"世界", @"全球", @"地区", @"城市", @"乡村",
         @"建设", @"规划", @"管理", @"服务", @"公共",
         @"医疗", @"健康", @"疾病", @"治疗", @"预防",
         @"科学", @"研究", @"实验", @"发现", @"理论",
         @"数据", @"信息", @"知识", @"智慧", @"智能",
         @"网络", @"数字", @"媒体", @"传播", @"新闻",
         @"艺术", @"音乐", @"绘画", @"文学", @"诗歌",
         @"电影", @"戏剧", @"舞蹈", @"设计", @"创作",
         @"体育", @"运动", @"比赛", @"训练", @"健康",
         @"食物", @"饮食", @"营养", @"农业", @"农民",
         @"自然", @"生态", @"动物", @"植物", @"森林",
         @"气候", @"天气", @"温度", @"雨", @"雪",
         @"地理", @"山脉", @"河流", @"海洋", @"土地",
         @"政治", @"政府", @"领导", @"选举", @"权力",
         @"军事", @"武器", @"防御", @"攻击", @"士兵",
         @"宗教", @"信仰", @"神", @"教堂", @"祈祷",
         @"哲学", @"思想", @"真理", @"现实", @"存在",
         @"心理", @"情感", @"感觉", @"记忆", @"学习",
         @"语言", @"文字", @"沟通", @"表达", @"理解",
         @"数学", @"数字", @"计算", @"公式", @"几何",
         @"物理", @"化学", @"生物", @"医学", @"工程",
         @"时间", @"空间", @"宇宙", @"星球", @"光",
         @"速度", @"力量", @"能量", @"物质", @"原子",
         @"家庭", @"父母", @"孩子", @"婚姻", @"爱情",
         @"友谊", @"社区", @"邻居", @"合作", @"竞争",
         @"工作", @"职业", @"公司", @"老板", @"员工",
         @"成功", @"失败", @"目标", @"计划", @"未来",
         @"过去", @"现在", @"年龄", @"生命", @"死亡",
         @"快乐", @"悲伤", @"愤怒", @"恐惧", @"惊讶",
         @"美丽", @"丑陋", @"善良", @"邪恶", @"道德",
         @"责任", @"权利", @"义务", @"自由", @"限制",
         @"学校", @"大学", @"老师", @"学生", @"考试",
         @"书籍", @"阅读", @"写作", @"出版", @"图书馆",
         @"电脑", @"手机", @"互联网", @"软件", @"硬件",
         @"游戏", @"娱乐", @"旅游", @"假期", @"节日",
         @"钱", @"财富", @"贫穷", @"银行", @"税收",
         @"交通", @"汽车", @"飞机", @"火车", @"船",
         @"建筑", @"房屋", @"道路", @"桥梁", @"公园",
         @"衣服", @"时尚", @"设计", @"颜色", @"风格",
         @"问题", @"答案", @"解决", @"困难", @"挑战",
         @"变化", @"进步", @"发展", @"革命", @"进化",
         @"原因", @"结果", @"影响", @"关系", @"系统",
         @"质量", @"数量", @"程度", @"水平", @"标准",
         @"机会", @"风险", @"决定", @"选择", @"命运",
        @"process", @"execute", @"start", @"complete", @"initialize",
        @"terminate", @"continue", @"pause", @"resume", @"cancel",
        @"validate", @"check", @"prepare", @"clean", @"reset",
        @"update", @"refresh", @"load", @"save", @"submit",
        @"fetch", @"set", @"convert", @"compare", @"filter",
        @"merge", @"split", @"parse", @"encrypt", @"decrypt",
        @"calculate", @"evaluate", @"count", @"analyze", @"format",
        @"encode", @"decode", @"compress", @"decompress", @"serialize",
        @"request", @"respond", @"download", @"upload", @"connect",
        @"disconnect", @"retry", @"cache", @"proxy", @"redirect",
        @"show", @"hide", @"create", @"destroy", @"layout",
        @"draw", @"render", @"animate", @"transition", @"scale",
        @"listen", @"notify", @"broadcast", @"register", @"unregister",
        @"dispatch", @"queue", @"synchronize", @"asynchronize", @"thread",
        @"efficient", @"fast", @"optimized", @"high-performance", @"low-latency",
        @"lightweight", @"memory-saving", @"CPU-saving", @"energy-saving", @"responsive",
        @"secure", @"encrypted", @"verified", @"signed", @"authenticated",
        @"private", @"sandboxed", @"isolated", @"protected", @"audited",
        @"reliable", @"stable", @"robust", @"fault-tolerant", @"resilient",
        @"accurate", @"consistent", @"complete", @"available", @"persistent",
        @"smart", @"adaptive", @"dynamic", @"configurable", @"extensible",
        @"modular", @"pluggable", @"reusable", @"customizable", @"composable",
        @"temporary", @"cached", @"preloaded", @"delayed", @"asynchronous",
        @"batched", @"parallel", @"serial", @"queued", @"prioritized",
        @"development", @"people", @"country", @"society", @"economy",
        @"culture", @"technology", @"education", @"history", @"tradition",
        @"innovation", @"reform", @"openness", @"policy", @"law",
        @"system", @"environment", @"resource", @"energy", @"agriculture",
        @"industry", @"business", @"finance", @"market", @"company",
        @"production", @"consumption", @"investment", @"trade", @"growth",
        @"stability", @"security", @"peace", @"war", @"international",
        @"world", @"global", @"region", @"city", @"village",
        @"construction", @"planning", @"management", @"service", @"public",
        @"medical", @"health", @"disease", @"treatment", @"prevention",
        @"science", @"research", @"experiment", @"discovery", @"theory",
        @"data", @"information", @"knowledge", @"wisdom", @"intelligence",
        @"network", @"digital", @"media", @"communication", @"news",
        @"art", @"music", @"painting", @"literature", @"poetry",
        @"movie", @"drama", @"dance", @"design", @"creation",
        @"sports", @"exercise", @"competition", @"training", @"health",
        @"food", @"diet", @"nutrition", @"farming", @"farmer",
        @"nature", @"ecology", @"animal", @"plant", @"forest",
        @"climate", @"weather", @"temperature", @"rain", @"snow",
        @"geography", @"mountain", @"river", @"ocean", @"land",
        @"politics", @"government", @"leadership", @"election", @"power",
        @"military", @"weapon", @"defense", @"attack", @"soldier",
        @"religion", @"belief", @"god", @"church", @"prayer",
        @"philosophy", @"thought", @"truth", @"reality", @"existence",
        @"psychology", @"emotion", @"feeling", @"memory", @"learning",
        @"language", @"writing", @"communication", @"expression", @"understanding",
        @"mathematics", @"number", @"calculation", @"formula", @"geometry",
        @"physics", @"chemistry", @"biology", @"medicine", @"engineering",
        @"time", @"space", @"universe", @"planet", @"light",
        @"speed", @"force", @"energy", @"matter", @"atom",
        @"family", @"parent", @"child", @"marriage", @"love",
        @"friendship", @"community", @"neighbor", @"cooperation", @"competition",
        @"work", @"career", @"corporation", @"boss", @"employee",
        @"success", @"failure", @"goal", @"plan", @"future",
        @"past", @"present", @"age", @"life", @"death",
        @"happiness", @"sadness", @"anger", @"fear", @"surprise",
        @"beauty", @"ugliness", @"kindness", @"evil", @"morality",
        @"responsibility", @"right", @"duty", @"freedom", @"limitation",
        @"school", @"university", @"teacher", @"student", @"exam",
        @"book", @"reading", @"writing", @"publishing", @"library",
        @"computer", @"phone", @"internet", @"software", @"hardware",
        @"game", @"entertainment", @"travel", @"vacation", @"festival",
        @"money", @"wealth", @"poverty", @"bank", @"tax",
        @"transportation", @"car", @"airplane", @"train", @"ship",
        @"architecture", @"house", @"road", @"bridge", @"park",
        @"clothing", @"fashion", @"design", @"color", @"style",
        @"problem", @"answerTo", @"solution", @"difficulty", @"challenge",
        @"change", @"progress", @"development", @"revolution", @"evolution",
        @"cause", @"effect", @"influence", @"relationship", @"system",
        @"quality", @"quantity", @"degree", @"level", @"standard",
        @"opportunity", @"risk", @"decision", @"choice", @"destiny",
        @"QuantumFlow",@"NexusSphere",@"VortexCore",@"SynapseLink",@"ChromaWave",
        @"TerraFrame",@"AeroGlide",@"NanoForge",@"FluxNode",@"MetaMesh",
        @"EchoPulse",@"VertexDrive",@"SolsticeBeam",@"OrionShell",@"CipherLock",
        @"PrismScale",@"NexusTide",@"AetherByte",@"VortexLens",@"QuantumLeap",
        @"ChromaShift",@"TerraByte",@"AeroBurst",@"NanoCell",@"FluxGate",
        @"MetaGrid",@"EchoTrace",@"VertexPort",@"SolsticeGlow",@"OrionField",
        @"CipherKey",@"PrismSpark",@"NexusBeam",@"AetherFlow",@"VortexRing",
        @"QuantumSync",@"ChromaBlend",@"TerraForm",@"AeroStream",@"NanoMesh",
        @"FluxField",@"MetaPort",@"EchoScan",@"VertexCore",@"SolsticeRay",
        @"OrionWave",@"CipherCode",@"PrismFlash",@"NexusLink",@"AetherPulse",
        @"VortexPath",@"QuantumShift",@"ChromaGlow",@"TerraCell",@"AeroFlux",
        @"NanoSync",@"FluxWave",@"MetaLens",@"EchoBeam",@"VertexSphere",
        @"SolsticeFlow",@"OrionCore",@"CipherGrid",@"PrismByte",@"NexusField",
        @"AetherRing",@"VortexSync",@"QuantumBeam",@"ChromaPulse",@"TerraGlide",
        @"AeroCell",@"NanoForge",@"FluxLink",@"MetaTide",@"EchoDrive",
        @"VertexShift",@"SolsticeSync",@"OrionMesh",@"CipherPort",@"PrismNode",
        @"NexusGlow",@"AetherPath",@"VortexLeap",@"QuantumRing",@"ChromaSync",
        @"TerraSpark",@"AeroTrace",@"NanoLens",@"FluxBeam",@"MetaPulse",
        @"EchoField",@"VertexFlow",@"SolsticePort",@"OrionShift",@"CipherTide",
        @"PrismLink",@"NexusSync",@"AetherGlide",@"VortexFrame",@"QuantumMesh",
        @"ChromaForge",@"TerraNode",@"AeroPulse",@"NanoRing",@"FluxSync",
        @"MetaBeam",@"EchoGlow",@"VertexTide",@"SolsticeLink",@"OrionSync",
        @"CipherLeap",@"PrismPath",@"NexusForge",@"AetherCell",@"VortexShift",
        @"QuantumTide",@"ChromaLink",@"TerraSync",@"AeroLeap",@"NanoPath",
        @"FluxForge",@"MetaShift",@"EchoTide",@"VertexSync",@"SolsticeForge",
        @"OrionLeap",@"CipherPath",@"PrismForge",@"NexusPath",@"AetherForge",
        @"VortexLeap",@"QuantumPath",@"ChromaForge",@"TerraLeap",@"AeroPath",
        @"NanoLeap",@"FluxPath",@"MetaLeap",@"EchoPath",@"VertexLeap",
        @"SolsticePath",@"OrionPath",@"CipherForge",@"PrismLeap",@"NexusLeap",
        @"AetherPath",@"VortexForge",@"QuantumForge",@"ChromaLeap",@"TerraForge",
        @"AeroForge",@"NanoForge",@"FluxLeap",@"MetaForge",@"EchoForge",
        @"VertexForge",@"SolsticeForge",@"OrionForge",@"CipherLeap",@"PrismForge",
        @"NexusForge",@"AetherLeap",@"VortexPath",@"QuantumLeap",@"ChromaPath",
        @"TerraPath",@"AeroLeap",@"NanoPath",@"FluxForge",@"MetaPath",
        @"EchoLeap",@"VertexPath",@"SolsticeLeap",@"OrionPath",@"CipherPath",
        @"PrismPath",@"NexusPath",@"AetherForge",@"VortexLeap",@"QuantumPath",
        @"ChromaLeap",@"TerraLeap",@"AeroPath",@"NanoLeap",@"FluxPath",
        @"MetaLeap",@"EchoPath",@"VertexLeap",@"SolsticePath",@"OrionLeap",
        @"CipherForge",@"PrismLeap",@"NexusLeap",@"AetherPath",@"VortexForge",
        @"QuantumForge",@"ChromaPath",@"TerraForge",@"AeroForge",@"NanoPath",
        @"FluxLeap",@"MetaForge",@"EchoForge",@"VertexPath",@"SolsticeForge",
        @"OrionForge",@"CipherLeap",@"PrismForge",@"NexusForge",@"AetherLeap",
        @"VortexPath",@"QuantumLeap",@"ChromaForge",@"TerraPath",@"AeroLeap",
        @"NanoForge",@"FluxPath",@"MetaPath",@"EchoLeap",@"VertexForge",
        @"SolsticeLeap",@"OrionPath",@"CipherPath",@"PrismLeap",@"NexusPath",
        @"AetherForge",@"VortexLeap",@"QuantumPath",@"ChromaLeap",@"TerraLeap",
        @"AeroPath",@"NanoLeap",@"FluxForge",@"MetaLeap",@"EchoPath",
        @"VertexLeap",@"SolsticePath",@"OrionLeap",@"CipherForge",@"PrismPath",
        @"NexusLeap",@"AetherPath",@"VortexForge",@"QuantumForge",@"ChromaPath",
        @"TerraForge",@"AeroForge",@"NanoPath",@"FluxLeap",@"MetaForge",
        @"EchoForge",@"VertexPath",@"SolsticeForge",@"OrionForge",@"CipherLeap",
        @"PrismForge",@"NexusForge",@"AetherLeap",@"VortexPath",@"QuantumLeap",
        @"ChromaForge",@"TerraPath",@"AeroLeap",@"NanoForge",@"FluxPath",
        @"MetaPath",@"EchoLeap",@"VertexForge",@"SolsticeLeap",@"OrionPath",
        @"CipherPath",@"PrismLeap",@"NexusPath",@"AetherForge",@"VortexLeap",
        @"QuantumPath",@"ChromaLeap",@"TerraLeap",@"AeroPath",@"NanoLeap",
        @"FluxForge",@"MetaLeap",@"EchoPath",@"VertexLeap",@"SolsticePath",
        @"OrionLeap",@"CipherForge",@"PrismPath",@"NexusLeap",@"AetherPath",
        @"VortexForge",@"QuantumForge",@"ChromaPath",@"TerraForge",@"AeroForge",
        @"NanoPath",@"FluxLeap",@"MetaForge",@"EchoForge",@"VertexPath",
        @"SolsticeForge",@"OrionForge",@"CipherLeap",@"PrismForge",@"NexusForge",
        @"AetherLeap",@"VortexPath",@"QuantumLeap",@"ChromaForge",@"TerraPath",
        @"AeroLeap",@"NanoForge",@"FluxPath",@"MetaPath",@"EchoLeap",
        @"VertexForge",@"SolsticeLeap",@"OrionPath",@"CipherPath",@"PrismLeap",
        @"NexusPath",@"AetherForge",@"VortexLeap",@"QuantumPath",@"ChromaLeap",
        @"TerraLeap",@"AeroPath",@"NanoLeap",@"FluxForge",@"MetaLeap",
        @"EchoPath",@"VertexLeap",@"SolsticePath",@"OrionLeap",@"CipherForge",
        @"PrismPath",@"NexusLeap",@"AetherPath",@"VortexForge",@"QuantumForge",
        @"ChromaPath",@"TerraForge",@"AeroForge",@"NanoPath",@"FluxLeap",
        @"MetaForge",@"EchoForge",@"VertexPath",@"SolsticeForge",@"OrionForge",
        @"CipherLeap",@"PrismForge",@"NexusForge",@"AetherLeap",@"VortexPath",
        @"QuantumLeap",@"ChromaForge",@"TerraPath",@"AeroLeap",@"NanoForge",
        @"FluxPath",@"MetaPath",@"EchoLeap",@"VertexForge",@"SolsticeLeap",
        @"OrionPath",@"CipherPath",@"PrismLeap",@"NexusPath",@"AetherForge",
        @"VortexLeap",@"QuantumPath",@"ChromaLeap",@"TerraLeap",@"AeroPath",
        @"NanoLeap",@"FluxForge",@"MetaLeap",@"EchoPath",@"VertexLeap",
        @"SolsticePath",@"OrionLeap",@"CipherForge",@"PrismPath",@"NexusLeap",
        @"AetherPath",@"VortexForge",@"QuantumForge",@"ChromaPath",@"TerraForge",
        @"AeroForge",@"NanoPath",@"FluxLeap",@"MetaForge",@"EchoForge",
        @"VertexPath",@"SolsticeForge",@"OrionForge",@"CipherLeap",@"PrismForge",
        @"NexusForge",@"AetherLeap",@"VortexPath",@"QuantumLeap",@"ChromaForge",
        @"TerraPath",@"AeroLeap",@"NanoForge",@"FluxPath",@"MetaPath",
        @"EchoLeap",@"VertexForge",@"SolsticeLeap",@"OrionPath",@"CipherPath",
        @"PrismLeap",@"NexusPath",@"AetherForge",@"VortexLeap",@"QuantumPath",
        @"ChromaLeap",@"TerraLeap",@"AeroPath",@"NanoLeap",@"FluxForge",
        @"MetaLeap",@"EchoPath",@"VertexLeap",@"SolsticePath",@"OrionLeap",
        @"CipherForge",@"PrismPath",@"NexusLeap",@"AetherPath",@"VortexForge",
        @"QuantumForge",@"ChromaPath",@"TerraForge",@"AeroForge",@"NanoPath",
        @"FluxLeap",@"MetaForge",@"EchoForge",@"VertexPath",@"SolsticeForge",
        @"OrionForge",@"CipherLeap",@"PrismForge",@"NexusForge",@"AetherLeap",
        @"VortexPath",@"QuantumLeap",@"ChromaForge",@"TerraPath",@"AeroLeap",
        @"NanoForge",@"FluxPath",@"MetaPath",@"EchoLeap",@"VertexForge",
        @"SolsticeLeap",@"OrionPath",@"CipherPath",@"PrismLeap",@"NexusPath",
        @"AetherForge",@"VortexLeap",@"QuantumPath",@"ChromaLeap",@"TerraLeap",
        @"AeroPath",@"NanoLeap",@"FluxForge",@"MetaLeap",@"EchoPath",
        @"VertexLeap",@"SolsticePath",@"OrionLeap",@"CipherForge",@"PrismPath",
        @"NexusLeap",@"AetherPath",@"VortexForge",@"QuantumForge",@"ChromaPath",
        @"TerraForge",@"AeroForge",@"NanoPath",@"FluxLeap",@"MetaForge",
        @"EchoForge",@"VertexPath",@"SolsticeForge",@"OrionForge",@"CipherLeap",
        @"PrismForge",@"NexusForge",@"AetherLeap",@"VortexPath",@"QuantumLeap",
        @"ChromaForge",@"TerraPath",@"AeroLeap",@"NanoForge",@"FluxPath",
        @"MetaPath",@"EchoLeap",@"VertexForge",@"SolsticeLeap",@"OrionPath",
        @"CipherPath",@"PrismLeap",@"NexusPath",@"AetherForge",@"VortexLeap",
        @"QuantumPath",@"ChromaLeap",@"TerraLeap",@"AeroPath",@"NanoLeap",
        @"FluxForge",@"MetaLeap",@"EchoPath",@"VertexLeap",@"SolsticePath",
        @"OrionLeap",@"CipherForge",@"PrismPath",@"NexusLeap",@"AetherPath",
        @"VortexForge",@"QuantumForge",@"ChromaPath",@"TerraForge",@"AeroForge",
        @"NanoPath",@"FluxLeap",@"MetaForge",@"EchoForge",@"VertexPath",
        @"SolsticeForge",@"OrionForge",@"CipherLeap",@"PrismForge",@"NexusForge",
        @"AetherLeap",@"VortexPath",@"QuantumLeap",@"ChromaForge",@"TerraPath",
        @"AeroLeap",@"NanoForge",@"FluxPath",@"MetaPath",@"EchoLeap",
        @"VertexForge",@"SolsticeLeap",@"OrionPath",@"CipherPath",@"PrismLeap",
        @"NexusPath",@"AetherForge",@"VortexLeap",@"QuantumPath",@"ChromaLeap",
        @"TerraLeap",@"AeroPath",@"NanoLeap",@"FluxForge",@"MetaLeap",
        @"EchoPath",@"VertexLeap",@"SolsticePath",@"OrionLeap",@"CipherForge",
        @"PrismPath",@"NexusLeap",@"AetherPath",@"VortexForge",@"QuantumForge",
        @"ChromaPath",@"TerraForge",@"AeroForge",@"NanoPath",@"FluxLeap",
        @"MetaForge",@"EchoForge",@"VertexPath",@"SolsticeForge",@"OrionForge",
        @"CipherLeap",@"PrismForge",@"NexusForge",@"AetherLeap",@"VortexPath",
        @"QuantumLeap",@"ChromaForge",@"TerraPath",@"AeroLeap",@"NanoForge",
        @"FluxPath",@"MetaPath",@"EchoLeap",@"VertexForge",@"SolsticeLeap",
        @"OrionPath",@"CipherPath",@"PrismLeap",@"NexusPath",@"AetherForge",
        @"VortexLeap",@"QuantumPath",@"ChromaLeap",@"TerraLeap",@"AeroPath",
        @"NanoLeap",@"FluxForge",@"MetaLeap",@"EchoPath",@"VertexLeap",
        @"SolsticePath",@"OrionLeap",@"CipherForge",@"PrismPath",@"NexusLeap",
        @"AetherPath",@"VortexForge",@"QuantumForge",@"ChromaPath",@"TerraForge",
        @"AeroForge",@"NanoPath",@"FluxLeap",@"MetaForge",@"EchoForge",
        @"VertexPath",@"SolsticeForge",@"OrionForge",@"CipherLeap",@"PrismForge",
        @"NexusForge",@"AetherLeap",@"VortexPath",@"QuantumLeap",@"ChromaForge"
    ];
}

+ (NSArray *)operationNouns {
    return @[

        @"高效", @"快速", @"优化", @"高性能", @"低延迟",@"轻量", @"节省内存", @"节省CPU", @"节省电量", @"响应式",
        @"安全", @"加密", @"验证", @"签名", @"认证",@"隐私", @"沙盒", @"隔离", @"防护", @"审查",
        @"可靠", @"稳定", @"健壮", @"容错", @"弹性",@"精确", @"一致", @"完整", @"可用", @"持久",
        @"智能", @"自适应", @"动态", @"可配置", @"可扩展",@"模块化", @"插件式", @"可复用", @"可定制", @"可组合",
        @"临时", @"缓存", @"预加载", @"延迟", @"异步",@"批量", @"并行", @"串行", @"排队", @"优先级",
        @"发展", @"人民", @"国家", @"社会", @"经济",
         @"文化", @"科技", @"教育", @"历史", @"传统",
         @"创新", @"改革", @"开放", @"政策", @"法律",
         @"制度", @"环境", @"资源", @"能源", @"农业",
         @"工业", @"商业", @"金融", @"市场", @"企业",
         @"生产", @"消费", @"投资", @"贸易", @"增长",
         @"稳定", @"安全", @"和平", @"战争", @"国际",
         @"世界", @"全球", @"地区", @"城市", @"乡村",
         @"建设", @"规划", @"管理", @"服务", @"公共",
         @"医疗", @"健康", @"疾病", @"治疗", @"预防",
         @"科学", @"研究", @"实验", @"发现", @"理论",
         @"数据", @"信息", @"知识", @"智慧", @"智能",
         @"网络", @"数字", @"媒体", @"传播", @"新闻",
         @"艺术", @"音乐", @"绘画", @"文学", @"诗歌",
         @"电影", @"戏剧", @"舞蹈", @"设计", @"创作",
         @"体育", @"运动", @"比赛", @"训练", @"健康",
         @"食物", @"饮食", @"营养", @"农业", @"农民",
         @"自然", @"生态", @"动物", @"植物", @"森林",
         @"气候", @"天气", @"温度", @"雨", @"雪",
         @"地理", @"山脉", @"河流", @"海洋", @"土地",
         @"政治", @"政府", @"领导", @"选举", @"权力",
         @"军事", @"武器", @"防御", @"攻击", @"士兵",
         @"宗教", @"信仰", @"神", @"教堂", @"祈祷",
         @"哲学", @"思想", @"真理", @"现实", @"存在",
         @"心理", @"情感", @"感觉", @"记忆", @"学习",
         @"语言", @"文字", @"沟通", @"表达", @"理解",
         @"数学", @"数字", @"计算", @"公式", @"几何",
         @"物理", @"化学", @"生物", @"医学", @"工程",
         @"时间", @"空间", @"宇宙", @"星球", @"光",
         @"速度", @"力量", @"能量", @"物质", @"原子",
         @"家庭", @"父母", @"孩子", @"婚姻", @"爱情",
         @"友谊", @"社区", @"邻居", @"合作", @"竞争",
         @"工作", @"职业", @"公司", @"老板", @"员工",
         @"成功", @"失败", @"目标", @"计划", @"未来",
         @"过去", @"现在", @"年龄", @"生命", @"死亡",
         @"快乐", @"悲伤", @"愤怒", @"恐惧", @"惊讶",
         @"美丽", @"丑陋", @"善良", @"邪恶", @"道德",
         @"责任", @"权利", @"义务", @"自由", @"限制",
         @"学校", @"大学", @"老师", @"学生", @"考试",
         @"书籍", @"阅读", @"写作", @"出版", @"图书馆",
         @"电脑", @"手机", @"互联网", @"软件", @"硬件",
         @"游戏", @"娱乐", @"旅游", @"假期", @"节日",
         @"钱", @"财富", @"贫穷", @"银行", @"税收",
         @"交通", @"汽车", @"飞机", @"火车", @"船",
         @"建筑", @"房屋", @"道路", @"桥梁", @"公园",
         @"衣服", @"时尚", @"设计", @"颜色", @"风格",
         @"问题", @"答案", @"解决", @"困难", @"挑战",
         @"变化", @"进步", @"发展", @"革命", @"进化",
         @"原因", @"结果", @"影响", @"关系", @"系统",
         @"质量", @"数量", @"程度", @"水平", @"标准",
         @"机会", @"风险", @"决定", @"选择", @"命运",
        
        @"efficient", @"fast", @"optimized", @"high-performance", @"low-latency",
        @"lightweight", @"memory-saving", @"CPU-saving", @"energy-saving", @"responsive",
        @"secure", @"encrypted", @"verified", @"signed", @"authenticated",
        @"private", @"sandboxed", @"isolated", @"protected", @"audited",
        @"reliable", @"stable", @"robust", @"fault-tolerant", @"resilient",
        @"accurate", @"consistent", @"complete", @"available", @"persistent",
        @"smart", @"adaptive", @"dynamic", @"configurable", @"extensible",
        @"modular", @"pluggable", @"reusable", @"customizable", @"composable",
        @"temporary", @"cached", @"preloaded", @"delayed", @"asynchronous",
        @"batched", @"parallel", @"serial", @"queued", @"prioritized",
        @"development", @"people", @"country", @"society", @"economy",
        @"culture", @"technology", @"education", @"history", @"tradition",
        @"innovation", @"reform", @"openness", @"policy", @"law",
        @"system", @"environment", @"resource", @"energy", @"agriculture",
        @"industry", @"business", @"finance", @"market", @"company",
        @"production", @"consumption", @"investment", @"trade", @"growth",
        @"stability", @"security", @"peace", @"war", @"international",
        @"world", @"global", @"region", @"city", @"village",
        @"construction", @"planning", @"management", @"service", @"public",
        @"medical", @"health", @"disease", @"treatment", @"prevention",
        @"science", @"research", @"experiment", @"discovery", @"theory",
        @"data", @"information", @"knowledge", @"wisdom", @"intelligence",
        @"network", @"digital", @"media", @"communication", @"news",
        @"art", @"music", @"painting", @"literature", @"poetry",
        @"movie", @"drama", @"dance", @"design", @"creation",
        @"sports", @"exercise", @"competition", @"training", @"health",
        @"food", @"diet", @"nutrition", @"farming", @"farmer",
        @"nature", @"ecology", @"animal", @"plant", @"forest",
        @"climate", @"weather", @"temperature", @"rain", @"snow",
        @"geography", @"mountain", @"river", @"ocean", @"land",
        @"politics", @"government", @"leadership", @"election", @"power",
        @"military", @"weapon", @"defense", @"attack", @"soldier",
        @"religion", @"belief", @"god", @"church", @"prayer",
        @"philosophy", @"thought", @"truth", @"reality", @"existence",
        @"psychology", @"emotion", @"feeling", @"memory", @"learning",
        @"language", @"writing", @"communication", @"expression", @"understanding",
        @"mathematics", @"number", @"calculation", @"formula", @"geometry",
        @"physics", @"chemistry", @"biology", @"medicine", @"engineering",
        @"time", @"space", @"universe", @"planet", @"light",
        @"speed", @"force", @"energy", @"matter", @"atom",
        @"family", @"parent", @"child", @"marriage", @"love",
        @"friendship", @"community", @"neighbor", @"cooperation", @"competition",
        @"work", @"career", @"corporation", @"boss", @"employee",
        @"success", @"failure", @"goal", @"plan", @"future",
        @"past", @"present", @"age", @"life", @"death",
        @"happiness", @"sadness", @"anger", @"fear", @"surprise",
        @"beauty", @"ugliness", @"kindness", @"evil", @"morality",
        @"responsibility", @"right", @"duty", @"freedom", @"limitation",
        @"school", @"university", @"teacher", @"student", @"exam",
        @"book", @"reading", @"writing", @"publishing", @"library",
        @"computer", @"phone", @"internet", @"software", @"hardware",
        @"game", @"entertainment", @"travel", @"vacation", @"festival",
        @"money", @"wealth", @"poverty", @"bank", @"tax",
        @"transportation", @"car", @"airplane", @"train", @"ship",
        @"architecture", @"house", @"road", @"bridge", @"park",
        @"clothing", @"fashion", @"design", @"color", @"style",
        @"problem", @"answerTo", @"solution", @"difficulty", @"challenge",
        @"change", @"progress", @"development", @"revolution", @"evolution",
        @"cause", @"effect", @"influence", @"relationship", @"system",
        @"quality", @"quantity", @"degree", @"level", @"standard",
        @"opportunity", @"risk", @"decision", @"choice", @"destiny",
        @"QuantumFlow",@"NexusSphere",@"VortexCore",@"SynapseLink",@"ChromaWave",
        @"TerraFrame",@"AeroGlide",@"NanoForge",@"FluxNode",@"MetaMesh",
        @"EchoPulse",@"VertexDrive",@"SolsticeBeam",@"OrionShell",@"CipherLock",
        @"PrismScale",@"NexusTide",@"AetherByte",@"VortexLens",@"QuantumLeap",
        @"ChromaShift",@"TerraByte",@"AeroBurst",@"NanoCell",@"FluxGate",
        @"MetaGrid",@"EchoTrace",@"VertexPort",@"SolsticeGlow",@"OrionField",
        @"CipherKey",@"PrismSpark",@"NexusBeam",@"AetherFlow",@"VortexRing",
        @"QuantumSync",@"ChromaBlend",@"TerraForm",@"AeroStream",@"NanoMesh",
        @"FluxField",@"MetaPort",@"EchoScan",@"VertexCore",@"SolsticeRay",
        @"OrionWave",@"CipherCode",@"PrismFlash",@"NexusLink",@"AetherPulse",
        @"VortexPath",@"QuantumShift",@"ChromaGlow",@"TerraCell",@"AeroFlux",
        @"NanoSync",@"FluxWave",@"MetaLens",@"EchoBeam",@"VertexSphere",
        @"SolsticeFlow",@"OrionCore",@"CipherGrid",@"PrismByte",@"NexusField",
        @"AetherRing",@"VortexSync",@"QuantumBeam",@"ChromaPulse",@"TerraGlide",
        @"AeroCell",@"NanoForge",@"FluxLink",@"MetaTide",@"EchoDrive",
        @"VertexShift",@"SolsticeSync",@"OrionMesh",@"CipherPort",@"PrismNode",
        @"NexusGlow",@"AetherPath",@"VortexLeap",@"QuantumRing",@"ChromaSync",
        @"TerraSpark",@"AeroTrace",@"NanoLens",@"FluxBeam",@"MetaPulse",
        @"EchoField",@"VertexFlow",@"SolsticePort",@"OrionShift",@"CipherTide",
        @"PrismLink",@"NexusSync",@"AetherGlide",@"VortexFrame",@"QuantumMesh",
        @"ChromaForge",@"TerraNode",@"AeroPulse",@"NanoRing",@"FluxSync",
        @"MetaBeam",@"EchoGlow",@"VertexTide",@"SolsticeLink",@"OrionSync",
        @"CipherLeap",@"PrismPath",@"NexusForge",@"AetherCell",@"VortexShift",
        @"QuantumTide",@"ChromaLink",@"TerraSync",@"AeroLeap",@"NanoPath",
        @"FluxForge",@"MetaShift",@"EchoTide",@"VertexSync",@"SolsticeForge",
        @"OrionLeap",@"CipherPath",@"PrismForge",@"NexusPath",@"AetherForge",
        @"VortexLeap",@"QuantumPath",@"ChromaForge",@"TerraLeap",@"AeroPath",
        @"NanoLeap",@"FluxPath",@"MetaLeap",@"EchoPath",@"VertexLeap",
        @"SolsticePath",@"OrionPath",@"CipherForge",@"PrismLeap",@"NexusLeap",
        @"AetherPath",@"VortexForge",@"QuantumForge",@"ChromaLeap",@"TerraForge",
        @"AeroForge",@"NanoForge",@"FluxLeap",@"MetaForge",@"EchoForge",
        @"VertexForge",@"SolsticeForge",@"OrionForge",@"CipherLeap",@"PrismForge",
        @"NexusForge",@"AetherLeap",@"VortexPath",@"QuantumLeap",@"ChromaPath",
        @"TerraPath",@"AeroLeap",@"NanoPath",@"FluxForge",@"MetaPath",
        @"EchoLeap",@"VertexPath",@"SolsticeLeap",@"OrionPath",@"CipherPath",
        @"PrismPath",@"NexusPath",@"AetherForge",@"VortexLeap",@"QuantumPath",
        @"ChromaLeap",@"TerraLeap",@"AeroPath",@"NanoLeap",@"FluxPath",
        @"MetaLeap",@"EchoPath",@"VertexLeap",@"SolsticePath",@"OrionLeap",
        @"CipherForge",@"PrismLeap",@"NexusLeap",@"AetherPath",@"VortexForge",
        @"QuantumForge",@"ChromaPath",@"TerraForge",@"AeroForge",@"NanoPath",
        @"FluxLeap",@"MetaForge",@"EchoForge",@"VertexPath",@"SolsticeForge",
        @"OrionForge",@"CipherLeap",@"PrismForge",@"NexusForge",@"AetherLeap",
        @"VortexPath",@"QuantumLeap",@"ChromaForge",@"TerraPath",@"AeroLeap",
        @"NanoForge",@"FluxPath",@"MetaPath",@"EchoLeap",@"VertexForge",
        @"SolsticeLeap",@"OrionPath",@"CipherPath",@"PrismLeap",@"NexusPath",
        @"AetherForge",@"VortexLeap",@"QuantumPath",@"ChromaLeap",@"TerraLeap",
        @"AeroPath",@"NanoLeap",@"FluxForge",@"MetaLeap",@"EchoPath",
        @"VertexLeap",@"SolsticePath",@"OrionLeap",@"CipherForge",@"PrismPath",
        @"NexusLeap",@"AetherPath",@"VortexForge",@"QuantumForge",@"ChromaPath",
        @"TerraForge",@"AeroForge",@"NanoPath",@"FluxLeap",@"MetaForge",
        @"EchoForge",@"VertexPath",@"SolsticeForge",@"OrionForge",@"CipherLeap",
        @"PrismForge",@"NexusForge",@"AetherLeap",@"VortexPath",@"QuantumLeap",
        @"ChromaForge",@"TerraPath",@"AeroLeap",@"NanoForge",@"FluxPath",
        @"MetaPath",@"EchoLeap",@"VertexForge",@"SolsticeLeap",@"OrionPath",
        @"CipherPath",@"PrismLeap",@"NexusPath",@"AetherForge",@"VortexLeap",
        @"QuantumPath",@"ChromaLeap",@"TerraLeap",@"AeroPath",@"NanoLeap",
        @"FluxForge",@"MetaLeap",@"EchoPath",@"VertexLeap",@"SolsticePath",
        @"OrionLeap",@"CipherForge",@"PrismPath",@"NexusLeap",@"AetherPath",
        @"VortexForge",@"QuantumForge",@"ChromaPath",@"TerraForge",@"AeroForge",
        @"NanoPath",@"FluxLeap",@"MetaForge",@"EchoForge",@"VertexPath",
        @"SolsticeForge",@"OrionForge",@"CipherLeap",@"PrismForge",@"NexusForge",
        @"AetherLeap",@"VortexPath",@"QuantumLeap",@"ChromaForge",@"TerraPath",
        @"AeroLeap",@"NanoForge",@"FluxPath",@"MetaPath",@"EchoLeap",
        @"VertexForge",@"SolsticeLeap",@"OrionPath",@"CipherPath",@"PrismLeap",
        @"NexusPath",@"AetherForge",@"VortexLeap",@"QuantumPath",@"ChromaLeap",
        @"TerraLeap",@"AeroPath",@"NanoLeap",@"FluxForge",@"MetaLeap",
        @"EchoPath",@"VertexLeap",@"SolsticePath",@"OrionLeap",@"CipherForge",
        @"PrismPath",@"NexusLeap",@"AetherPath",@"VortexForge",@"QuantumForge",
        @"ChromaPath",@"TerraForge",@"AeroForge",@"NanoPath",@"FluxLeap",
        @"MetaForge",@"EchoForge",@"VertexPath",@"SolsticeForge",@"OrionForge",
        @"CipherLeap",@"PrismForge",@"NexusForge",@"AetherLeap",@"VortexPath",
        @"QuantumLeap",@"ChromaForge",@"TerraPath",@"AeroLeap",@"NanoForge",
        @"FluxPath",@"MetaPath",@"EchoLeap",@"VertexForge",@"SolsticeLeap",
        @"OrionPath",@"CipherPath",@"PrismLeap",@"NexusPath",@"AetherForge",
        @"VortexLeap",@"QuantumPath",@"ChromaLeap",@"TerraLeap",@"AeroPath",
        @"NanoLeap",@"FluxForge",@"MetaLeap",@"EchoPath",@"VertexLeap",
        @"SolsticePath",@"OrionLeap",@"CipherForge",@"PrismPath",@"NexusLeap",
        @"AetherPath",@"VortexForge",@"QuantumForge",@"ChromaPath",@"TerraForge",
        @"AeroForge",@"NanoPath",@"FluxLeap",@"MetaForge",@"EchoForge",
        @"VertexPath",@"SolsticeForge",@"OrionForge",@"CipherLeap",@"PrismForge",
        @"NexusForge",@"AetherLeap",@"VortexPath",@"QuantumLeap",@"ChromaForge",
        @"TerraPath",@"AeroLeap",@"NanoForge",@"FluxPath",@"MetaPath",
        @"EchoLeap",@"VertexForge",@"SolsticeLeap",@"OrionPath",@"CipherPath",
        @"PrismLeap",@"NexusPath",@"AetherForge",@"VortexLeap",@"QuantumPath",
        @"ChromaLeap",@"TerraLeap",@"AeroPath",@"NanoLeap",@"FluxForge",
        @"MetaLeap",@"EchoPath",@"VertexLeap",@"SolsticePath",@"OrionLeap",
        @"CipherForge",@"PrismPath",@"NexusLeap",@"AetherPath",@"VortexForge",
        @"QuantumForge",@"ChromaPath",@"TerraForge",@"AeroForge",@"NanoPath",
        @"FluxLeap",@"MetaForge",@"EchoForge",@"VertexPath",@"SolsticeForge",
        @"OrionForge",@"CipherLeap",@"PrismForge",@"NexusForge",@"AetherLeap",
        @"VortexPath",@"QuantumLeap",@"ChromaForge",@"TerraPath",@"AeroLeap",
        @"NanoForge",@"FluxPath",@"MetaPath",@"EchoLeap",@"VertexForge",
        @"SolsticeLeap",@"OrionPath",@"CipherPath",@"PrismLeap",@"NexusPath",
        @"AetherForge",@"VortexLeap",@"QuantumPath",@"ChromaLeap",@"TerraLeap",
        @"AeroPath",@"NanoLeap",@"FluxForge",@"MetaLeap",@"EchoPath",
        @"VertexLeap",@"SolsticePath",@"OrionLeap",@"CipherForge",@"PrismPath",
        @"NexusLeap",@"AetherPath",@"VortexForge",@"QuantumForge",@"ChromaPath",
        @"TerraForge",@"AeroForge",@"NanoPath",@"FluxLeap",@"MetaForge",
        @"EchoForge",@"VertexPath",@"SolsticeForge",@"OrionForge",@"CipherLeap",
        @"PrismForge",@"NexusForge",@"AetherLeap",@"VortexPath",@"QuantumLeap",
        @"ChromaForge",@"TerraPath",@"AeroLeap",@"NanoForge",@"FluxPath",
        @"MetaPath",@"EchoLeap",@"VertexForge",@"SolsticeLeap",@"OrionPath",
        @"CipherPath",@"PrismLeap",@"NexusPath",@"AetherForge",@"VortexLeap",
        @"QuantumPath",@"ChromaLeap",@"TerraLeap",@"AeroPath",@"NanoLeap",
        @"FluxForge",@"MetaLeap",@"EchoPath",@"VertexLeap",@"SolsticePath",
        @"OrionLeap",@"CipherForge",@"PrismPath",@"NexusLeap",@"AetherPath",
        @"VortexForge",@"QuantumForge",@"ChromaPath",@"TerraForge",@"AeroForge",
        @"NanoPath",@"FluxLeap",@"MetaForge",@"EchoForge",@"VertexPath",
        @"SolsticeForge",@"OrionForge",@"CipherLeap",@"PrismForge",@"NexusForge",
        @"AetherLeap",@"VortexPath",@"QuantumLeap",@"ChromaForge",@"TerraPath",
        @"AeroLeap",@"NanoForge",@"FluxPath",@"MetaPath",@"EchoLeap",
        @"VertexForge",@"SolsticeLeap",@"OrionPath",@"CipherPath",@"PrismLeap",
        @"NexusPath",@"AetherForge",@"VortexLeap",@"QuantumPath",@"ChromaLeap",
        @"TerraLeap",@"AeroPath",@"NanoLeap",@"FluxForge",@"MetaLeap",
        @"EchoPath",@"VertexLeap",@"SolsticePath",@"OrionLeap",@"CipherForge",
        @"PrismPath",@"NexusLeap",@"AetherPath",@"VortexForge",@"QuantumForge",
        @"ChromaPath",@"TerraForge",@"AeroForge",@"NanoPath",@"FluxLeap",
        @"MetaForge",@"EchoForge",@"VertexPath",@"SolsticeForge",@"OrionForge",
        @"CipherLeap",@"PrismForge",@"NexusForge",@"AetherLeap",@"VortexPath",
        @"QuantumLeap",@"ChromaForge",@"TerraPath",@"AeroLeap",@"NanoForge",
        @"FluxPath",@"MetaPath",@"EchoLeap",@"VertexForge",@"SolsticeLeap",
        @"OrionPath",@"CipherPath",@"PrismLeap",@"NexusPath",@"AetherForge",
        @"VortexLeap",@"QuantumPath",@"ChromaLeap",@"TerraLeap",@"AeroPath",
        @"NanoLeap",@"FluxForge",@"MetaLeap",@"EchoPath",@"VertexLeap",
        @"SolsticePath",@"OrionLeap",@"CipherForge",@"PrismPath",@"NexusLeap",
        @"AetherPath",@"VortexForge",@"QuantumForge",@"ChromaPath",@"TerraForge",
        @"AeroForge",@"NanoPath",@"FluxLeap",@"MetaForge",@"EchoForge",
        @"VertexPath",@"SolsticeForge",@"OrionForge",@"CipherLeap",@"PrismForge",
        @"NexusForge",@"AetherLeap",@"VortexPath",@"QuantumLeap",@"ChromaForge"
    ];
}

+ (NSDictionary *)paramTypeMap {
    return @{
        @"id": @"目标对象",
        @"NSObject": @"基础对象",
        @"NSString": @"字符串内容",
        @"NSNumber": @"数值参数",
        @"NSArray": @"数组集合",
        @"NSDictionary": @"键值对字典",
        @"NSSet": @"无序集合",
        @"NSData": @"二进制数据",
        @"NSDate": @"日期时间",
        @"NSURL": @"资源定位符",
        @"BOOL": @"布尔标志",
        @"Boolean": @"布尔值",
        @"bool": @"C布尔值",
        @"int": @"整数值",
        @"NSInteger": @"对象整型",
        @"NSUInteger": @"无符号整型",
        @"float": @"单精度浮点",
        @"CGFloat": @"核心图形浮点",
        @"double": @"双精度浮点",
        @"long": @"长整型",
        @"NSError": @"错误对象",
        @"NSError**": @"错误指针",
        @"SEL": @"选择器",
        @"Class": @"类对象",
        @"Protocol": @"协议对象",
        @"Block": @"代码块",
        @"void*": @"空指针",
        @"CGRect": @"矩形区域",
        @"CGPoint": @"坐标点",
        @"CGSize": @"尺寸大小",
        @"NSRange": @"范围值",
        @"UIEdgeInsets": @"边缘间距",
        @"NSURLRequest": @"URL请求",
        @"NSURLResponse": @"URL响应",
        @"NSHTTPURLResponse": @"HTTP响应",
        @"NSURLSession": @"会话对象",
        @"NSURLSessionTask": @"会话任务",
        @"completion": @"完成回调块",
        @"success": @"成功回调块",
        @"failure": @"失败回调块",
        @"progress": @"进度回调块",
        @"handler": @"通用处理块",
        @"callback": @"回调函数",
        @"delegate": @"委托对象",
    };
}

+ (NSArray *)callbackNotes {
    return @[

        @" * @note 回调将在主线程执行",
        @" * @note 回调在后台线程执行，如需UI更新请手动切换到主线程",
        @" * @note 回调执行线程取决于调用时的参数配置",
        @" * @note 回调可能在任意线程执行，请做好线程同步",
        
        @" * @warning 回调可能被多次调用，请做好状态管理",
        @" * @warning 回调可能不会被调用，请设置超时处理",
        @" * @note 回调会强引用self，注意循环引用问题",
        @" * @warning 回调执行时对象可能已经被释放",

        @" * @warning 回调参数可能为nil，调用前请检查",
        @" * @note 回调的第一个参数总是表示操作结果",
        @" * @warning 回调中的error参数只在失败时有效",
        @" * @note 回调中的response参数可能被复用",
        
        @" * @note 回调中应避免耗时操作",
        @" * @warning 回调中不要执行同步网络请求",
        @" * @note 回调中创建的对象需要手动释放",
        @" * @warning 回调中不要直接修改UI元素",
 
        @" * @see 相关回调定义参见XXXProtocol",
        @" * @since 异步回调从v2.0开始支持",
        @" * @deprecated 考虑使用新的基于block的API替代",
        @" * @note 回调执行顺序不能保证",
        
        @" * @warning 回调中抛出的异常不会被捕获",
        @" * @note 回调中的错误码定义参见XXXError.h",
        @" * @warning 某些情况下回调可能带有部分成功的结果",
        @" * @note 回调可能因为系统限制而被取消",
        @" * @note 在后台状态下回调可能被延迟",
        @" * @warning 低电量模式下回调频率可能降低",
        @" * @note 某些回调可能在沙盒限制下无法正常工作",
        @" * @warning 在extension中某些回调不可用",
        @" * @debug 回调执行时会打印日志",
        @" * @test 该回调在单元测试中被模拟",
        @" * @note 回调性能指标会被统计",
        @" * @warning 调试版本中回调会有额外验证",

        @" * @compatibility 该回调在iOS 13+可用",
        @" * @iPad 回调在分屏模式下行为可能不同",
        @" * @macCatalyst 回调在Mac上有特殊处理",
        @" * @availability 某些回调在特定区域不可用",
        
        // Threading Behavior
        @" * @note The callback will be executed on the main thread",
        @" * @note The callback executes on a background thread (switch to main thread for UI updates)",
        @" * @note Callback execution thread depends on the calling parameters",
        @" * @note The callback may execute on any thread (ensure proper synchronization)",

        // Invocation Warnings
        @" * @warning The callback may be invoked multiple times (manage state accordingly)",
        @" * @warning The callback might never be invoked (implement timeout handling)",
        @" * @note The callback strongly references self (watch for retain cycles)",
        @" * @warning The callback may execute after the object has been deallocated",

        // Parameter Notes
        @" * @warning Callback parameters may be nil (always validate before use)",
        @" * @note The first parameter always indicates the operation result",
        @" * @warning The error parameter is only valid when the operation fails",
        @" * @note Response objects may be reused across callbacks",

        // Execution Guidelines
        @" * @note Avoid time-consuming operations in callbacks",
        @" * @warning Never perform synchronous network requests in callbacks",
        @" * @note Objects created in callbacks require manual cleanup",
        @" * @warning Never modify UI elements directly from callbacks",

        // Versioning & References
        @" * @see Refer to XXXProtocol for callback definitions",
        @" * @since Asynchronous callbacks added in v2.0",
        @" * @deprecated Consider using the new block-based API instead",
        @" * @note Callback execution order is not guaranteed",

        // Error Handling
        @" * @warning Exceptions thrown in callbacks won't be caught",
        @" * @note Error codes are defined in XXXError.h",
        @" * @warning Some callbacks may deliver partial success results",
        @" * @note Callbacks may be canceled due to system constraints",

        // System Conditions
        @" * @note Callbacks may be delayed in background state",
        @" * @warning Callback frequency may reduce in low-power mode",
        @" * @note Some callbacks may not work under sandbox restrictions",
        @" * @warning Certain callbacks are unavailable in extensions",

        // Debugging & Testing
        @" * @debug Callback invocations are logged",
        @" * @test This callback is mocked in unit tests",
        @" * @note Callback performance metrics are collected",
        @" * @warning Debug builds include additional callback validation",

        // Platform Availability
        @" * @compatibility Available on iOS 12+",
        @" * @iPad Behavior may differ in split-screen mode",
        @" * @macCatalyst Special handling on macOS",
        @" * @availability Some callbacks are region-locked"
    ];
}

+ (NSArray *)modifiers {
    return @[@"高效", @"安全", @"异步", @"批量", @"自动", @"手动", @"快速", @"精确",
             @"可靠", @"灵活", @"智能", @"动态", @"静态", @"临时", @"永久", @"局部",
             @"全局", @"公开", @"私有", @"内部", @"外部", @"主要", @"次要", @"基础",
             
             @"efficient", @"secure", @"asynchronous", @"batched", @"automatic", @"manual",
             @"fast", @"precise", @"reliable", @"flexible", @"smart", @"dynamic", @"static",

             @"temporary", @"permanent", @"local", @"global", @"public", @"private",
             @"internal", @"external", @"primary", @"secondary", @"basic"
    ];
}

+ (NSArray *)returnDescriptions {
    return @[
        @"操作结果", @"执行状态", @"处理输出", @"方法返回值", @"函数结果",
        @"是否成功", @"验证结果", @"检查状态", @"存在标志", @"可用状态",
        @"计数值", @"计算结果", @"统计值", @"评估分数", @"性能指标",
        @"创建的对象", @"查询结果", @"转换后的对象", @"解析内容", @"格式化输出",
        @"过滤数组", @"排序结果", @"分组字典", @"去重集合", @"映射结果",
        @"请求响应", @"下载数据", @"上传结果", @"连接状态", @"缓存内容",
        @"读取内容", @"写入状态", @"文件属性", @"目录列表", @"路径结果",
        @"渲染图像", @"缩放结果", @"滤镜效果", @"合成图像", @"编码数据",
        @"查询记录", @"插入ID", @"更新计数", @"删除结果", @"事务状态",
        @"用户信息", @"订单详情", @"支付凭证", @"物流状态", @"验证令牌",
        @"错误对象", @"异常信息", @"失败原因", @"调试详情", @"堆栈跟踪",
        @"内存用量", @"CPU负载", @"电池状态", @"网络条件", @"设备信息",
        @"单例实例", @"共享资源", @"全局状态", @"工厂对象", @"代理对象",

        @"operation result", @"execution status", @"processing output", @"method return value", @"function result",
        @"success flag", @"verification result", @"check status", @"existence flag", @"availability status",
        @"count value", @"calculation result", @"statistical value", @"evaluation score", @"performance metric",
        @"created object", @"query result", @"converted object", @"parsed content", @"formatted output",
        @"filtered array", @"sorted result", @"grouped dictionary", @"deduplicated set", @"mapped result",
        @"request response", @"downloaded data", @"upload result", @"connection status", @"cached content",
        @"read content", @"write status", @"file attributes", @"directory listing", @"path result",
        @"rendered image", @"scaled result", @"filter effect", @"composite image", @"encoded data",
        @"query record", @"inserted ID", @"update count", @"deletion result", @"transaction status",
        @"user information", @"order details", @"payment receipt", @"shipping status", @"validation token",
        @"error object", @"exception info", @"failure reason", @"debug details", @"stack trace",
        @"memory usage", @"CPU load", @"battery status", @"network condition", @"device info",
        @"singleton instance", @"shared resource", @"global state", @"factory object", @"proxy object",
        @"QuantumFlow",@"NexusSphere",@"VortexCore",@"SynapseLink",@"ChromaWave",
        @"TerraFrame",@"AeroGlide",@"NanoForge",@"FluxNode",@"MetaMesh",
        @"EchoPulse",@"VertexDrive",@"SolsticeBeam",@"OrionShell",@"CipherLock",
        @"PrismScale",@"NexusTide",@"AetherByte",@"VortexLens",@"QuantumLeap",
        @"ChromaShift",@"TerraByte",@"AeroBurst",@"NanoCell",@"FluxGate",
        @"MetaGrid",@"EchoTrace",@"VertexPort",@"SolsticeGlow",@"OrionField",
        @"CipherKey",@"PrismSpark",@"NexusBeam",@"AetherFlow",@"VortexRing",
        @"QuantumSync",@"ChromaBlend",@"TerraForm",@"AeroStream",@"NanoMesh",
        @"FluxField",@"MetaPort",@"EchoScan",@"VertexCore",@"SolsticeRay",
        @"OrionWave",@"CipherCode",@"PrismFlash",@"NexusLink",@"AetherPulse",
        @"VortexPath",@"QuantumShift",@"ChromaGlow",@"TerraCell",@"AeroFlux",
        @"NanoSync",@"FluxWave",@"MetaLens",@"EchoBeam",@"VertexSphere",
        @"SolsticeFlow",@"OrionCore",@"CipherGrid",@"PrismByte",@"NexusField",
        @"AetherRing",@"VortexSync",@"QuantumBeam",@"ChromaPulse",@"TerraGlide",
        @"AeroCell",@"NanoForge",@"FluxLink",@"MetaTide",@"EchoDrive",
        @"VertexShift",@"SolsticeSync",@"OrionMesh",@"CipherPort",@"PrismNode",
        @"NexusGlow",@"AetherPath",@"VortexLeap",@"QuantumRing",@"ChromaSync",
        @"TerraSpark",@"AeroTrace",@"NanoLens",@"FluxBeam",@"MetaPulse",
        @"EchoField",@"VertexFlow",@"SolsticePort",@"OrionShift",@"CipherTide",
        @"PrismLink",@"NexusSync",@"AetherGlide",@"VortexFrame",@"QuantumMesh",
        @"ChromaForge",@"TerraNode",@"AeroPulse",@"NanoRing",@"FluxSync",
        @"MetaBeam",@"EchoGlow",@"VertexTide",@"SolsticeLink",@"OrionSync",
        @"CipherLeap",@"PrismPath",@"NexusForge",@"AetherCell",@"VortexShift",
        @"QuantumTide",@"ChromaLink",@"TerraSync",@"AeroLeap",@"NanoPath",
        @"FluxForge",@"MetaShift",@"EchoTide",@"VertexSync",@"SolsticeForge",
        @"OrionLeap",@"CipherPath",@"PrismForge",@"NexusPath",@"AetherForge",
        @"VortexLeap",@"QuantumPath",@"ChromaForge",@"TerraLeap",@"AeroPath",
        @"NanoLeap",@"FluxPath",@"MetaLeap",@"EchoPath",@"VertexLeap",
        @"SolsticePath",@"OrionPath",@"CipherForge",@"PrismLeap",@"NexusLeap",
        @"AetherPath",@"VortexForge",@"QuantumForge",@"ChromaLeap",@"TerraForge",
        @"AeroForge",@"NanoForge",@"FluxLeap",@"MetaForge",@"EchoForge",
        @"VertexForge",@"SolsticeForge",@"OrionForge",@"CipherLeap",@"PrismForge",
        @"NexusForge",@"AetherLeap",@"VortexPath",@"QuantumLeap",@"ChromaPath",
        @"TerraPath",@"AeroLeap",@"NanoPath",@"FluxForge",@"MetaPath",
        @"EchoLeap",@"VertexPath",@"SolsticeLeap",@"OrionPath",@"CipherPath",
        @"PrismPath",@"NexusPath",@"AetherForge",@"VortexLeap",@"QuantumPath",
        @"ChromaLeap",@"TerraLeap",@"AeroPath",@"NanoLeap",@"FluxPath",
        @"MetaLeap",@"EchoPath",@"VertexLeap",@"SolsticePath",@"OrionLeap",
        @"CipherForge",@"PrismLeap",@"NexusLeap",@"AetherPath",@"VortexForge",
        @"QuantumForge",@"ChromaPath",@"TerraForge",@"AeroForge",@"NanoPath",
        @"FluxLeap",@"MetaForge",@"EchoForge",@"VertexPath",@"SolsticeForge",
        @"OrionForge",@"CipherLeap",@"PrismForge",@"NexusForge",@"AetherLeap",
        @"VortexPath",@"QuantumLeap",@"ChromaForge",@"TerraPath",@"AeroLeap",
        @"NanoForge",@"FluxPath",@"MetaPath",@"EchoLeap",@"VertexForge",
        @"SolsticeLeap",@"OrionPath",@"CipherPath",@"PrismLeap",@"NexusPath",
        @"AetherForge",@"VortexLeap",@"QuantumPath",@"ChromaLeap",@"TerraLeap",
        @"AeroPath",@"NanoLeap",@"FluxForge",@"MetaLeap",@"EchoPath",
        @"VertexLeap",@"SolsticePath",@"OrionLeap",@"CipherForge",@"PrismPath",
        @"NexusLeap",@"AetherPath",@"VortexForge",@"QuantumForge",@"ChromaPath",
        @"TerraForge",@"AeroForge",@"NanoPath",@"FluxLeap",@"MetaForge",
        @"EchoForge",@"VertexPath",@"SolsticeForge",@"OrionForge",@"CipherLeap",
        @"PrismForge",@"NexusForge",@"AetherLeap",@"VortexPath",@"QuantumLeap",
        @"ChromaForge",@"TerraPath",@"AeroLeap",@"NanoForge",@"FluxPath",
        @"MetaPath",@"EchoLeap",@"VertexForge",@"SolsticeLeap",@"OrionPath",
        @"CipherPath",@"PrismLeap",@"NexusPath",@"AetherForge",@"VortexLeap",
        @"QuantumPath",@"ChromaLeap",@"TerraLeap",@"AeroPath",@"NanoLeap",
        @"FluxForge",@"MetaLeap",@"EchoPath",@"VertexLeap",@"SolsticePath",
        @"OrionLeap",@"CipherForge",@"PrismPath",@"NexusLeap",@"AetherPath",
        @"VortexForge",@"QuantumForge",@"ChromaPath",@"TerraForge",@"AeroForge",
        @"NanoPath",@"FluxLeap",@"MetaForge",@"EchoForge",@"VertexPath",
        @"SolsticeForge",@"OrionForge",@"CipherLeap",@"PrismForge",@"NexusForge",
        @"AetherLeap",@"VortexPath",@"QuantumLeap",@"ChromaForge",@"TerraPath",
        @"AeroLeap",@"NanoForge",@"FluxPath",@"MetaPath",@"EchoLeap",
        @"VertexForge",@"SolsticeLeap",@"OrionPath",@"CipherPath",@"PrismLeap",
        @"NexusPath",@"AetherForge",@"VortexLeap",@"QuantumPath",@"ChromaLeap",
        @"TerraLeap",@"AeroPath",@"NanoLeap",@"FluxForge",@"MetaLeap",
        @"EchoPath",@"VertexLeap",@"SolsticePath",@"OrionLeap",@"CipherForge",
        @"PrismPath",@"NexusLeap",@"AetherPath",@"VortexForge",@"QuantumForge",
        @"ChromaPath",@"TerraForge",@"AeroForge",@"NanoPath",@"FluxLeap",
        @"MetaForge",@"EchoForge",@"VertexPath",@"SolsticeForge",@"OrionForge",
        @"CipherLeap",@"PrismForge",@"NexusForge",@"AetherLeap",@"VortexPath",
        @"QuantumLeap",@"ChromaForge",@"TerraPath",@"AeroLeap",@"NanoForge",
        @"FluxPath",@"MetaPath",@"EchoLeap",@"VertexForge",@"SolsticeLeap",
        @"OrionPath",@"CipherPath",@"PrismLeap",@"NexusPath",@"AetherForge",
        @"VortexLeap",@"QuantumPath",@"ChromaLeap",@"TerraLeap",@"AeroPath",
        @"NanoLeap",@"FluxForge",@"MetaLeap",@"EchoPath",@"VertexLeap",
        @"SolsticePath",@"OrionLeap",@"CipherForge",@"PrismPath",@"NexusLeap",
        @"AetherPath",@"VortexForge",@"QuantumForge",@"ChromaPath",@"TerraForge",
        @"AeroForge",@"NanoPath",@"FluxLeap",@"MetaForge",@"EchoForge",
        @"VertexPath",@"SolsticeForge",@"OrionForge",@"CipherLeap",@"PrismForge",
        @"NexusForge",@"AetherLeap",@"VortexPath",@"QuantumLeap",@"ChromaForge",
        @"TerraPath",@"AeroLeap",@"NanoForge",@"FluxPath",@"MetaPath",
        @"EchoLeap",@"VertexForge",@"SolsticeLeap",@"OrionPath",@"CipherPath",
        @"PrismLeap",@"NexusPath",@"AetherForge",@"VortexLeap",@"QuantumPath",
        @"ChromaLeap",@"TerraLeap",@"AeroPath",@"NanoLeap",@"FluxForge",
        @"MetaLeap",@"EchoPath",@"VertexLeap",@"SolsticePath",@"OrionLeap",
        @"CipherForge",@"PrismPath",@"NexusLeap",@"AetherPath",@"VortexForge",
        @"QuantumForge",@"ChromaPath",@"TerraForge",@"AeroForge",@"NanoPath",
        @"FluxLeap",@"MetaForge",@"EchoForge",@"VertexPath",@"SolsticeForge",
        @"OrionForge",@"CipherLeap",@"PrismForge",@"NexusForge",@"AetherLeap",
        @"VortexPath",@"QuantumLeap",@"ChromaForge",@"TerraPath",@"AeroLeap",
        @"NanoForge",@"FluxPath",@"MetaPath",@"EchoLeap",@"VertexForge",
        @"SolsticeLeap",@"OrionPath",@"CipherPath",@"PrismLeap",@"NexusPath",
        @"AetherForge",@"VortexLeap",@"QuantumPath",@"ChromaLeap",@"TerraLeap",
        @"AeroPath",@"NanoLeap",@"FluxForge",@"MetaLeap",@"EchoPath",
        @"VertexLeap",@"SolsticePath",@"OrionLeap",@"CipherForge",@"PrismPath",
        @"NexusLeap",@"AetherPath",@"VortexForge",@"QuantumForge",@"ChromaPath",
        @"TerraForge",@"AeroForge",@"NanoPath",@"FluxLeap",@"MetaForge",
        @"EchoForge",@"VertexPath",@"SolsticeForge",@"OrionForge",@"CipherLeap",
        @"PrismForge",@"NexusForge",@"AetherLeap",@"VortexPath",@"QuantumLeap",
        @"ChromaForge",@"TerraPath",@"AeroLeap",@"NanoForge",@"FluxPath",
        @"MetaPath",@"EchoLeap",@"VertexForge",@"SolsticeLeap",@"OrionPath",
        @"CipherPath",@"PrismLeap",@"NexusPath",@"AetherForge",@"VortexLeap",
        @"QuantumPath",@"ChromaLeap",@"TerraLeap",@"AeroPath",@"NanoLeap",
        @"FluxForge",@"MetaLeap",@"EchoPath",@"VertexLeap",@"SolsticePath",
        @"OrionLeap",@"CipherForge",@"PrismPath",@"NexusLeap",@"AetherPath",
        @"VortexForge",@"QuantumForge",@"ChromaPath",@"TerraForge",@"AeroForge",
        @"NanoPath",@"FluxLeap",@"MetaForge",@"EchoForge",@"VertexPath",
        @"SolsticeForge",@"OrionForge",@"CipherLeap",@"PrismForge",@"NexusForge",
        @"AetherLeap",@"VortexPath",@"QuantumLeap",@"ChromaForge",@"TerraPath",
        @"AeroLeap",@"NanoForge",@"FluxPath",@"MetaPath",@"EchoLeap",
        @"VertexForge",@"SolsticeLeap",@"OrionPath",@"CipherPath",@"PrismLeap",
        @"NexusPath",@"AetherForge",@"VortexLeap",@"QuantumPath",@"ChromaLeap",
        @"TerraLeap",@"AeroPath",@"NanoLeap",@"FluxForge",@"MetaLeap",
        @"EchoPath",@"VertexLeap",@"SolsticePath",@"OrionLeap",@"CipherForge",
        @"PrismPath",@"NexusLeap",@"AetherPath",@"VortexForge",@"QuantumForge",
        @"ChromaPath",@"TerraForge",@"AeroForge",@"NanoPath",@"FluxLeap",
        @"MetaForge",@"EchoForge",@"VertexPath",@"SolsticeForge",@"OrionForge",
        @"CipherLeap",@"PrismForge",@"NexusForge",@"AetherLeap",@"VortexPath",
        @"QuantumLeap",@"ChromaForge",@"TerraPath",@"AeroLeap",@"NanoForge",
        @"FluxPath",@"MetaPath",@"EchoLeap",@"VertexForge",@"SolsticeLeap",
        @"OrionPath",@"CipherPath",@"PrismLeap",@"NexusPath",@"AetherForge",
        @"VortexLeap",@"QuantumPath",@"ChromaLeap",@"TerraLeap",@"AeroPath",
        @"NanoLeap",@"FluxForge",@"MetaLeap",@"EchoPath",@"VertexLeap",
        @"SolsticePath",@"OrionLeap",@"CipherForge",@"PrismPath",@"NexusLeap",
        @"AetherPath",@"VortexForge",@"QuantumForge",@"ChromaPath",@"TerraForge",
        @"AeroForge",@"NanoPath",@"FluxLeap",@"MetaForge",@"EchoForge",
        @"VertexPath",@"SolsticeForge",@"OrionForge",@"CipherLeap",@"PrismForge",
        @"NexusForge",@"AetherLeap",@"VortexPath",@"QuantumLeap",@"ChromaForge"
    ];
}

+ (NSString *)generateCallbackNote{
    return self.callbackNotes[arc4random_uniform((uint32_t)self.callbackNotes.count)];
}

+ (NSString *)generateReturnDescription{
    return self.returnDescriptions[arc4random_uniform((uint32_t)self.returnDescriptions.count)];
}

+ (NSString *)generateMethodDescription:(NSString *)methodName {
    NSArray *verbs = [self actionVerbs];
    NSArray *nouns = [self operationNouns];
    NSArray *mods = [self modifiers];
    
    // 提取方法名第一部分
    NSString *meaningfulPart = [[methodName componentsSeparatedByString:@":"] firstObject];
    meaningfulPart = [meaningfulPart stringByReplacingOccurrencesOfString:@")" withString:@""];
    meaningfulPart = [[meaningfulPart componentsSeparatedByString:@" "] lastObject];
    
    // 随机选择组件
    NSString *verb = verbs[arc4random_uniform((uint32_t)verbs.count)];
    NSString *noun = nouns[arc4random_uniform((uint32_t)nouns.count)];
    NSString *mod = mods[arc4random_uniform((uint32_t)mods.count)];
    
    // 50%概率添加修饰词
    if (arc4random_uniform(2) == 0) {
        return [NSString stringWithFormat:@"%@%@的%@", verb, mod, noun];
    } else {
        return [NSString stringWithFormat:@"%@%@", verb, noun];
    }
}

+ (NSString *)generateParamDescriptionForParam:(NSString *)paramName {
    NSDictionary *paramTypeMap = self.paramTypeMap;
    
    // 检查是否有匹配的类型描述
    NSString *typeDescription = paramTypeMap[paramName];
    if (typeDescription) {
        return typeDescription;
    }
    
    // 检查是否是回调类型
    if ([paramName hasSuffix:@"Block"] || [paramName hasSuffix:@"Handler"] ||
        [paramName hasSuffix:@"Completion"] || [paramName hasSuffix:@"Callback"]) {
        return @"回调处理块";
    }
    
    // 默认描述
    NSArray *defaultDescriptions = @[@"参数值", @"配置选项", @"输入数据", @"控制标志"];
    return defaultDescriptions[arc4random_uniform((uint32_t)defaultDescriptions.count)];
}


+ (NSString *)generateSmartCommentForMethod:(NSString *)methodName params:(NSArray *)paramTypes {
    NSMutableString *comment = [NSMutableString stringWithString:@"/**\n * "];
    [comment appendString:[self generateMethodDescription:methodName]];
    
    BOOL hasParams = paramTypes.count > 0;
    BOOL hasBlock = NO;
    
    // 检查是否有block参数
    for (NSString *paramType in paramTypes) {
        if ([paramType containsString:@"Block"] || [paramType containsString:@"^"] ||
            [paramType containsString:@"handler"] || [paramType containsString:@"completion"]) {
            hasBlock = YES;
            break;
        }
    }
    
    if (hasParams) {
        [comment appendString:@"\n *\n"];
        
        // 添加参数说明
        for (int i = 0; i < paramTypes.count; i++) {
            NSString *paramName = [NSString stringWithFormat:@"param%d", i+1];
            if (i < [[methodName componentsSeparatedByString:@":"] count] - 1) {
                paramName = [[methodName componentsSeparatedByString:@":"][i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            }
            
            [comment appendFormat:@" * @param %@ %@\n", paramName, [self generateParamDescriptionForParam:paramTypes[i]]];
        }
        
        // 添加回调说明
        if (hasBlock) {
            NSArray *callbackNotes = self.callbackNotes;
            [comment appendString:callbackNotes[arc4random_uniform((uint32_t)callbackNotes.count)]];
            [comment appendString:@"\n"];
        }
    }
    
    // 50%概率添加返回值说明
    if (arc4random_uniform(2) == 0) {
        if (!hasParams) {
            [comment appendString:@"\n *"];
        }
        NSArray *returnDescriptions = self.returnDescriptions;
        [comment appendString:[NSString stringWithFormat:@"\n * @return %@",returnDescriptions[arc4random_uniform((uint32_t)returnDescriptions.count)]]];
    }
    
    [comment appendString:@"\n */"];
    return comment;
}



@end

