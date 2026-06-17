//
//  BFRouterViewController.m
//  QuShou
//
//  Created by 王祥伟 on 2024/4/8.
//

#import "BFRouterViewController.h"
#import "BFRouterModel.h"
@interface BFRouterViewController ()

@end

@implementation BFRouterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"页面跳转";
    NSString *path = @"/Users/wangxiangwei/Desktop/CashCeria/CashCeria/ConstString/BFString.h";
    NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSArray *vcs = [fileContent regexPattern:@"vc_([^;\n\r\f\t\v ]*);"];
    
    NSMutableSet *data = [NSMutableSet set];
    for (NSString *string in vcs) {
        if (![string hasPrefix:@"base"]){
            NSString *vcString = [NSString stringWithFormat:@"vc_%@",string];
            NSString *vcClass = [BFString performAction:vcString];
            [data addObject:[NSString stringWithFormat:@"%@(%@)",vcClass,vcString]];
        }
    }
    self.data = data.allObjects;
    [self.tableView reloadData];
}

#pragma mark -- UITableViewDelegate,UITableViewDataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *string = self.data[indexPath.row];
    NSString *vcString = [string componentsSeparatedByString:@"("].firstObject;
    
    if ([BFRouterModel.hfiles.allKeys containsObject:vcString]){
        NSString *path = BFRouterModel.hfiles[vcString];
        NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        NSArray *filter = [fileContent regexPattern:@"\\)(.*?)\\;"];
        
        if (filter.count){
            NSMutableArray *params = [NSMutableArray array];
            for (NSString *string in filter) {
                NSString *result = [string.whitespace stringByReplacingOccurrencesOfString:@"*" withString:@""];
                NSArray *arr = [result componentsSeparatedByString:@" "];
                BFRouterModel *model = BFRouterModel.new;
                model.ivar = arr.lastObject;
                model.property = arr.firstObject;
                [params addObject:model];
            }
            [BFRouter jumpUrl:BFString.vc_router_params params:@{@"url":vcString,@"data":params}];
            return;
        }
    }
    
    [BFRouter jumpUrl:vcString];
}

- (NSString *)cellClass{
    return BFString.tc_router;
}

@end
