//
//  BFModifyProjectViewController.m
//  OCProject
//
//  Created by 王祥伟 on 2024/3/28.
//

#import "BFModifyProjectViewController.h"
#import "BFConfoundModel.h"
@interface BFModifyProjectViewController ()

@end

@implementation BFModifyProjectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"修改项目名称";
    self.data = [BFConfoundModel data_modify_project];
    [self.tableView reloadData];
}

- (NSString *)cellClass{
    return BFString.tc_spam_code_model;
}

@end
