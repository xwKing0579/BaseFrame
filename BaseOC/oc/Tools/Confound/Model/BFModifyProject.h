//
//  BFModifyProject.h
//  OCProject
//
//  Created by 王祥伟 on 2024/3/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFModifyProject : NSObject


///修改项目名
+ (void)modifyProjectName:(NSString *)projectPath oldName:(NSString *)oldName newName:(NSString *)newName;

///修改文件前缀
+ (void)modifyFilePrefix:(NSString *)projectPath oldPrefix:(NSString *)oldPrefix newPrefix:(NSString *)newPrefix;
+ (void)modifyFilePrefix:(NSString *)projectPath otherPrefix:(BOOL)otherPrefix oldPrefix:(NSString *)oldPrefix newPrefix:(NSString *)newPrefix;

///删除注释
+ (void)clearCodeComment:(NSString *)projectPath ignoreDirNames:(NSArray<NSString *> * __nullable)ignoreDirNames;

//搜索关键字
+ (void)searchProjectName:(NSString *)projectPath keyWord:(NSString *)keyWord;


+ (void)modify2FilePrefix:(NSString *)projectPath newPrefix:(NSString *)newPrefix;
//图片
+ (void)copyImagesInDirectory:(NSString *)directory toDirectory:(NSString *)todirectory;

//文件大小
+ (void)searchBigFileInDirectory:(NSString *)directory minSize:(NSString *)size;

//文件读写
+ (void)fileToReadWrite;
@end

@interface ChineseStringsCollector : NSObject
  
@property (nonatomic, strong) NSMutableSet<NSString *> *chineseStrings;
  
- (void)collectChineseStringsFromFile:(NSString *)filePath;
+ (void)traverseDirectoryAndCollectChineseStrings:(NSString *)directory;

+ (void)fanyizhongwen:(NSString *)directory fromFile:(NSString *)filePath;
@end

NS_ASSUME_NONNULL_END
