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

@end
