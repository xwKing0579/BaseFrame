//
//  BFUiHierarchyViewController.h
//  OCProject
//
//  Created by 王祥伟 on 2024/3/14.
//

#import "BFBaseTableViewController.h"
#import "BFUIHierarchyModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface BFUiHierarchyViewController : BFBaseTableViewController

@property (nonatomic, strong) BFUIHierarchyModel *views;
@property (nonatomic, strong) BFUIHierarchyModel *vcs;

@end

NS_ASSUME_NONNULL_END
