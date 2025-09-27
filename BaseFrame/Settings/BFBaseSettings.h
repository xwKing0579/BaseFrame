//
//  BFBaseSettings.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger,BFSettingState){
    BFSettingStateNotDetermined = 0,
    BFSettingStateRestricted,
    BFSettingStateDenied,
    BFSettingStateAuthorized,
    BFSettingStateLimited,
    BFSettingStateUnknown,
};

@interface BFBaseSettings : NSObject

+ (BOOL)isAuthorized;

+ (void)requestAuthorization:(void(^)(BFSettingState state,NSDictionary *info))completion;

@end

NS_ASSUME_NONNULL_END
