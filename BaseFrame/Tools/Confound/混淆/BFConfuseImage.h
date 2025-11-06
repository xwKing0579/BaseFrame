//
//  BFConfuseImage.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFConfuseImage : NSObject

//找出所有图片打印名称
+ (NSArray<NSString *> *)allAssetFilenamesInProject:(NSString *)projectRoot;

/// 同步检测未使用的图片资源
/// @param projectPath 项目路径
/// @param excludeDirs 要排除的目录
+ (NSArray<NSString *> *)findUnusedImagesInProject:(NSString *)projectPath
                                       excludeDirs:(NSArray<NSString *> *)excludeDirs
                                      shouldDelete:(BOOL)shouldDelete;

//随机命名图片，不会需改项目中图片名
+ (void)renameAssetsInDirectory:(NSString *)directory;

+ (void)renameImageAssetsAndCodeReferencesInProject:(NSString *)projectDirectory
                                     renameMapping:(NSDictionary<NSString *, NSString *> *)renameMapping;

// 替换两个目录中的同名图片
+ (void)replaceImagesFromDirectoryA:(NSString *)dirAPath toDirectoryB:(NSString *)dirBPath;

//移除@1x
+ (void)removeAt1xSuffixFromImagesInDirectory:(NSString *)directoryPath;

+ (NSDictionary *)mapImageDict;
+ (NSDictionary *)mapImageDict1;
+ (NSDictionary *)mapImageDict4;
+ (NSDictionary *)mapImageDict103;
+ (NSDictionary *)mapImageDict200;
@end

NS_ASSUME_NONNULL_END
