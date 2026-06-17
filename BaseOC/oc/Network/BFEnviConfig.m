//
//  BFEnviConfig.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/6.
//

#import "BFEnviConfig.h"

NSString *const kBFEnviConfigNetworkKey = @"kBFEnviConfigNetworkKey";
@implementation BFEnviConfig


+ (BFSchemeEnvi)envi{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *envi = [userDefaults valueForKey:kBFEnviConfigNetworkKey];
    if (envi == nil){
        envi = @(BFSchemeEnviDev);
        [userDefaults setValue:envi forKey:kBFEnviConfigNetworkKey];
        [userDefaults synchronize];
    }
    return (BFSchemeEnvi)envi.integerValue;
}

+ (void)setEnvi:(BFSchemeEnvi)envi{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:@(envi) forKey:kBFEnviConfigNetworkKey];
    [userDefaults synchronize];
}

+ (NSString *)enviToSting{
    NSUInteger index = [self envi];
    return [self allEnvi][index];
}

+ (NSArray <NSString *>*)allEnvi{
    return @[@"测试",@"预生产",@"生产"];
}

+ (void)enviConfig:(void (^)(void))complation{
    UIAlertController *alert = [UIAlertController alertStyle:UIAlertControllerStyleActionSheet title:@"切换环境" message:nil cancel:@"取消" cancelBlock:^(NSString * _Nonnull cancel) {
        
    } confirms:[self allEnvi] confirmBlock:^(NSUInteger index) {
        if ([self envi] != index){
            [self setEnvi:index];
            complation();
        }
    }];
    [UIViewController.currentViewController presentViewController:alert animated:YES completion:nil];
}

@end
