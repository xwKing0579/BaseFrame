//
//  BFDebugToolViewController.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/7.
//

#import "BFBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN
@class BFDebugToolViewCell,BFDebugToolModel;
@interface BFDebugToolViewController : BFBaseViewController

@end


@interface BFDebugToolViewCell : UICollectionViewCell

@property (nonatomic, copy) BFDebugToolModel *model;

@end

@interface BFDebugToolModel : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *image;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *target;
@property (nonatomic, copy) NSString *action;

+ (NSArray *)data;
@end

NS_ASSUME_NONNULL_END
