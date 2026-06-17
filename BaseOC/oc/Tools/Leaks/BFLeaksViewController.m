//
//  BFLeaksViewController.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/22.
//

#import "BFLeaksViewController.h"
#import "MLeaksMessenger.h"
@interface BFLeaksViewController ()
@end

@implementation BFLeaksViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"内存泄漏";
    
    NSMutableArray *data = [NSMutableArray array];
    for (NSNumber *num in [MLeaksMessenger leaks]) {
        NSString *ptr = [[NSString alloc] initWithFormat:@"0x%llx",num.unsignedLongLongValue];
        uintptr_t hex = strtoull(ptr.UTF8String, NULL, 0);
        @try {
            id obj = (__bridge id)(void *)hex;
            if (obj) [data addObject:obj];
        } @catch (NSException *exception) {
            
        } @finally {
            
        }
    }
    self.data = data;
    [self.tableView reloadData];
}

- (NSString *)cellClass{
    return BFString.tc_leaks;
}

#pragma mark -- UITableViewDelegate,UITableViewDataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [BFRouter jumpUrl:BFString.vc_po_object params:@{@"object":self.data[indexPath.row]}];
}

@end
