//
//  BFConfoundSetting.h
//  OCProject
//
//  Created by 王祥伟 on 2024/3/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class BFSpamCodeSetting,BFSpamCodeFileSetting,BFSpamCodeWordSetting,BFModifyProjectSetting;

@interface BFConfoundSetting : NSObject

@property (nonatomic, assign) BOOL isSpam;
@property (nonatomic, assign) BOOL isModifyProject;
@property (nonatomic, assign) BOOL isModifyClass;
@property (nonatomic, assign) BOOL isClearComment;
@property (nonatomic, assign) BOOL isMethodConfusion;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) BFSpamCodeSetting *spamSet;
@property (nonatomic, strong) BFModifyProjectSetting *modifySet;
+ (instancetype)sharedManager;
@end

@interface BFSpamCodeSetting : NSObject
@property (nonatomic, assign) BOOL isSpamInOldCode;
@property (nonatomic, assign) BOOL isSpamInNewDir;
@property (nonatomic, assign) BOOL isSpamMethod;
@property (nonatomic, assign) BOOL isSpamOldWords;
@property (nonatomic, assign) int spamMethodNum;
@property (nonatomic, copy) NSString *spamMethodPrefix;
@property (nonatomic, strong) BFSpamCodeFileSetting *spamFileSet;
@property (nonatomic, strong) NSMutableDictionary *projectWords;
@property (nonatomic, copy) NSArray *combinedWords;
@property (nonatomic, strong) BFSpamCodeWordSetting *spamWordSet;
@end

@interface BFSpamCodeFileSetting : NSObject
@property (nonatomic, copy) NSString *projectName;
@property (nonatomic, copy) NSString *dirName;
@property (nonatomic, copy) NSString *author;
@property (nonatomic, copy) NSString *spamClassPrefix;
@property (nonatomic, copy) NSString *spamhFileContent;
@property (nonatomic, copy) NSString *spammFileContent;
@property (nonatomic, copy) NSString *spamFileDesContent;
@property (nonatomic, assign) int spamFileNum;

@end

@interface BFSpamCodeWordSetting : NSObject
@property (nonatomic, assign) int minLength;
@property (nonatomic, assign) int maxLength;
@property (nonatomic, assign) int frequency;
@property (nonatomic, copy) NSArray *blackList;
@end

@interface BFModifyProjectSetting : NSObject
@property (nonatomic, assign) BOOL isModifyPrefixOther;
@property (nonatomic, copy) NSString *oldName;
@property (nonatomic, copy) NSString *modifyName;
@property (nonatomic, copy) NSString *oldPrefix;
@property (nonatomic, copy) NSString *modifyPrefix;
@end


NS_ASSUME_NONNULL_END
