//
//  BFFileContentTool.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFFileContentTool : NSObject
+ (NSSet<NSString *> *)findAllClassNamesInProjectDirectory:(NSString *)directoryPath;
@end

NS_ASSUME_NONNULL_END
