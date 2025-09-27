//
//  BFOperationModel.h
//  OCProject
//
//  Created by 王祥伟 on 2024/3/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFOperationModel : NSObject

@property (nonatomic, assign) NSOperationQueuePriority priority;
@property (nonatomic, copy) void (^block)(NSOperation *operation, BFOperationModel *model);

@end

NS_ASSUME_NONNULL_END
