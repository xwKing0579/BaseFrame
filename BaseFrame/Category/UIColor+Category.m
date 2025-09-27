//
//  UIColor+Category.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/5.
//

#import "UIColor+Category.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation UIColor (Category)
#pragma clang diagnostic pop

+ (BOOL)resolveClassMethod:(SEL)selector{
    NSString *string = NSStringFromSelector(selector);
    RESOLVE_CLASS_METHOD([NSStringFromSelector(selector) hasPrefix:@"c"] && (string.length == 7 || string.length == 9), @selector(colorSelf))
    return [super resolveClassMethod:selector];
}

+ (UIColor *)colorSelf{
    return [self performAction:@"rgbString:" object:NSStringFromSelector(_cmd)];
}

+ (UIColor *)rgbString:(NSString *)cString{
    cString = [cString substringFromIndex:1];
    NSString *rString = [cString substringWithRange:NSMakeRange(0, 2)];
    NSString *gString = [cString substringWithRange:NSMakeRange(2, 2)];
    NSString *bString = [cString substringWithRange:NSMakeRange(4, 2)];
   
    unsigned int r, g, b, a = 0;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    if (cString.length == 8){
        NSString *aString = [cString substringWithRange:NSMakeRange(6, 2)];
        [[NSScanner scannerWithString:aString] scanHexInt:&a];
    }
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:cString.length == 6 ? 1.0 : a/255.0];
}

+ (UIColor *)RGB:(int)rgb {return [self RGB:rgb A:1.0];}
+ (UIColor *)RGB:(int)rgb A:(CGFloat)a {
    return [UIColor colorWithRed:((float)((rgb & 0xFF0000) >> 16))/255.0 green:((float)((rgb & 0xFF00) >> 8))/255.0 blue:((float)(rgb & 0xFF))/255.0 alpha:a];
}

- (NSString *)hexStringWithAlpha:(BOOL)withAlpha {
    CGColorRef color = self.CGColor;
    size_t count = CGColorGetNumberOfComponents(color);
    const CGFloat *components = CGColorGetComponents(color);
    static NSString *stringFormat = @"%02x%02x%02x";
    NSString *hex = nil;
    if (count == 2) {
        NSUInteger white = (NSUInteger)(components[0] * 255.0f);
        hex = [NSString stringWithFormat:stringFormat, white, white, white];
    }else if (count == 4) {
        hex = [NSString stringWithFormat:stringFormat,
               (NSUInteger)(components[0] * 255.0f),
               (NSUInteger)(components[1] * 255.0f),
               (NSUInteger)(components[2] * 255.0f)];
    }
    
    if (hex && withAlpha) {
        hex = [hex stringByAppendingFormat:@"%02lx",(unsigned long)(self.alpha * 255.0 + 0.5)];
    }
    return hex;
}

- (CGFloat)alpha{
    return CGColorGetAlpha(self.CGColor);
}

+ (instancetype)gradientColorWithSize:(CGSize)size
                            direction:(GradientColorDirection)direction
                           startColor:(UIColor *)startcolor
                             endColor:(UIColor *)endColor{
    if (CGSizeEqualToSize(size, CGSizeZero) || !startcolor || !endColor) {
         return nil;
     }
     
     CAGradientLayer *gradientLayer = [CAGradientLayer layer];
     gradientLayer.frame = CGRectMake(0, 0, size.width, size.height);
     
     CGPoint startPoint = CGPointMake(0.0, 0.0);
     if (direction == GradientColorDirectionUpwardDiagonalLine) {
         startPoint = CGPointMake(0.0, 1.0);
     }
     
     CGPoint endPoint = CGPointMake(0.0, 0.0);
     switch (direction) {
         case GradientColorDirectionVertical:
             endPoint = CGPointMake(0.0, 1.0);
             break;
         case GradientColorDirectionDownDiagonalLine:
             endPoint = CGPointMake(1.0, 1.0);
             break;
         case GradientColorDirectionUpwardDiagonalLine:
             endPoint = CGPointMake(1.0, 0.0);
             break;
         default:
             endPoint = CGPointMake(1.0, 0.0);
             break;
     }
     gradientLayer.startPoint = startPoint;
     gradientLayer.endPoint = endPoint;
     
     gradientLayer.colors = @[(__bridge id)startcolor.CGColor, (__bridge id)endColor.CGColor];
     UIGraphicsBeginImageContext(size);
     [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
     UIImage*image = UIGraphicsGetImageFromCurrentImageContext();
     UIGraphicsEndImageContext();
     
     return [UIColor colorWithPatternImage:image];
}

@end

