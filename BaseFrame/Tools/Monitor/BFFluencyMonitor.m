//
//  BFFluencyMonitor.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/20.
//

#import "BFFluencyMonitor.h"
#import "BFThreadTrace.h"
#import "BFMonitorCache.h"
#import <execinfo.h>

NSInteger const kFluencyMonitor_count = 5;
NSInteger const kFluencyMonitorMillisecond = 80;
NSString *const kTPMonitorConfigKey = @"kTPMonitorConfigKey";

@interface BFFluencyMonitor (){
    CFRunLoopObserverRef _observer;  // 观察者
    dispatch_semaphore_t _semaphore; // 信号量
    CFRunLoopActivity _activity;     // 状态
    NSUInteger _count;               //次数
    BOOL isMonitoring;
}
@end

@implementation BFFluencyMonitor

static inline dispatch_queue_t fluency_monitor_queue(void) {
    static dispatch_queue_t fluency_monitor_queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        fluency_monitor_queue = dispatch_queue_create("com.monitor.queue", NULL);
    });
    return fluency_monitor_queue;
}

+ (void)load{
#ifdef DEBUG
    [self start];
#endif
}

+ (instancetype)sharedManager {
    static BFFluencyMonitor *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [self new];
    });
    return sharedManager;
}

+ (void)start{
    [[NSUserDefaults standardUserDefaults] setValue:@(YES) forKey:kTPMonitorConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    BFFluencyMonitor *manager = [BFFluencyMonitor sharedManager];
    if (manager->isMonitoring) return;
    CFRunLoopObserverContext context = {0, (__bridge void *)self, NULL, NULL};
    CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                        kCFRunLoopAllActivities,
                                        YES,
                                        0,
                                        &runLoopObserverCallBack,
                                        &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    manager->isMonitoring = YES;
    manager->_observer = observer;
    manager->_semaphore = semaphore;
    dispatch_async(fluency_monitor_queue(),^{
        while (1) {
            if (!manager->isMonitoring) return;
            
            long dsw = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, kFluencyMonitorMillisecond * NSEC_PER_MSEC));
            if (dsw != 0) {
                if (manager->_activity == kCFRunLoopBeforeSources || manager->_activity == kCFRunLoopAfterWaiting) {
                    if (++manager->_count < kFluencyMonitor_count){
                        continue;
                    }
                    BFMonitorModel *model = [BFMonitorModel new];
                    model.date = [NSDate currentTime];
                    model.thread = [NSThread mainThread].description;
                    model.stackSymbols = [NSThread callStackSymbols];
                    model.backtrace = [BFThreadTrace backtraceOfMainThread];
                    model.page = [NSString stringWithFormat:@"%@",UIViewController.currentViewController ?: UIViewController.window];
                    
                    id obj = [BFMonitorCache monitorData];
                    NSMutableArray *data = [NSMutableArray array];
                    if (obj) [data addObjectsFromArray:obj];
                    [data addObject:model];
                    [BFMonitorCache cacheMonitorData:data];
                }
            }
            manager->_count = 0;
        }
    });
}

static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    BFFluencyMonitor *shareManager = [BFFluencyMonitor sharedManager];
    shareManager->_activity = activity;
    dispatch_semaphore_t semaphore = shareManager->_semaphore;
    dispatch_semaphore_signal(semaphore);
}

+ (void)stop{
    [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:kTPMonitorConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    BFFluencyMonitor *manager = [BFFluencyMonitor sharedManager];
    if (!manager->isMonitoring) return;
    manager->isMonitoring = NO;
    if(!manager->_observer) return;
    CFRunLoopRemoveObserver(CFRunLoopGetMain(),manager->_observer, kCFRunLoopCommonModes);
    CFRelease(manager->_observer);
    manager->_observer = NULL;
}

+ (BOOL)isOn{
    return [[[NSUserDefaults standardUserDefaults] valueForKey:kTPMonitorConfigKey] boolValue];
}

@end
