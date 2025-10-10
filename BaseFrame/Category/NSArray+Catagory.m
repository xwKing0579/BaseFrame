//
//  NSArray+Catagory.m
//  BaseFrame
//
//  Created by King on 2025/9/21.
//

#import "NSArray+Catagory.h"

@implementation NSArray (Catagory)

- (void)printRepeatItems{
    [self filterRepeatItems:YES];
}

- (NSArray *)filterRepeatItems{
    return [self filterRepeatItems:NO];
}

- (NSArray *)filterRepeatItems:(BOOL)print{
    NSMutableArray *tempArr = [NSMutableArray array];
    
    for (id obj in self) {
        if (![tempArr containsObject:obj]){
            [tempArr addObject:obj];
        }else{
            if (print) NSLog(@"重复元素 %@",obj);
        }
    }
    return tempArr;
}

- (NSArray<NSString *> *)sortedArrayByStringLengthAscending {
    return [self sortedArrayByStringLengthOrder:YES];
}

- (NSArray<NSString *> *)sortedArrayByStringLengthOrder:(BOOL)ascending {
    // 首先过滤出字符串对象
    NSArray<NSString *> *stringArray = [self filteredArrayUsingPredicate:
                                       [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isKindOfClass:[NSString class]];
    }]];
    
    // 根据字符串长度排序
    return [stringArray sortedArrayUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
        NSUInteger length1 = str1.length;
        NSUInteger length2 = str2.length;
        
        if (length1 < length2) {
            return ascending ? NSOrderedAscending : NSOrderedDescending;
        } else if (length1 > length2) {
            return ascending ? NSOrderedDescending : NSOrderedAscending;
        } else {
            // 长度相等时按字母顺序排序
            return [str1 compare:str2];
        }
    }];
}
@end
