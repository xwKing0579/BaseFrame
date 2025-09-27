//
//  BFOperationManager.m
//  OCProject
//
//  Created by 王祥伟 on 2024/3/11.
//

#import "BFOperationManager.h"
#import "BFOperation.h"

@interface BFOperationManager ()
@property (nonatomic, strong) NSOperationQueue *taskQueue;
@property (nonatomic, strong) NSMutableDictionary *objectPtrs;
@end

@implementation BFOperationManager

+ (instancetype)sharedManager {
    static BFOperationManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [self new];
    });
    return manager;
}

+ (void)addOperationModel:(BFOperationModel *)model{
    if (!model) return;
    BFOperationManager *manager = [BFOperationManager sharedManager];
    NSString *key = [NSString stringWithFormat:@"%ld",(uintptr_t)model];
    
    BFOperation *operation = [[BFOperation alloc] init];
    operation.model = model;
    operation.queuePriority = model.priority;
    [manager.taskQueue addOperation:operation];
    [manager.objectPtrs setValue:operation forKey:key];
}

+ (void)removeOperationForModel:(BFOperationModel *)model{
    if (!model) return;
    NSString *key = [NSString stringWithFormat:@"%ld",(uintptr_t)model];
    [self removeOperationForKey:key];
}

+ (void)removeAllOperation{
    BFOperationManager *manager = [BFOperationManager sharedManager];
    for (NSString *key in manager.objectPtrs.allKeys) {
        [self removeOperationForKey:key];
    }
}

+ (void)removeOperationForKey:(NSString *)key{
    BFOperationManager *manager = [BFOperationManager sharedManager];
    if ([manager.objectPtrs valueForKey:key]){
        BFOperation *operation = manager.objectPtrs[key];
        operation.isExecuting ? operation.finished = YES : [operation cancel];
        [manager.objectPtrs removeObjectForKey:key];
        operation = nil;
    }
}

- (NSMutableDictionary *)objectPtrs{
    if (!_objectPtrs){
        _objectPtrs = [[NSMutableDictionary alloc] init];
    }
    return _objectPtrs;
}

- (NSOperationQueue *)taskQueue{
    if (!_taskQueue){
        _taskQueue = [[NSOperationQueue alloc] init];
        _taskQueue.maxConcurrentOperationCount = 1;
    }
    return _taskQueue;
}

@end
