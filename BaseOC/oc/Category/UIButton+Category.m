//
//  UIButton+Category.m
//  QuShou
//
//  Created by 王祥伟 on 2024/4/2.
//

#import "UIButton+Category.h"

@implementation UIButton (Category)

- (void)setTitlePosition:(TitlePositionType)type spacing:(CGFloat)spacing{
    CGSize imageSize = [self imageForState:self.state].size;
    if (imageSize.height * imageSize.width <= 0) return;
    
    NSString *title = [self titleForState:self.state];
    if (title.length <= 0) return;
    CGSize titleSize = [title sizeWithAttributes:@{NSFontAttributeName:self.titleLabel.font}];
    
    switch (type) {
        case TitlePositionLeft:
            self.titleEdgeInsets = UIEdgeInsetsMake(0, - imageSize.width, 0, imageSize.width + spacing);
            self.imageEdgeInsets = UIEdgeInsetsMake(0, titleSize.width + spacing, 0, - titleSize.width);
            break;
        case TitlePositionRight:
            self.titleEdgeInsets = UIEdgeInsetsMake(0, spacing, 0, 0);
            self.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, spacing);
            break;
        case TitlePositionTop:
            self.titleEdgeInsets = UIEdgeInsetsMake(- (imageSize.height + spacing), - imageSize.width, 0, 0);
            self.imageEdgeInsets = UIEdgeInsetsMake(0, 0, - (titleSize.height + spacing), - titleSize.width);
            break;
        case TitlePositionBottom:
            self.titleEdgeInsets = UIEdgeInsetsMake(0, - imageSize.width, - (imageSize.height + spacing), 0);
            self.imageEdgeInsets = UIEdgeInsetsMake(- (titleSize.height + spacing), 0, 0, - titleSize.width);
            break;
        default:
            break;
    }
}

//----------------------------------------------
- (void)setEnlargedEdgeInsets:(UIEdgeInsets)enlargedEdgeInsets{
    NSValue *value = [NSValue valueWithUIEdgeInsets:enlargedEdgeInsets];
    objc_setAssociatedObject(self, @selector(enlargedEdgeInsets), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)enlargedEdgeInsets{
    NSValue *value = objc_getAssociatedObject(self, @selector(enlargedEdgeInsets));
    if (value) return [value UIEdgeInsetsValue];
    return UIEdgeInsetsZero;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (UIEdgeInsetsEqualToEdgeInsets(self.enlargedEdgeInsets, UIEdgeInsetsZero)) {
        return [super pointInside:point withEvent:event];
    }

    UIEdgeInsets enlarge = UIEdgeInsetsMake(-self.enlargedEdgeInsets.top, -self.enlargedEdgeInsets.left, -self.enlargedEdgeInsets.bottom, -self.enlargedEdgeInsets.right);
    CGRect hitFrame = UIEdgeInsetsInsetRect(self.bounds, enlarge);
    return CGRectContainsPoint(hitFrame, point);
}

@end
