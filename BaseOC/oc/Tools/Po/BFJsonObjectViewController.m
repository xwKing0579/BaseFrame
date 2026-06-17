//
//  BFJsonObjectViewController.m
//  FXTP
//
//  Created by 王祥伟 on 2024/6/4.
//

#import "BFJsonObjectViewController.h"
#import "BFJsonObjectModel.h"
@interface BFJsonObjectViewController ()

@end

@implementation BFJsonObjectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"解析后数据";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"去解析" style:(UIBarButtonItemStyleDone) target:self action:@selector(toJsonText)];
    
    NSMutableArray *temp = [NSMutableArray array];
    if ([self.obj isKindOfClass:[NSDictionary class]]){
        NSDictionary *dic = (NSDictionary *)self.obj;
        for (NSString *key in dic.allKeys) {
            BFJsonObjectModel *model = [BFJsonObjectModel new];
            model.key = key;
            model.value = dic[key];
            [temp addObject:model];
        }
        self.data = temp;
    }else if ([self.obj isKindOfClass:[NSArray class]]){
        NSArray *arr = (NSArray *)self.obj;
        for (NSString *sting in arr) {
            BFJsonObjectModel *model = [BFJsonObjectModel new];
            model.value = sting;
            [temp addObject:model];
        }
    }
    self.data = temp;
    [self.tableView reloadData];
}

- (void)toJsonText{
    UIPasteboard *pastboard = [UIPasteboard generalPasteboard];
    NSString *content = pastboard.string;
    NSObject *obj;
    for (BFJsonObjectModel *model in self.data) {
        NSString *value = [NSString stringWithFormat:@"%@", model.value].whitespace;
        if ([value isEqualToString:content]){
            obj = model.value;
        }
    }
    [BFJsonObjectModel toJson:obj];
}

- (NSString *)cellClass{
    return BFString.tc_json_object;
}

@end
