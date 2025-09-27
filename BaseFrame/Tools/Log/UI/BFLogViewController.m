//
//  BFLogViewController.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/19.
//

#import "BFLogViewController.h"
#import "BFLogManager.h"

@interface BFLogViewController ()
@end

@implementation BFLogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = [NSString stringWithFormat:@"Log(%@)",[BFLogManager isOn] ? @"开" : @"关"];
    
    [self setUpSubViews];
}

- (void)setUpSubViews{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"delete"].original style:(UIBarButtonItemStyleDone) target:self action:@selector(removeLogData)];
    
    self.data = ((NSArray *)BFLogManager.data).reverseObjectEnumerator.allObjects;
    [self.tableView reloadData];
}

- (void)removeLogData{
    [BFLogManager removeData];
    self.data = BFLogManager.data;
    [self.tableView reloadData];
}

- (NSString *)cellClass{
    return BFString.tc_log;
}

#pragma mark -- UITableViewDelegate,UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.data.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [BFRouter jumpUrl:BFString.vc_log_detail params:@{@"model":self.data[indexPath.row]}];
}

@end
