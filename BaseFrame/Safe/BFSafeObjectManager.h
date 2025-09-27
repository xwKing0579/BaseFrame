//
//  BFSafeObjectManager.h
//  OCProject
//
//  Created by 王祥伟 on 2024/1/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFSafeObjectManager : NSObject

+ (void)safeObjectWithException:(NSException *)exception;

@end

NS_ASSUME_NONNULL_END
