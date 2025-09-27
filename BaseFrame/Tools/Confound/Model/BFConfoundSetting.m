//
//  BFConfoundSetting.m
//  OCProject
//
//  Created by 王祥伟 on 2024/3/25.
//

#import "BFConfoundSetting.h"

@implementation BFConfoundSetting

+ (instancetype)sharedManager {
    static BFConfoundSetting *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [self new];
        manager.isSpam = NO;
        manager.isModifyProject = NO;
        manager.isModifyClass = NO;
        manager.isClearComment = NO;
        manager.isMethodConfusion = YES;
        
        BFSpamCodeSetting *spamSet = [BFSpamCodeSetting new];
        manager.spamSet = spamSet;
        spamSet.isSpamInNewDir = YES;
        spamSet.isSpamInOldCode = NO;
        spamSet.isSpamMethod = YES;
        spamSet.isSpamOldWords = YES;
        spamSet.projectWords = [NSMutableDictionary dictionary];
        
        BFSpamCodeFileSetting *spamFileSet = [BFSpamCodeFileSetting new];
        spamSet.spamFileSet = spamFileSet;
        spamFileSet.spamFileNum = 100;
        
        BFSpamCodeWordSetting *spamWordSet = [BFSpamCodeWordSetting new];
        spamSet.spamWordSet = spamWordSet;
        spamWordSet.minLength = 3;
        spamWordSet.maxLength = 10;
        spamWordSet.frequency = 10;
        
        BFModifyProjectSetting *modifySet = [BFModifyProjectSetting new];
        manager.modifySet = modifySet;
    });
    return manager;
}

@end


@implementation BFSpamCodeSetting

- (NSString *)spamMethodPrefix{
    return self.isSpamMethod ? safeString(_spamMethodPrefix) : @"";
}

- (NSArray *)combinedWords{
    NSArray *words = self.projectWords.allKeys;
    BFSpamCodeWordSetting *set = self.spamWordSet;
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *word in words) {
        if (word.length < set.minLength) continue;
        if (word.length > set.maxLength) continue;
        if ([set.blackList containsObject:word.lowercaseString]) continue;
        if ([self.projectWords[word] intValue] < set.frequency) continue;
        [result addObject:word];
    }
    
    NSArray *addArr = @[@"description",@"detail",@"memory",@"directory",@"observer",@"storage",@"response",@"target",@"exception",@"authentication",@"authorization",@"refresh",@"reload",@"application",@"mark",@"matches",@"manager",@"object",@"plugin",@"source",@"time",@"item",@"selected",@"except",@"param",@"name",@"path",@"token",@"navigation",@"configure",@"file",@"count",@"goods",@"replace"];
    while (result.count < addArr.count) {
        NSString *string = addArr[arc4random()%addArr.count];
        if (![result containsObject:string]) [result addObject:string];
    }
    return result;
}

@end

@implementation BFSpamCodeFileSetting

- (NSString *)projectName{
    return _projectName ?: @"ProjectName";
}

- (NSString *)dirName{
    return _dirName ?: @"SpamCode";
}

- (NSString *)author{
    return _author ?: @"author";
}

- (NSString *)spamClassPrefix{
    return _spamClassPrefix ?: BFString.prefix_app;
}

- (NSString *)spamhFileContent{
    return [NSString stringWithFormat:@"//\n//  file.h\n//  %@\n//\n//  Created by %@ on date.\n//\n\n#import <UIKit/UIKit.h>\n\nNS_ASSUME_NONNULL_BEGIN\n\n@interface file : UIView\n\n@end\n\nNS_ASSUME_NONNULL_END\n",self.projectName,self.author];
}

- (NSString *)spammFileContent{
    return [NSString stringWithFormat:@"//\n//  file.m\n//  %@\n//\n//  Created by %@ on date.\n//\n\n#import \"file.h\"\n\n@implementation file\n\n@end",self.projectName,self.author];
}

- (NSString *)spamFileDesContent{
    return [NSString stringWithFormat:@"//\n//  file.m\n//  %@\n//\n//  Created by %@ on date.\n//\n\n#import <Foundation/Foundation.h>\n\n",self.projectName,self.author];
}

@end

@implementation BFSpamCodeWordSetting

- (NSArray *)blackList{
    return _blackList ?: @[@"void",@"init",@"else",@"if",@"interface",@"implementation",@"date",@"data",@"dataPicker",@"const",@"assign",@"retain",@"copy",@"weak",@"strong",@"readwrite",@"readonly",@"nonatomic",@"atomic",@"static",@"extern",@"int",@"float",@"double",@"mark",@"switch",@"for",@"integer",@"string",@"static",@"cgrect",@"rect",@"array",@"image",@"label",@"integer",@"created",@"height",@"view",@"index",@"all",@"and",@"basic",@"copy",@"right",@"the",@"float",@"error",@"data",@"const",@"lazy",@"date",@"result",@"button",@"rights",@"value",@"width",@"bool",@"methods",@"update",@"long",@"return"];
}

@end


@implementation BFModifyProjectSetting

@end
