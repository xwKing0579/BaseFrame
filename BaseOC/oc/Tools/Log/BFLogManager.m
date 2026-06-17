//
//  BFLogManager.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/19.
//

#import "BFLogManager.h"
#include "fishhook.h"

NSString *const kTPLogConfigKey = @"kTPLogConfigKey";

//函数指针，用来保存原始的函数的地址
static void(*oldLog)(NSString *format, ...);

//新的NSLog
void newLog(NSString *format, ...){
    
    va_list vl;
    va_start(vl, format);
    NSString *str = [[NSString alloc] initWithFormat:format arguments:vl];
    va_end(vl);
    
    [[BFLogManager sharedManager] addLog:str];

    oldLog(@"%@",str);
}

@interface BFLogManager ()
@property (nonatomic, strong) NSMutableArray<BFLogModel *> *data;
@end

@implementation BFLogManager

+ (void)load {
#ifdef DEBUG
    
#endif
}

+ (instancetype)sharedManager {
    static BFLogManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [self new];
        sharedManager.data = [NSMutableArray array];
    });
    
    return sharedManager;
}

+ (void)start{
    rebind_symbols((struct rebinding[1]){"NSLog", (void *)newLog, (void **)&oldLog},1);
    [[NSUserDefaults standardUserDefaults] setValue:@(YES) forKey:kTPLogConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)stop{
    rebind_symbols((struct rebinding[1]){"NSLog", (void *)oldLog, NULL},1);
    [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:kTPLogConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)isOn{
    return [[[NSUserDefaults standardUserDefaults] valueForKey:kTPLogConfigKey] boolValue];
}

- (void)addLog:(NSString *)log{
    BFLogModel *model = [BFLogModel new];
    model.content = log;
    model.thread = [NSThread currentThread].description;
    model.date = [NSDate currentTime];
    [[BFLogManager sharedManager].data addObject:model];
}

+ (NSMutableArray<BFLogModel *> *)data{
    return [self sharedManager].data;
}

+ (void)removeData{
    [[self sharedManager].data removeAllObjects];
}

@end
