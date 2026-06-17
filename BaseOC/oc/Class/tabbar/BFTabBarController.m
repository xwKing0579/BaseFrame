//
//  BFTabBarController.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/5.
//

#import "BFTabBarController.h"
#import "BFBaseNavigationController.h"
#import "BFModifyProject.h"
@interface BFTabBarController ()<UITabBarControllerDelegate>

@end

@implementation BFTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *names = @[BFString.vc_base,BFString.vc_base,BFString.vc_base,BFString.vc_base];
    NSArray *titles = @[@"1",@"2",@"3",@"4"];
    for (int i = 0; i < names.count; i++) {
        NSString *vcName = names[i];
        [self setUpViewControllersInNavClass:BFBaseNavigationController.class rootClass:NSClassFromString(vcName) tabBarName:titles[i] tabBarImageName:vcName.abbr];
    }
    
    if (@available (iOS 15.0, *)) {
         UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
         [appearance configureWithOpaqueBackground];
         appearance.backgroundColor = UIColor.cFFFFFF;
         self.tabBar.standardAppearance = appearance;
         self.tabBar.scrollEdgeAppearance = self.tabBar.standardAppearance;
     } else {
         self.tabBar.barTintColor = UIColor.cFFFFFF;
     }
    self.delegate = self;
    
    //统计中文
    //[ChineseStringsCollector traverseDirectoryAndCollectChineseStrings:@"/Users/wangxiangwei/Desktop/test"];
    //替换中文
    //[ChineseStringsCollector fanyizhongwen:@"/Users/wangxiangwei/Desktop/test" fromFile:@"/Users/wangxiangwei/Desktop/翻译/result.strings"];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController{
    return YES;
}

@end
