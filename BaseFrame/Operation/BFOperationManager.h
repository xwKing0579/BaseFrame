//
//  BFOperationManager.h
//  OCProject
//
//  Created by 王祥伟 on 2024/3/11.
//

#import <Foundation/Foundation.h>
#import "BFOperationModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface BFOperationManager : NSObject

+ (void)addOperationModel:(BFOperationModel *)model;
+ (void)removeOperationForModel:(BFOperationModel *)model;
+ (void)removeAllOperation;

@end

NS_ASSUME_NONNULL_END
