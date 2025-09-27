//
//  BFWordsRackTool.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/4/10.
//

#import <Foundation/Foundation.h>



typedef NS_ENUM(NSInteger, WordsType) {
    AllType,
    ReadingWordsType,
    ReadingMethodsType,
};

NS_ASSUME_NONNULL_BEGIN

@interface BFWordsRackTool : NSObject


+ (NSArray *)getWordsWithType:(WordsType)type;

+ (NSArray *)expectList;
+ (NSDictionary *)wordWhiteList;

+ (NSArray *)readingWords;
//1000个常用属性名
+ (NSArray<NSString *> *)propertyNames;
@end

NS_ASSUME_NONNULL_END
