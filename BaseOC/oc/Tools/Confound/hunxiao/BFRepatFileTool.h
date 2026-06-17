//
//  BFRepatFileTool.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFRepatFileTool : NSObject
+ (NSDictionary *)findAllDuplicatesInProjectAtPath:(NSString *)projectPath;
+ (void)removeCommentLinesInDirectory:(NSString *)directoryPath;
@end

NS_ASSUME_NONNULL_END
