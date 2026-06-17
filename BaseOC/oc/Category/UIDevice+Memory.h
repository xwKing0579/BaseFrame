//
//  UIDevice+Memory.h
//  BaseFrame
//
//  Created by 王祥伟 on 2024/11/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDevice (Memory)


/// 获取手机内存总量, 返回的是字节数
+ (long long)totalMemoryBytes;
/// 获取手机可用内存, 返回的是字节数
+ (long long)freeMemoryBytes;

/// 获取手机硬盘空闲空间, 返回的是字节数
+ (long long)freeDiskSpaceBytes;
/// 获取手机硬盘总空间, 返回的是字节数
+ (long long)totalDiskSpaceBytes;




@end

NS_ASSUME_NONNULL_END
