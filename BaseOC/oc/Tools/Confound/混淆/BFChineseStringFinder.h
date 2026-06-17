//
//  BFChineseStringFinder.h
//  BaseFrame
//
//  Created by 王祥伟 on 2025/6/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFChineseStringFinder : NSObject
+ (void)findChineseStringsInDirectory:(NSString *)directoryPath;
@end

NS_ASSUME_NONNULL_END
