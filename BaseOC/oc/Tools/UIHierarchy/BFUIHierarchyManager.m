//
//  BFUIHierarchyManager.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/25.
//

#import "BFUIHierarchyManager.h"
NSString *const kTPUIHierarchyConfigKey = @"kTPUIHierarchyConfigKey";
NSString *const kTPUIHierarchyNotification = @"kTPUIHierarchyNotification";
@implementation BFUIHierarchyManager

+ (void)start{
    [self updateBoolValue:YES];
}

+ (void)stop{
    [self updateBoolValue:NO];
}

+ (void)updateBoolValue:(BOOL)value{
    [[NSUserDefaults standardUserDefaults] setValue:@(value) forKey:kTPUIHierarchyConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [NSObject performTarget:BFString.bf_debug_tool.classString action:@"didChangeUIHierarchy"];
}

+ (BOOL)isOn{
    return [[[NSUserDefaults standardUserDefaults] valueForKey:kTPUIHierarchyConfigKey] boolValue];
}

+ (BFUIHierarchyModel *)viewUIHierarchy:(id)obj{
    if (!obj) return nil;
    UIView *view = nil;
    if ([obj isKindOfClass:[UIViewController class]]) {
        UIViewController *vc = (UIViewController *)obj;
        view = vc.view;
    }else if ([obj isKindOfClass:[UIView class]]){
        view = obj;
    }
    if (!view) return nil;
    return [self getSubviewsFromViews:@[view] withViewDeepLevel:0 next:NO].firstObject;
}

+ (NSArray <BFUIHierarchyModel *>*)getSubviewsFromViews:(NSArray <UIView *>*)views withViewDeepLevel:(int)deepLevel next:(BOOL)next{
    NSMutableArray *array = [NSMutableArray array];
    for (UIView *subview in views.reverseObjectEnumerator) {
        BFUIHierarchyModel *model = [BFUIHierarchyModel new];
        model.deepLevel = deepLevel+1;
        UIResponder *responder = subview.nextResponder;
        if (!next && [responder isKindOfClass:[UIViewController class]]){
            model.objectClass = NSStringFromClass([responder class]);
            model.haveSubviews = YES;
            model.isController = YES;
            model.objectPtr = (uintptr_t)subview.nextResponder;
            model.subviews = [self getSubviewsFromViews:@[subview] withViewDeepLevel:model.deepLevel next:YES];
        }else{
            model.objectClass = NSStringFromClass([subview class]);
            model.haveSubviews = subview.subviews.count;
            model.objectPtr = (uintptr_t)subview;
            model.subviews = [self getSubviewsFromViews:subview.subviews withViewDeepLevel:model.deepLevel next:NO];
        }
        [array addObject:model];
    }
    return array;
}

+ (BFUIHierarchyModel *)viewControllers{
    return [self getViewControllers:@[UIViewController.rootViewController] withViewDeepLevel:0].firstObject;
}

+ (NSArray <BFUIHierarchyModel *>*)getViewControllers:(NSArray <__kindof UIViewController *>*)vcs withViewDeepLevel:(int)deepLevel{
    NSMutableArray *array = [NSMutableArray array];
    for (UIViewController *vc in vcs) {
        BFUIHierarchyModel *model = [BFUIHierarchyModel new];
        model.deepLevel = deepLevel+1;
        model.objectClass = NSStringFromClass([vc class]);
        model.haveSubviews = vc.childViewControllers.count;
        model.isController = YES;
        model.objectPtr = (uintptr_t)vc.nextResponder;
        model.subviews = [self getViewControllers:vc.childViewControllers withViewDeepLevel:model.deepLevel];
        [array addObject:model];
    }
    return array;
}

@end
