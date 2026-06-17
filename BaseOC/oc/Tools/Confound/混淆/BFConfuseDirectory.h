//
//  BFConfuseDirectory.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFConfuseDirectory : NSObject



//替换文件名
+ (void)processProjectAtPath:(NSString *)projectPath
               renameMapping:(NSDictionary<NSString *, NSString *> *)mapping;

//计算目录内存
+ (void)calculateAndPrintDirectorySizes:(NSString *)projectPath;


//单独替换分类

+ (NSDictionary *)dict;
+ (NSDictionary *)dict1;
+ (NSDictionary *)dict2;
+ (NSDictionary *)dict103;
@end

NS_ASSUME_NONNULL_END
