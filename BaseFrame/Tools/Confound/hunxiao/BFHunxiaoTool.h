//
//  BFHunxiaoTool.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/4/10.
//

#import <Foundation/Foundation.h>
#import "BFGrabWordsTool.h"
NS_ASSUME_NONNULL_BEGIN

@interface BFHunxiaoTool : NSObject

//修改项目名称
+ (BOOL)renameProjectAtPath:(NSString *)projectPath fromOldName:(NSString *)oldName toNewName:(NSString *)newName error:(NSError **)error;

//方法重命名
+ (BOOL)renameMethodNameAtPath:(NSString *)projectPath wordType:(WordsType)wordType;



@end


NS_ASSUME_NONNULL_END
