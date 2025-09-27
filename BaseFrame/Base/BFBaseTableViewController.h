//
//  BFBaseTableViewController.h
//  OCProject
//
//  Created by 王祥伟 on 2024/1/5.
//

#import "BFBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFBaseTableViewController : BFBaseViewController
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *data;

- (NSString *)cellClass;
- (NSString *)actionString;
@end

NS_ASSUME_NONNULL_END
