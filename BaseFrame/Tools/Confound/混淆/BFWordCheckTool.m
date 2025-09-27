//
//  BFWordCheckTool.m
//  BaseFrame
//
//  Created by 王祥伟 on 2025/6/18.
//

#import "BFWordCheckTool.h"

@implementation BFWordCheckTool

+ (void)checkNewDict:(NSDictionary *)newDict oldDict:(NSDictionary *)oldDict{
    NSMutableDictionary *repeatDict = [NSMutableDictionary dictionary];
    NSMutableDictionary *repeatValueDict = [NSMutableDictionary dictionary];
    NSMutableDictionary *missingDict = [NSMutableDictionary dictionary];
    NSMutableDictionary *confuseDict = [NSMutableDictionary dictionary];
    
    NSMutableArray *temp = [NSMutableArray array];
    NSMutableArray *valueTemp = [NSMutableArray array];
    for (NSString *keyStr in newDict.allKeys) {
        if ([temp containsObject:keyStr]){
            [repeatDict setValue:newDict[keyStr] forKey:keyStr];
        }else{
            [temp addObject:keyStr];
        }
        
        NSString *value = newDict[keyStr];
        if ([valueTemp containsObject:value]){
            [repeatValueDict setValue:value forKey:keyStr];
        }else{
            [valueTemp addObject:value];
        }
    }
    NSLog(@"重复key部分：\n%@",repeatDict);
    NSLog(@"重复value部分：\n%@",repeatValueDict);
    
    for (NSString *keyStr in oldDict.allKeys) {
        if ([newDict.allKeys containsObject:keyStr]){
            
        }else{
            [missingDict setValue:oldDict[keyStr] forKey:keyStr];
        }
    }
    NSLog(@"丢失部分：新字典数量 = %ld,旧字典数量 = %ld \n%@",newDict.allKeys.count,oldDict.allKeys.count,missingDict);
    
    [newDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * _Nonnull stop) {
        NSString *noHeadKey = [key stringByReplacingOccurrencesOfString:@"DB" withString:@""];
        NSString *noHeadValue = [obj stringByReplacingOccurrencesOfString:@"gg_" withString:@""];
        
        NSString *oldValue = oldDict[key]?:@"";
        NSString *noHeadOldValue = [oldValue stringByReplacingOccurrencesOfString:@"gg_" withString:@""];
        if ([noHeadValue containsString:noHeadKey] || [noHeadKey containsString:noHeadValue] || [noHeadValue containsString:noHeadOldValue] || [noHeadOldValue containsString:noHeadValue]){
            [confuseDict setValue:newDict[key] forKey:key];
        }
    }];
    NSLog(@"混淆错误：\n%@",confuseDict);
}

@end
