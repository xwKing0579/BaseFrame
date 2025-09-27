//
//  MBProgressHUD+Category.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/18.
//

#import "MBProgressHUD+Category.h"
//#import "NSObject+MemoryLeak.h"

static MBProgressHUD *_textHud;
static MBProgressHUD *_loadingHud;
@implementation MBProgressHUD (Category)

+ (void)showText:(NSString *)text{
    [self showText:text inView:UIViewController.currentViewController.view];
}

+ (void)showText:(NSString *)text inView:(UIView *)view{
    [self showText:text inView:view enable:YES];
}

+ (void)showText:(NSString *)text inView:(UIView *)view enable:(BOOL)enable{
    [self showText:text inView:view enable:enable afterDelay:0 offsetY:0];
}

+ (void)showText:(NSString *)text inView:(UIView *)view enable:(BOOL)enable afterDelay:(NSTimeInterval)afterDelay offsetY:(CGFloat)offsetY{
    if (!text.noNull) return;
    if (!_textHud) _textHud = [MBProgressHUD new];
    MBProgressHUD *hud = _textHud;
    hud.userInteractionEnabled = !enable;
    hud.mode = MBProgressHUDModeText;
    hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    hud.bezelView.color = [UIColor colorWithWhite:0.f alpha:0.5];
    hud.removeFromSuperViewOnHide = YES;
    hud.detailsLabel.text = text;
    hud.detailsLabel.textColor = UIColor.whiteColor;
    hud.offset = CGPointMake(0, offsetY);
    UIView *rootView = view ?: UIViewController.window;
    [rootView addSubview:hud];
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:afterDelay ?: 1.5+(text.length/15)*0.8];
}

+ (void)showLoading{
    [self showLoadingInView:UIViewController.currentViewController.view];
}

+ (void)showLoadingInView:(UIView *)view{
    [self showLoadingInView:view enable:NO];
}

+ (void)showLoadingInView:(UIView *)view enable:(BOOL)enable{
    if (!_loadingHud) _loadingHud = [MBProgressHUD new];
    MBProgressHUD *hud = _loadingHud;
    hud.userInteractionEnabled = !enable;
    hud.mode = MBProgressHUDModeCustomView;
    hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    hud.bezelView.color = UIColor.clearColor;
    
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 120)];
    
    CAReplicatorLayer *replicatorLayer = [CAReplicatorLayer layer];
    replicatorLayer.bounds          = customView.bounds;
    replicatorLayer.position        = customView.center;
    replicatorLayer.backgroundColor = UIColor.c000000.CGColor;
    replicatorLayer.cornerRadius    = 8;
    replicatorLayer.masksToBounds   = YES;
  
    [customView.layer addSublayer:replicatorLayer];

    CALayer *dotLayer        = [CALayer layer];
    dotLayer.bounds          = CGRectMake(0, 0, 6, 6);
    dotLayer.position        = CGPointMake(30, 100);
    dotLayer.backgroundColor = UIColor.blueColor.CGColor;
    dotLayer.cornerRadius    = 3;
    [replicatorLayer addSublayer:dotLayer];
    
    replicatorLayer.instanceCount = 3;
    replicatorLayer.instanceTransform = CATransform3DMakeTranslation((replicatorLayer.frame.size.width-30)/3, 0, 0);
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.duration    = 1;
    animation.fromValue   = @1;
    animation.toValue     = @1.3;
    animation.repeatCount = MAXFLOAT;
    [dotLayer addAnimation:animation forKey:nil];
    replicatorLayer.instanceDelay = 1;
    
    
    UIImageView *iconImageView = [[UIImageView alloc] init];
    iconImageView.image = UIImage.loading;
    iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    [customView addSubview:iconImageView];
    [iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(70);
        make.top.mas_equalTo(15);
        make.centerX.mas_equalTo(0);
    }];
    
    hud.customView = customView;
    UIView *rootView = view ?: UIViewController.window;
    [rootView addSubview:hud];
    [customView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(0);
        make.width.height.mas_equalTo(100);
    }];
    [hud showAnimated:YES];
}

+ (void)hideLoading{
    [_textHud hideAnimated:YES];
    [_loadingHud hideAnimated:YES];
}

- (BOOL)willDealloc{
    return YES;
}

@end
