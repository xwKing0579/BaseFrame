//
//  BFConfuseVariable.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/6/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFConfuseVariable : NSObject

+ (void)safeReplaceContentInDirectory:(NSString *)directoryPath
                        renameMapping:(NSDictionary<NSString *, NSString *> *)renameMapping;

+ (void)safeReplaceContentInDirectory:(NSString *)directoryPath
                     renameSetMapping:(NSDictionary<NSString *, NSString *> *)renameSetMapping;

+ (NSArray <NSString *> *)scanVariablesInDirectory:(NSString *)directoryPath;


+ (NSDictionary *)mapVariableDict;
+ (NSDictionary *)mapVariableDict1;
+ (NSDictionary *)mapVariableDict4;

+ (NSDictionary *)mapSetVariableDict;
+ (NSDictionary *)mapSetVariableDict1;
+ (NSDictionary *)mapSetVariableDict4;
@end

NS_ASSUME_NONNULL_END
