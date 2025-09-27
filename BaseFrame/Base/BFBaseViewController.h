//
//  BFBaseViewController.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFBaseViewController : UIViewController
///通用回调
@property (nonatomic, copy) void (^block)(id obj);

///hidden navbar
- (BOOL)hideNavigationBar;
- (BOOL)disableNavigationBar;

///back
- (void)backViewController;
- (UIColor *)backButtonColor;
- (BOOL)hideBackButton;

@end

NS_ASSUME_NONNULL_END
