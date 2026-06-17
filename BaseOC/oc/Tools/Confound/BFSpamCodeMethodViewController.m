//
//  BFSpamCodeMethodViewController.m
//  OCProject
//
//  Created by 王祥伟 on 2024/3/27.
//

#import "BFSpamCodeMethodViewController.h"
#import "BFConfoundModel.h"
@interface BFSpamCodeMethodViewController ()

@end

@implementation BFSpamCodeMethodViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"新增方法名前缀";
    self.data = [BFConfoundModel data_code_method];
    [self.tableView reloadData];
}

- (NSString *)cellClass{
    return BFString.tc_spam_code_model;
}


@end
