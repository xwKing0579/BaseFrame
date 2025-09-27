//
//  NSObject+Category.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/12.
//

#import "NSObject+Category.h"

@implementation NSObject (Category)

+ (void)swizzleClassMethod:(SEL)originSelector withSwizzleMethod:(SEL)swizzleSelector{
    swizzleClassMethod(self.class, originSelector, swizzleSelector);
}

- (void)swizzleInstanceMethod:(SEL)originSelector withSwizzleMethod:(SEL)swizzleSelector{
    swizzleInstanceMethod(self.class, originSelector, swizzleSelector);
}

static void swizzleClassMethod(Class cls, SEL originSelector, SEL swizzleSelector){
    if (!class_isMetaClass(object_getClass(cls))) {
        return;
    }
    
    Method originalMethod = class_getClassMethod(cls, originSelector);
    Method swizzledMethod = class_getClassMethod(cls, swizzleSelector);
    
    Class metacls = objc_getMetaClass(NSStringFromClass(cls).UTF8String);
    if (class_addMethod(metacls,
                        originSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod))) {
        /* swizzing super class method, added if not exist */
        class_replaceMethod(metacls,
                            swizzleSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    }else{
        /* swizzleMethod maybe belong to super */
        class_replaceMethod(metacls,
                            swizzleSelector,
                            class_replaceMethod(metacls,
                                                originSelector,
                                                method_getImplementation(swizzledMethod),
                                                method_getTypeEncoding(swizzledMethod)),
                            method_getTypeEncoding(originalMethod));
    }
}

static void swizzleInstanceMethod(Class cls, SEL originSelector, SEL swizzleSelector){
    if (!class_isMetaClass(object_getClass(cls))) {
        return;
    }
    
    /* if current class not exist selector, then get super*/
    Method originalMethod = class_getInstanceMethod(cls, originSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzleSelector);
    
    /* add selector if not exist, implement append with method */
    if (class_addMethod(cls,
                        originSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod))) {
        /* replace class instance method, added if selector not exist */
        /* for class cluster , it always add new selector here */
        class_replaceMethod(cls,
                            swizzleSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    }else {
        /* swizzleMethod maybe belong to super */
        class_replaceMethod(cls,
                            swizzleSelector,
                            class_replaceMethod(cls,
                                                originSelector,
                                                method_getImplementation(swizzledMethod),
                                                method_getTypeEncoding(swizzledMethod)),
                            method_getTypeEncoding(originalMethod));
    }
}

- (NSArray <NSDictionary *>*)propertyList{
    NSMutableArray *propertyArray = [NSMutableArray array];
    if ([self isKindOfClass:[NSString class]] ||
        [self isKindOfClass:[NSDate class]] ||
        [self isKindOfClass:[NSData class]]){
        return @[@{@"description":self.description}];
    }
    NSMutableArray *keys = [NSMutableArray array];
    unsigned int outCount = 0;
    objc_property_t *properties = class_copyPropertyList(self.class, &outCount);
    for (int i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        NSString *key = [NSString stringWithUTF8String:property_getName(property)];
        if ([keys containsObject:key]) continue;
        id value = [self performAction:key];
        if (value) {
            [keys addObject:key];
            [propertyArray addObject:@{key:value}];
        }
    }
    free(properties);
    return propertyArray;
}

- (NSArray <NSDictionary *>*)customPropertyList:(NSArray <NSString *>*)properties{
    NSMutableArray *propertyArray = [NSMutableArray array];
    for (NSString *key in properties) {
        id value = [self performAction:key];
        ///特殊处理非对象类型数据
        if ([key isEqualToString:@"borderColor"]){
            value = [UIColor colorWithCGColor:(__bridge CGColorRef _Nonnull)([self valueForKey:key])];
        }
        if (!value) continue;
        if ([value isKindOfClass:[UIColor class]]) {
            UIColor *color = (UIColor *)value;
            [propertyArray addObject:@{key:[color hexStringWithAlpha:YES]}];
        }else{
            [propertyArray addObject:@{key:value}];
        }
    }
    return propertyArray;
}

- (NSDictionary *)parseModuleMappingJSON:(NSString *)resource{
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:resource ofType:@"json"];
    
    if (!filePath) {
        NSLog(@"JSON 文件未找到");
        return nil;
    }
    
    NSError *error = nil;
    NSData *jsonData = [NSData dataWithContentsOfFile:filePath options:0 error:&error];
    
    if (error) {
        NSLog(@"读取文件错误: %@", error.localizedDescription);
        return nil;
    }
    
    // 先检查重复 key
    [self checkDuplicateKeysLineByLine:jsonData];
    
    NSDictionary *moduleMapping = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                  options:kNilOptions
                                                                    error:&error];
    
    if (error) {
        NSLog(@"解析 JSON 错误: %@", error.localizedDescription);
        return nil;
    }
    
    if (![moduleMapping isKindOfClass:[NSDictionary class]]) {
        NSLog(@"JSON 格式不正确，应为字典类型");
        return nil;
    }
    
    return moduleMapping;
}

// 另一种方法：逐行检查
- (void)checkDuplicateKeysLineByLine:(NSData *)jsonData {
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if (!jsonString) {
        return;
    }
    
    NSArray<NSString *> *lines = [jsonString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableSet<NSString *> *seenKeys = [NSMutableSet set];
    BOOL foundDuplicates = NO;
    
    NSError *regexError = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\"([^\"]+)\"\\s*:"
                                                                           options:0
                                                                             error:&regexError];
    
    for (NSUInteger lineNumber = 0; lineNumber < lines.count; lineNumber++) {
        NSString *line = lines[lineNumber];
        NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:line
                                                                  options:0
                                                                    range:NSMakeRange(0, line.length)];
        
        for (NSTextCheckingResult *match in matches) {
            if (match.numberOfRanges >= 2) {
                NSRange keyRange = [match rangeAtIndex:1];
                NSString *key = [line substringWithRange:keyRange];
                
                if ([seenKeys containsObject:key]) {
                    foundDuplicates = YES;
                    NSLog(@"⚠️ 重复 key: '%@' (第%ld行)", key, lineNumber + 1);
                } else {
                    [seenKeys addObject:key];
                }
            }
        }
    }
}

- (NSSet *)parseModuleArrayJSON:(NSString *)resource{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:resource ofType:@"json"];
    
    if (!filePath) {
        NSLog(@"JSON 文件未找到");
        return nil;
    }
    
    // 2. 读取 JSON 数据
    NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    
    // 3. 解析 JSON 数据为数组
    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
    
    if (error) {
        NSLog(@"JSON 解析错误: %@", error.localizedDescription);
        return nil;
    }
    
    if (![jsonArray isKindOfClass:[NSArray class]]) {
        NSLog(@"JSON 数据不是数组格式");
        return nil;
    }
    
    // 4. 将数组转换为 NSSet
    NSSet *resultSet = [NSSet setWithArray:jsonArray];
    return resultSet;
}

@end
