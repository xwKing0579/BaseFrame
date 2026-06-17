//
//  UIColor+Category.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, GradientColorDirection) {
    GradientColorDirectionLevel,//水平渐变
    GradientColorDirectionVertical,//竖直渐变
    GradientColorDirectionDownDiagonalLine,//向上对角线渐变
    GradientColorDirectionUpwardDiagonalLine,//向下对角线渐变
};

@interface UIColor (Category)

+ (UIColor *)c000000;
+ (UIColor *)c00000033;
+ (UIColor *)c00000066;
+ (UIColor *)cFFFFFF;
+ (UIColor *)cCCCCCC;
+ (UIColor *)cE1E1E1;
+ (UIColor *)c333333;
+ (UIColor *)cEEEEEE;
+ (UIColor *)cBFBFBF;


+ (UIColor *)rgbString:(NSString *)cString;
- (NSString *)hexStringWithAlpha:(BOOL)withAlpha;
+ (instancetype)gradientColorWithSize:(CGSize)size
                            direction:(GradientColorDirection)direction
                           startColor:(UIColor *)startcolor
                             endColor:(UIColor *)endColor;

@end

NS_ASSUME_NONNULL_END
