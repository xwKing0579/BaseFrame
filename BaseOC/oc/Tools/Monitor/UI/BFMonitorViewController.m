//
//  BFMonitorViewController.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/20.
//

#import "BFMonitorViewController.h"
#import "BFFluencyMonitor.h"
#import "BFMonitorCache.h"

@interface BFMonitorViewController ()

@end

@implementation BFMonitorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = [NSString stringWithFormat:@"卡顿检测(%@)",[BFFluencyMonitor isOn] ? @"开" : @"关"];
    
    [self setUpSubViews];
}

- (void)setUpSubViews{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"delete"].original style:(UIBarButtonItemStyleDone) target:self action:@selector(removeMonitorData)];
    self.data = ((NSArray *)[BFMonitorCache monitorData]).reverseObjectEnumerator.allObjects;
    [self.tableView reloadData];
}

- (void)removeMonitorData{
    [BFMonitorCache removeMonitorData];
    self.data = [BFMonitorCache monitorData];
    [self.tableView reloadData];
}

- (NSString *)cellClass{
    return BFString.tc_monitor;
}

#pragma mark -- UITableViewDelegate,UITableViewDataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [BFRouter jumpUrl:BFString.vc_po_object params:@{@"object":self.data[indexPath.row]}];
}
@end
