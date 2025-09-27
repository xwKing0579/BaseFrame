//
//  BFBaseNavigationController.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/5.
//

#import "BFBaseNavigationController.h"

@interface BFBaseNavigationController ()

@end

@implementation BFBaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationBar.translucent = NO;
    self.navigationBar.backgroundColor = [UIColor whiteColor];
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    appearance.backgroundColor = [UIColor whiteColor];
    UIImage *image = [UIImage createImageWithColor:UIColor.cFFFFFF];
    appearance.shadowImage = image;
    appearance.backgroundImage = image;
    self.navigationBar.standardAppearance =  appearance;
    self.navigationBar.scrollEdgeAppearance = appearance;
    [self.navigationBar setShadowImage:image];
    [self.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
}

@end
