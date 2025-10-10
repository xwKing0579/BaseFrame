//
//  BFConfuseModel.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/7/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFConfuseModel : NSObject

//替换属性列表和映射操作
+ (void)auditAndFixProjectAtPath:(NSString *)projectPath
                propertyMappings:(NSDictionary<NSString *, NSString *> *)mappings
                  whitelistedPods:(NSArray<NSString *> *)whitelistedPods;


+ (NSArray<NSString *> *)extractModelPropertiesFromProjectPath:(NSString *)projectPath
                                                  pathWhitelist:(NSArray<NSString *> *)whitelist
                                                  pathBlacklist:(NSArray<NSString *> *)blacklist;

+ (NSDictionary *)mapModelDict;
+ (NSDictionary *)mapModelDict1;
+ (NSDictionary *)mapModelDict2;
+ (NSDictionary *)mapModelDict103;
@end

NS_ASSUME_NONNULL_END
