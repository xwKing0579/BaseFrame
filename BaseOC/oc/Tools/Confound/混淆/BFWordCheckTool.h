//
//  BFWordCheckTool.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/6/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFWordCheckTool : NSObject

//检查新字典比旧字典 缺少 部分
+ (void)checkNewDict:(NSDictionary *)newDict oldDict:(NSDictionary *)oldDict;

@end

NS_ASSUME_NONNULL_END
