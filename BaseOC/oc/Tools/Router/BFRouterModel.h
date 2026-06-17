//
//  BFRouterModel.h
//  QuShou
//
//  Created by 王祥伟 on 2024/4/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFRouterModel : NSObject

@property (nonatomic, copy) NSString *ivar;
@property (nonatomic, copy) NSString *property;

@property (nonatomic, strong) NSObject *value;
@property (nonatomic, strong) NSArray *params;
@property (nonatomic, strong) BFRouterModel *superRouter;

+ (NSDictionary *)hfiles;

@end

NS_ASSUME_NONNULL_END
