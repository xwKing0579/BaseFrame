//
//  BFEnviConfig.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger,BFSchemeEnvi){
    BFSchemeEnviDev = 0,
    BFSchemeEnviPreRelese,
    BFSchemeEnviRelese,
};

@interface BFEnviConfig : NSObject

+ (BFSchemeEnvi)envi;
+ (NSString *)enviToSting;
+ (NSArray <NSString *>*)allEnvi;

+ (void)setEnvi:(BFSchemeEnvi)envi;

+ (void)enviConfig:(void (^)(void))complation;

@end

NS_ASSUME_NONNULL_END
