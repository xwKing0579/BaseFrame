//
//  UIImage+Assets.m
//  MoQia
//
//  Created by 王祥伟 on 2024/7/10.
//

#import "UIImage+Assets.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation UIImage (Assets)
#pragma clang diagnostic pop

+ (BOOL)resolveClassMethod:(SEL)selector{
    RESOLVE_CLASS_METHOD(YES, @selector(toGetImage))
    return [super resolveClassMethod:selector];
}

+ (UIImage *)toGetImage{
    return [UIImage imageNamed:safeString(NSStringFromSelector(_cmd))];
}

- (UIImage *)tintcolor:(UIColor *)color{
    return [self imageWithTintColor:color];
}

@end


@implementation NSString (Assets)

- (UIImage *)toImage{
    return [UIImage imageNamed:self];
}

@end
