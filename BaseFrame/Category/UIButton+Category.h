//
//  UIButton+Category.h
//  QuShou
//
//  Created by 王祥伟 on 2024/4/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TitlePositionType) {
    TitlePositionLeft,
    TitlePositionRight,
    TitlePositionTop,
    TitlePositionBottom
};

@interface UIButton (Category)

@property (nonatomic,assign) UIEdgeInsets enlargedEdgeInsets;

- (void)setTitlePosition:(TitlePositionType)type spacing:(CGFloat)spacing;

@end

NS_ASSUME_NONNULL_END
