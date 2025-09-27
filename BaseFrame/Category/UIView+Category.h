//
//  UIView+Category.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/7.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Category)
@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, assign) CGSize  size;

- (void)addSubviews:(NSArray *)views;
- (void)removeAllSubView;
- (void)removeAllSubViewExcept:(NSArray *)views;

//所有子视图
- (NSArray *)allSubViews;

- (UIImage *)toImage;

- (void)setRoundCorners:(UIRectCorner)corners cornerRadii:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
