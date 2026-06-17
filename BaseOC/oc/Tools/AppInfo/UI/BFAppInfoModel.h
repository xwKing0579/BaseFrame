//
//  BFAppInfoModel.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class BFAppInfoListModel;
@interface BFAppInfoModel : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray <BFAppInfoListModel *>*item;

+ (NSArray <BFAppInfoModel *>*)data;

@end

@interface BFAppInfoListModel : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *content;
@end
NS_ASSUME_NONNULL_END
