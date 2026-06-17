//
//  NSDate+Category.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/13.
//

#import "NSDate+Category.h"

@implementation NSDate (Category)

+ (NSString *)currentTime{
    return [self currentTimeFormatterString:[self yearToSecond]];
}

+ (NSString *)currentTimeFormatterString:(NSString *)formatterString{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:formatterString];
    return [formatter stringFromDate:[NSDate date]];
}

+ (NSString *)timeFromDate:(NSDate *)date{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:[self yearToSecond]];
    return [formatter stringFromDate:date];
}

- (NSString *)toString{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:[self yearToSecond]];
    return [formatter stringFromDate:self];
}

- (NSString *)yearToSecond{
    return [NSDate yearToSecond];
}

+ (NSString *)yearToSecond{
    return @"yyyy-MM-dd";
}

+ (NSDate *)yearBefore:(int)n{
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = -n;
    return [calendar dateByAddingComponents:components toDate:now options:0];
}

- (NSDateComponents *)dateComponents{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:self];
    return components;
}

+ (NSInteger)daysInYear:(NSInteger)year month:(NSInteger)month{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = year;
    components.month = month;
    NSDate *firstDayOfMonth = [calendar dateFromComponents:components];
    NSRange range = [calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:firstDayOfMonth];
    NSInteger daysInMonth = range.length;
    return daysInMonth;
}

@end
