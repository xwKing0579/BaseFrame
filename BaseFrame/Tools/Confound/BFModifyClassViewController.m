//
//  BFModifyClassViewController.m
//  OCProject
//
//  Created by 王祥伟 on 2024/3/28.
//

#import "BFModifyClassViewController.h"
#import "BFConfoundModel.h"
#import "BFModifyProject.h"
@interface BFModifyClassViewController ()

@end

@implementation BFModifyClassViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"修改类名前缀(大写)";
    self.data = [BFConfoundModel data_modify_class];
    [self.tableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellString = indexPath.row == 0 ? BFString.tc_confound : BFString.tc_spam_code_model;
    return [NSObject performTarget:cellString.classString action:[self actionString] object:tableView object:self.data[indexPath.row]] ?: [UITableViewCell new];
}
@end
