//
//  BFSpamMethod.m
//  OCProject
//
//  Created by 王祥伟 on 2024/3/21.
//

#import "BFSpamMethod.h"
#import "BFConfoundSetting.h"
@implementation BFSpamMethod

+ (void)spamCodeProjectPath:(NSString *)projectPath{
    return [self spamCodeProjectPath:projectPath ignoreDirNames:nil];
}

+ (void)spamCodeProjectPath:(NSString *)projectPath ignoreDirNames:(NSArray<NSString *> * __nullable)ignoreDirNames{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:projectPath error:nil];
    for (NSString *filePath in files) {
        if ([ignoreDirNames containsObject:filePath]) continue;
        NSString *path = [projectPath stringByAppendingPathComponent:filePath];
        
        BOOL isDirectory;
        if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
            [self spamCodeProjectPath:path ignoreDirNames:ignoreDirNames];
            continue;
        }
        
        NSString *fileName = filePath.lastPathComponent;
        if ([fileName hasSuffix:@".h"]) {
            if ([fileName containsString:@"+"]) continue;
            NSString *headName = fileName.stringByDeletingPathExtension;
            if ([headName isEqualToString:NSStringFromClass([self class])]) continue;
            NSString *mFileName = [headName stringByAppendingPathExtension:@"m"];
            if (![files containsObject:mFileName]) continue;
            
            NSString *mfile = [path stringByReplacingOccurrencesOfString:@".h" withString:@".m"];
            NSError *error = nil;
            NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
            [fileContent stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSArray *mehods = [fileContent regexPattern:@"@(void)\\s+([^:\\r\\n]+);"];
            int count = (int)(MIN(30, mehods.count) + arc4random()%5 + 6);
            NSArray *customMethods = [self randomMethodName:mfile count:count];
            [self createSpamMethods:customMethods toFilePath:[path stringByReplacingOccurrencesOfString:@".h" withString:@""]];
        }
    }
}

+ (void)createSpamMethods:(NSArray *)methods toFilePath:(NSString *)filePath{
    NSError *error = nil;
    NSString *hfilePath = [NSString stringWithFormat:@"%@.h",filePath];
    NSString *mfilePath = [NSString stringWithFormat:@"%@.m",filePath];
    NSMutableString *hfileContent = [NSMutableString stringWithContentsOfFile:hfilePath encoding:NSUTF8StringEncoding error:&error];
    NSMutableString *mfileContent = [NSMutableString stringWithContentsOfFile:mfilePath encoding:NSUTF8StringEncoding error:&error];
    if (error) return;
    NSArray *hcomponent = [hfileContent componentsSeparatedByString:@"@end"];
    NSArray *mcomponent = [mfileContent componentsSeparatedByString:@"@end"];
    if (hcomponent.count < 2 || mcomponent.count < 2) return;
    
    NSMutableString *hmethodContent = [NSMutableString string];
    NSMutableString *mmethodContent = [NSMutableString string];
    NSInteger index = 0;
    NSArray *randwords = [self randomWords];
    for (int i = 0; i < methods.count; i++) {
        NSString *string = methods[i];
        
        //备注 开始 ----
        int arc = arc4random()%3+1;
        if (arc > 2){
            [hmethodContent appendString:@"//"];
            while (arc > 0) {
                [hmethodContent appendString:randwords[index]];
                [hmethodContent appendString:@" "];
                index++;
                arc--;
            }
            [hmethodContent appendString:@"\n"];
        }
        //备注 结束 ----
        [hmethodContent appendString:string];
        [hmethodContent appendString:@";\n\n"];
        
        
        [mmethodContent appendString:string];
        if (i == methods.count - 1){
            [mmethodContent appendString:self.randomInstanceMethodString];
        }else{
            NSString *methodString = methods[i+1];
            NSString *separat = @" (NSString *)";
            NSString *com1 = [string componentsSeparatedByString:separat].firstObject;
            NSString *com2 = [methodString componentsSeparatedByString:separat].firstObject;

            if ([com1 isEqualToString:com2]){
                NSRange range = [methodString rangeOfString:separat];
                NSString *result = [methodString substringWithRange:NSMakeRange(range.location+range.length, methodString.length-range.location-range.length)];
                
                NSString *randomStr = randomStringWithLength(arc4random()%66+6);
                
                
                int random = arc4random()%10;
                NSString *aiTe = @"%@";
                NSString *randomChar = randomStringWithLength(3);
                switch (random) {
                    case 0:
                        [mmethodContent appendString:[NSString stringWithFormat:@"{\n    return [[self %@] stringByAppendingString:@\"%@\"];\n}\n\n",result,randomStr]];
                        break;
                    case 1:
                        [mmethodContent appendString:[NSString stringWithFormat:@"{\n    return [[self %@] stringByAppendingFormat:@\"%@\", NSStringFromClass(self.class)];\n}\n\n",result,aiTe]];
                        break;
                    case 2:
                        [mmethodContent appendString:[NSString stringWithFormat:@"{\n    return [[self %@] componentsSeparatedByString:@\"%@\"].firstObject;\n}\n\n",result,randomChar]];
                        break;
                    case 3:
                        [mmethodContent appendString:[NSString stringWithFormat:@"{\n    return [[self %@] stringByReplacingOccurrencesOfString:@\"%@\" withString:@\"\"];\n}\n\n",result,randomChar]];
                        break;
                    case 4:
                        [mmethodContent appendString:[NSString stringWithFormat:@"{\n    return [[self %@] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];\n}\n\n",result]];
                        break;
                    case 5:
                        [mmethodContent appendString:[NSString stringWithFormat:@"{\n    return [self %@];\n}\n\n",result]];
                        break;
                    case 6:
                        [mmethodContent appendString:[NSString stringWithFormat:@"{\n    return self.%@;\n}\n\n",result]];
                        break;
                    default:
                    {
                        NSString *uuidString = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
                        [uuidString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%u",arc4random()%10] withString:@""];
                        [mmethodContent appendString:[NSString stringWithFormat:@"{\n    return @\"%@\";\n}\n\n",[uuidString lowercaseString]]];
                    }
                        break;
                }
                
            }else{
                [mmethodContent appendString:self.randomInstanceMethodString];
            }
        }
    }
    NSMutableString *hContent = [NSMutableString string];
    NSMutableString *mContent = [NSMutableString string];
    for (int i = 0; i < hcomponent.count-1; i++) {
        NSString *hString = [hcomponent[i] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        NSString *noSpace = [hString stringByReplacingOccurrencesOfString:@" " withString:@""];
        if ([hString containsString:@"@interface"] && ![noSpace containsString:@"//@interface"]){
            [hContent appendString:hString];
            [hContent appendString:@"\n\n"];
            [hContent appendString:hmethodContent];
        }else{
            [hContent appendString:hString];
            [hContent appendString:@"\n\n"];
        }
        [hContent appendString:@"@end\n\n"];
    }
    
    for (int i = 0; i < mcomponent.count-1; i++) {
        NSString *mString = [mcomponent[i] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        NSString *noSpace = [mString stringByReplacingOccurrencesOfString:@" " withString:@""];
        if ([mString containsString:@"@implementation"] && ![noSpace containsString:@"//@implementation"]){
            [mContent appendString:mString];
            [mContent appendString:@"\n\n"];
            [mContent appendString:mmethodContent];
        }else{
            [mContent appendString:mString];
            [mContent appendString:@"\n\n"];
        }
        [mContent appendString:@"@end\n\n"];
    }
    
    [hContent appendString:[hcomponent.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
    [mContent appendString:[mcomponent.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
    
    [hContent writeToFile:hfilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [mContent writeToFile:mfilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

+ (NSString *)randomInstanceMethodString{
    int random = arc4random()%666;
    NSString *randomString;
    switch (random) {
        case 0:
            randomString = @"return NSStringFromSelector(_cmd)";
            break;
        case 1:
            randomString = @"return [NSString stringWithFormat:@\"%@\", self.class]";
            break;
        case 2:
            randomString = @"return [NSString stringWithFormat:@\"%@\", self]";
            break;
        case 3:
            randomString = @"return [NSString stringWithFormat:@\"%@:%@\", self.class, self]";
            break;
        case 4:
        {
            randomString = @"NSString *AAAAA = NSStringFromSelector(_cmd);\n    NSCharacterSet *BBBBB = [NSCharacterSet URLQueryAllowedCharacterSet];\n    return [AAAAA stringByAddingPercentEncodingWithAllowedCharacters:BBBBB]";
            
            NSArray *randwords = [self randomWords];
            NSString *word1 = randwords[arc4random()%randwords.count]?:@"stringName";
            NSString *word2 = randwords[arc4random()%randwords.count]?:@"charaSet";
            if ([word1 isEqualToString:word2]){
                word2 = [NSString stringWithFormat:@"%@2",word2];
            }
            randomString = [randomString stringByReplacingOccurrencesOfString:@"AAAAA" withString:word1];
            randomString = [randomString stringByReplacingOccurrencesOfString:@"BBBBB" withString:word2];
        }
            break;
        case 5:
            randomString = @"return NSStringFromClass(self.class)";
            break;
        case 6:
        {
            randomString = @"NSDateFormatter *formater = [[NSDateFormatter alloc] init];\n    NSDate *date = [NSDate date];\n    [formater setDateFormat:@\"yyyy-MM-dd\"];\n    return [formater stringFromDate:date];\n";
            NSArray *randwords = [self randomWords];
            NSString *word1 = randwords[arc4random()%randwords.count];
            if (![word1 isEqualToString:@"formater"]){
                [randomString stringByReplacingOccurrencesOfString:@"formater" withString:word1];
            }
        }
            break;
        case 7:
        {
            randomString = @"NSCalendar *calendar = [NSCalendar currentCalendar];\n    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:[NSDate date]];\n    dateComponents.day = 1;\n    dateComponents.month += 2;\n    NSDate *endDayOfNextMonth = [calendar dateFromComponents:dateComponents];\n    endDayOfNextMonth = [endDayOfNextMonth dateByAddingTimeInterval:-1];\n    NSDateFormatter *formater = [[NSDateFormatter alloc] init];\n    [formater setDateFormat:@\"yyyy-MM-dd\"];\n    return [formater stringFromDate:endDayOfNextMonth]";
            NSArray *randwords = [self randomWords];
            NSString *word1 = randwords[arc4random()%randwords.count];
            if (![word1 isEqualToString:@"endDayOfNextMonth"]){
                [randomString stringByReplacingOccurrencesOfString:@"endDayOfNextMonth" withString:word1];
            }
        }
            break;
        case 8:
        {
            randomString = @"NSMutableString *pinyin = [NSMutableString stringWithString:[NSString stringWithFormat:@\"%@\",self]];\n    CFStringTransform((__bridge CFMutableStringRef)(pinyin), NULL, kCFStringTransformMandarinLatin, NO);\n    return pinyin";
            NSArray *randwords = [self randomWords];
            NSString *word1 = randwords[arc4random()%randwords.count];
            if (![word1 isEqualToString:@"pinyin"]){
                [randomString stringByReplacingOccurrencesOfString:@"pinyin" withString:word1];
            }
        }
            break;
        case 9:
        {
            randomString = @"return  [[NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970]*1000] stringValue]";
        }
            break;
        case 10:
        {
            randomString = @"return  [[NSUUID UUID] UUIDString]";
        }
            break;
        case 11:
        {
            randomString = @"return  [[[NSString stringWithFormat:@\"%@\",self] dataUsingEncoding:NSUTF8StringEncoding] description]";
        }
            break;
        case 12:
        {
            randomString = @"return [[NSString stringWithFormat:@\"%@\",self] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]";
        }
            break;
        case 13:
        {
            randomString = @"return [[[NSString stringWithFormat:@\"%@\",self] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]";
        }
        case 14:
        {
            randomString = @"return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:[NSString stringWithFormat:@\"%@\",self] options:0 error:NULL] encoding:NSUTF8StringEncoding]";
        }
            break;
        case 15:
        {
            randomString = @"return NSHomeDirectory()";
        }
            break;
        case 16:
        {
            randomString = @"return NSTemporaryDirectory()";
        }
            break;
        case 17:
        {
            randomString = @"return  NSBundle.mainBundle.bundleIdentifier";
        }
            break;
        case 18:
        {
            randomString = @"NSString *result = [NSString stringWithFormat:@\"%@\",self];\n    return [NSPropertyListSerialization propertyListWithData:[result dataUsingEncoding:NSUTF8StringEncoding] options:NSPropertyListMutableContainersAndLeaves format:NULL error:NULL]";
            NSArray *randwords = [self randomWords];
            NSString *word1 = randwords[arc4random()%randwords.count];
            if (![word1 isEqualToString:@"result"]){
                [randomString stringByReplacingOccurrencesOfString:@"result" withString:word1];
            }
        }
            break;
        case 19:
        {
            randomString = @"return [NSString stringWithFormat:@\"%.2lf\",UIScreen.mainScreen.bounds.size.width]";
        }
            break;
        case 20:
        {
            randomString = @"return [NSString stringWithFormat:@\"%.2lf\",UIScreen.mainScreen.bounds.size.height]";
        }
            break;
        case 21:
        {
            randomString = @"return [NSString stringWithFormat:@\"%.2lf\",UIScreen.mainScreen.scale]";
        }
            break;
        case 22:
        {
            randomString = @"return [NSString stringWithFormat:@\"%.2lf\",UIScreen.mainScreen.bounds.size.width*UIScreen.mainScreen.scale]";
        }
            break;
        case 23:
        {
            randomString = @"return [NSString stringWithFormat:@\"%.2lf\",UIScreen.mainScreen.bounds.size.height*UIScreen.mainScreen.scale]";
        }
            break;
        case 24:
        {
            randomString = @"return [NSString stringWithFormat:@\"%.2lf\",UIScreen.mainScreen.bounds.size.width*UIScreen.mainScreen.bounds.size.height]";
        }
            break;
        case 25:
        {
            randomString = @"return [NSString stringWithFormat:@\"%@\",NSFileManager.defaultManager.currentDirectoryPath]";
        }
            break;
        case 26:
        {
            randomString = @"return [NSString stringWithFormat:@\"%@\",NSFileManager.defaultManager.temporaryDirectory.absoluteString]";
        }
            break;

        default: //随机字符
        {
            
            NSString *uuidString = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
            [uuidString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%u",arc4random()%10] withString:@""];
            randomString = [NSString stringWithFormat:@"return @\"%@\"",[uuidString lowercaseString]];
        }
            break;
    }
    return [NSString stringWithFormat:@"{\n    %@;\n}\n\n",randomString];
}

+ (NSArray *)randomMethodName:(NSString *)path count:(int)count{
    NSArray *wordsValue = [self randomWords];
    
    NSSet *result = [self combinedWords:wordsValue minLen:2 maxLen:5 count:count];
    NSMutableArray *mehods = [NSMutableArray array];
    for (NSString *string in result.allObjects) {
        int random = arc4random()%10;
        NSString *methodString;
        switch (random) {
//            case 0:
//                methodString = [NSString stringWithFormat:@"%@ (BOOL)%@%@",self.randomMethodType,self.methodPrefix,string];
//                break;
//                
            default:
                methodString = [NSString stringWithFormat:@"%@ (NSString *)%@%@",self.randomMethodType,self.methodPrefix,string];
                break;
        }
       
        [mehods addObject:methodString];
    }
    return mehods;
}

+ (NSSet *)combinedWords:(NSArray *)words minLen:(int)minLen maxLen:(int)maxLen count:(int)count{
    NSMutableSet *indexs = [NSMutableSet set];
    NSMutableSet *result = [NSMutableSet set];
    while (result.count < count) {
        int lenth = arc4random()%abs(maxLen - minLen) + minLen;
        while (indexs.count < lenth) {
            [indexs addObject:[NSNumber numberWithInt:arc4random()%words.count]];
        }
        NSString *methodString = @"";
        for (int i = 0; i < indexs.count;i++) {
            int index = [indexs.allObjects[i] intValue];
            NSString *wordString = words[index];
            if (i != 0) wordString = [wordString capitalizedString];
            methodString = [methodString stringByAppendingString:wordString];
        }
        [result addObject:methodString];
        [indexs removeAllObjects];
    }
    return result;
}

+ (NSString *)randomMethodType{
    return  arc4random() % 2 == 1 ? @"-" : @"+";
}

+ (NSString *)methodPrefix{
    NSString *methodPrefix = BFConfoundSetting.sharedManager.spamSet.spamMethodPrefix;
    return methodPrefix ?: @"";
}

//随机单词集合
+ (NSArray *)randomWords{
    return BFConfoundSetting.sharedManager.spamSet.combinedWords;
}

+ (void)getWordsProjectPath:(NSString *)projectPath ignoreDirNames:(NSArray<NSString *> * __nullable)ignoreDirNames{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:projectPath error:nil];
    NSMutableDictionary *wordCounts = BFConfoundSetting.sharedManager.spamSet.projectWords;
    for (NSString *filePath in files) {
        if ([ignoreDirNames containsObject:filePath]) continue;
        NSString *path = [projectPath stringByAppendingPathComponent:filePath];
        
        BOOL isDirectory;
        if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
            [self getWordsProjectPath:path ignoreDirNames:ignoreDirNames];
            continue;
        }
        
        NSString *fileName = filePath.lastPathComponent;
        if ([fileName hasSuffix:@".m"]) {
            NSError *error = nil;
            NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
            NSArray *words = [fileContent filterString];
            for (NSString *word in words) {
                if (word.length > 0) {
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^[A-Za-z]+$"];
                    if ([predicate evaluateWithObject:word] && ![word.lowercaseString containsString:@"date"]){
                        NSString *key = [word lowercaseString];
                        if ([key hasPrefix:@"ui"]) key = [key stringByReplacingOccurrencesOfString:@"ui" withString:@""];
                        if ([key hasPrefix:@"ns"]) key = [key stringByReplacingOccurrencesOfString:@"ns" withString:@""];
                        if (key.length == 0) continue;
                        NSNumber *count = wordCounts[key];
                        if (count) {
                            wordCounts[key] = @(count.intValue + 1);
                        }else{
                            wordCounts[key] = @1;
                        }
                    }
                }
            }
        }
    }
}


NSString *randomStringWithLength(int length) {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ#%$&*?"; // 可用的字符
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length]; // 创建可变字符串
    for (int i = 0; i < length; i++) {
        uint32_t randomIndex = arc4random_uniform((uint32_t)[letters length]); // 生成随机索引
        unichar randomChar = [letters characterAtIndex:randomIndex]; // 获取对应字符
        [randomString appendFormat:@"%C", randomChar]; // 添加到字符串中
    }

    return randomString; // 返回生成的随机字符串
}
@end
