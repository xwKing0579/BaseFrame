//
//  BFSpamCodeViewController.m
//  OCProject
//
//  Created by 王祥伟 on 2024/3/22.
//

#import "BFSpamCodeViewController.h"
#import "BFConfoundModel.h"

@interface BFSpamCodeViewController ()

@end

@implementation BFSpamCodeViewController

/*
 * view将要出现
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"垃圾代码配置";
    self.data = [BFConfoundModel data_code];
    [self.tableView reloadData];
}

- (NSString *)cellClass{
    return BFString.tc_confound;
}

#pragma mark -- UITableViewDelegate,UITableViewDataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    BFConfoundModel *model = self.data[indexPath.row];
    [BFRouter jumpUrl:model.url];
}

@end
