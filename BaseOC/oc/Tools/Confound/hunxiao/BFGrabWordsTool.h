//
//  BFGrabWordsTool.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/4/10.
//

#import <Foundation/Foundation.h>
#import "BFWordsRackTool.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const kDocumentPath;

@interface BFGrabWordsTool : NSObject

//获取所有方法
+ (NSArray *)scanMethodsInProjectAtPath:(NSString *)projectPath;

//获取所有单词并存起来
+ (NSArray *)scanWordsInProjectAtPath:(NSString *)projectPath;
+ (NSArray *)scanWordsInProjectAtPath:(NSString *)projectPath writeToFile:(BOOL)write;

//单词库
+ (NSArray *)getAllTxtWordsWithType:(WordsType)type;

//方法名称替换  key是原方法名 value是需要替换的方法名
+ (NSDictionary *)replaceMethodNameWithOriginMethodList:(NSArray *)methodList words:(NSArray *)words;

@end


@interface NSString (CamelCaseSplit)
- (NSArray<NSString *> *)splitCamelCaseComponents;
@end


@interface NSArray (Functional)
- (NSArray *)map:(id (^)(id obj))block;
@end
NS_ASSUME_NONNULL_END
