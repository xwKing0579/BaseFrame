#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFCodeFormatter : NSObject

/// 格式化项目代码（一行代码实现）
/// @param projectPath 项目路径
+ (void)formatProjectAtPath:(NSString *)projectPath;

@end

NS_ASSUME_NONNULL_END
