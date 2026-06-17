//
//  BFBaseTabBarController.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/5.
//

#import "BFBaseTabBarController.h"

@interface BFBaseTabBarController ()

@end

@implementation BFBaseTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)setUpViewControllersInNavClass:(Class)navClass
                             rootClass:(Class)rootClass
                            tabBarName:(NSString *)name
                       tabBarImageName:(NSString *)imageName{
    [self setUpViewControllersInNavClass:navClass rootClass:rootClass tabBarName:name tabBarImageName:imageName size:UIFont.font12 color:UIColor.c333333 selColor:UIColor.c000000];
}

- (void)setUpViewControllersInNavClass:(Class)navClass
                             rootClass:(Class)rootClass
                            tabBarName:(NSString *)name
                       tabBarImageName:(NSString *)imageName
                                  size:(UIFont *)size
                                 color:(UIColor *)color
                              selColor:(UIColor *)selColor{
    __kindof UINavigationController *nav = [[navClass  alloc] initWithRootViewController:[rootClass new]];
    
    nav.tabBarItem.title = name;
    nav.tabBarItem.image = [UIImage imageNamed:imageName].original;
    NSString *selectedImage = [NSString stringWithFormat:@"%@_sel",imageName];
    nav.tabBarItem.selectedImage = [UIImage imageNamed:selectedImage].original;
    
    if (@available (iOS 13.0, *)) {
        self.tabBar.unselectedItemTintColor = color;
        self.tabBar.tintColor = selColor;
    }else{
        [nav.tabBarItem setTitleTextAttributes:
         @{NSForegroundColorAttributeName:color,
                      NSFontAttributeName:size}
                                 forState:UIControlStateNormal];
        [nav.tabBarItem setTitleTextAttributes:
         @{NSForegroundColorAttributeName:selColor,
                      NSFontAttributeName:size}
                                 forState:UIControlStateSelected];
    }
   
    [self addChildViewController:nav];
}

@end
