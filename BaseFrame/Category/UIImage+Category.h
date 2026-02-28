//
//  UIImage+Category.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Category)

- (UIImage *)original;

+ (UIImage *)createImageWithColor:(UIColor *)color;
+ (UIImage *)createImageWithColor:(UIColor *)color size:(CGSize)size;
+ (UIImage *)createImageWithColor:(UIColor *)color size:(CGSize)size radius:(CGFloat)radius;

//图片拉伸
- (UIImage *)stretchable;

- (UIImage *)imageByApplyingAlpha:(CGFloat)alpha;

- (UIImage *)thumbnailWithImage:(UIImage *)originalImage size:(CGSize)size;

/// 压缩成NSData
/// @param toSize 目标尺寸
/// @param scale 控制压缩速度 0～1
- (NSData *)compressImageToSize:(NSInteger)toSize scale:(CGFloat)scale;

+ (UIImage *)generateQRCodeWithData:(NSString *)data size:(CGFloat)size logoImage:(UIImage *)logoImage ratio:(CGFloat)ratio;

@end

NS_ASSUME_NONNULL_END
