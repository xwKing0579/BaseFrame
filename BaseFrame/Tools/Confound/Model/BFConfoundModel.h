//
//  BFConfoundModel.h
//  OCProject
//
//  Created by 王祥伟 on 2024/3/22.
//

#import <Foundation/Foundation.h>
#import "BFConfoundSetting.h"
NS_ASSUME_NONNULL_BEGIN

@interface BFConfoundModel : NSObject
@property (nonatomic, copy) NSString *idStr;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, assign) BOOL setting;
@property (nonatomic, assign) BOOL selecte;

+ (NSArray *)data;
+ (NSArray *)data_file;
+ (NSArray *)data_code;
+ (NSArray *)data_code_method;
+ (NSArray *)data_code_word;
+ (NSArray *)data_modify_project;
+ (NSArray *)data_modify_class;

+ (void)editContent:(id)content idStr:(NSString *)idStr;

@end

NS_ASSUME_NONNULL_END
