//
//  BFConfuseProject.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFConfuseProject : NSObject
//项目重新命名
+ (void)renameProjectAtPath:(NSString *)projectPath oldName:(NSString *)oldName newName:(NSString *)newName;


@end

NS_ASSUME_NONNULL_END
