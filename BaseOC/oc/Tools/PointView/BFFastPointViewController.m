//
//  BFFastPointViewController.m
//  OCProject
//
//  Created by 王祥伟 on 2024/7/8.
//

#import "BFFastPointViewController.h"
#import "BFDebugTool.h"
@interface BFFastPointViewController ()

@end

@implementation BFFastPointViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"视图列表";
    [self setUpSubViews];
}

- (void)setUpSubViews{
    NSMutableArray *data = [NSMutableArray array];
    for (UIView *view in BFDebugTool.manager.targetView.allSubViews) {
        CGRect viewRect = [view.superview convertRect:view.frame toView:UIViewController.window];
        if (CGRectContainsPoint(viewRect, BFDebugTool.manager.targetPoint)){
            [data addObject:view];
        }
    }
    self.data = data;
    [self.tableView reloadData];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"图文" style:(UIBarButtonItemStyleDone) target:self action:@selector(filterImageOrText)];
}

- (void)filterImageOrText{
    NSMutableArray *data = [NSMutableArray array];
    for (UIView *view in self.data) {
        if ([view isKindOfClass:[UILabel class]] ||
            [view isKindOfClass:[UIButton class]] ||
            [view isKindOfClass:[UIImageView class]] ||
            [view isKindOfClass:[UITextView class]] ||
            [view isKindOfClass:[UITextField class]]) {
            [data addObject:view];
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
