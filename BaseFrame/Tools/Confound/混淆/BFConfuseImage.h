//
//  BFConfuseImage.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFConfuseImage : NSObject

+ (NSArray<NSString *> *)allAssetFilenamesInProject:(NSString *)projectRoot;

//随机命名图片，不会需改项目中图片名
+ (void)renameAssetsInDirectory:(NSString *)directory;

+ (void)renameImageAssetsAndCodeReferencesInProject:(NSString *)projectDirectory
                                     renameMapping:(NSDictionary<NSString *, NSString *> *)renameMapping;



+ (NSDictionary *)mapImageDict;
+ (NSDictionary *)mapImageDict1;
+ (NSDictionary *)mapImageDict4;
+ (NSDictionary *)mapImageDict103;

@end

NS_ASSUME_NONNULL_END
