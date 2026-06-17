//
//  BFBaseSettings.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/6.
//

#import "BFBaseSettings.h"

@implementation BFBaseSettings
+ (BOOL)isAuthorized{
    return NO;
}

+ (void)requestAuthorization:(void(^)(BFSettingState state,NSDictionary *info))completion{
    completion(BFSettingStateUnknown,nil);
}

@end
