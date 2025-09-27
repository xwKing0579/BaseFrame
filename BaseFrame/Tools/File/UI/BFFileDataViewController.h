//
//  BFFileDataViewController.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/15.
//

#import "BFBaseViewController.h"
#import "BFBaseTableViewController.h"
NS_ASSUME_NONNULL_BEGIN

@interface BFFileDataViewController : BFBaseTableViewController
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSDictionary *dic;
@end

NS_ASSUME_NONNULL_END
