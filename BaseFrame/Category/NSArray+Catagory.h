//
//  NSArray+Catagory.h
//  BaseFrame
//
//  Created by King on 2025/9/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (Catagory)

//打印重复元素
- (void)printRepeatItems;

//筛选重复元素
- (NSArray *)filterRepeatItems;

//长度排序
- (NSArray<NSString *> *)sortedArrayByStringLengthAscending;
@end

NS_ASSUME_NONNULL_END
