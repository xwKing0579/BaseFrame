//
//  BFBaseViewController.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/5.
//

#import "BFBaseViewController.h"
#import "UINavigationController+FDFullscreenPopGesture.h"

@interface BFBaseViewController ()<UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIButton *backBtn;

@end

@implementation BFBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSString *imageString;
    if (self.navigationController.childViewControllers.count > 1) {
        imageString = @"back";
    }else if (self.presentingViewController){
        imageString = @"close";
    }
    if (imageString) {
        UIImage *image = [UIImage imageNamed:imageString].original;
        if ([self backButtonColor]) image = [image imageWithTintColor:[self backButtonColor]];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:image style:(UIBarButtonItemStyleDone) target:self action:@selector(backViewController)];
    }
    self.fd_interactivePopDisabled = [self disableNavigationBar];
    self.fd_prefersNavigationBarHidden = [self hideNavigationBar];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.view.backgroundColor = UIColor.cFFFFFF;
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (![self hideBackButton]) {
        [self.view addSubview:self.backBtn];
    }
}


- (UIButton *)backBtn{
    if (!_backBtn){
        _backBtn = [[UIButton alloc] init];
        
        UIImage *image = UIImage.back;
        if ([self backButtonColor]) image = [image imageWithTintColor:[self backButtonColor]];
        [_backBtn setImage:image forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backViewController) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_backBtn];
        [_backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(10);
            make.top.mas_equalTo(UIDevice.statusBarHeight);
            make.width.height.mas_equalTo(UIDevice.navBarHeight);
        }];
    }
    return _backBtn;
}

///back
- (void)backViewController{
    [BFRouter back];
}

///hidden navbar
- (BOOL)hideNavigationBar{
    return NO;
}

- (BOOL)disableNavigationBar{
    return NO;
}

- (UIColor *)backButtonColor{
    return UIColor.c000000;
}

- (BOOL)hideBackButton{
    return YES;
}
@end
