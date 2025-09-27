//
//  UIImage+Assets.h
//  MoQia
//
//  Created by 王祥伟 on 2024/7/10.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Assets)

//common
+ (UIImage *)AppIcon;
+ (UIImage *)loading;
+ (UIImage *)back;
+ (UIImage *)close;
+ (UIImage *)empty;


- (UIImage *)tintcolor:(UIColor *)color;

@end

@interface NSString (Assets)

- (UIImage *)toImage;

@end

NS_ASSUME_NONNULL_END
