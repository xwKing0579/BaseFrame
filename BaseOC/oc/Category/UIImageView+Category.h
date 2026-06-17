//
//  UIImageView+Category.h
//  QuShou
//
//  Created by 王祥伟 on 2024/4/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (Category)

- (void)setImageUrl:(id)url;
- (void)setImageUrl:(id)url placeholder:(id _Nullable)placeholder;

@end

NS_ASSUME_NONNULL_END
