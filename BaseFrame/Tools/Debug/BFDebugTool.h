//
//  BFDebugTool.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFDebugTool : NSObject

@property (nonatomic, readonly, strong) UIView *targetView;
@property (nonatomic, readonly, assign) CGPoint targetPoint;

+ (instancetype)manager;

+ (void)start;
+ (void)stop;

@end

NS_ASSUME_NONNULL_END
