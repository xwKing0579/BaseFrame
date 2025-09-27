//
//  BFRouterParamsViewController.m
//  QuShou
//
//  Created by 王祥伟 on 2024/4/25.
//

#import "BFRouterParamsViewController.h"
#import "BFRouterModel.h"

@interface BFRouterParamsViewController ()
@property (nonatomic, copy) NSString *url;
@property (nonatomic, strong) NSArray *params;
@end

@implementation BFRouterParamsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"配置参数";
    if (!self.params) self.params = self.data;
    [self setRouterValue];
    [self.tableView reloadData];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"跳转页面" style:(UIBarButtonItemStyleDone) target:self action:@selector(clickJumpAction)];
}

- (void)setRouterValue{
    for (BFRouterModel *model in self.data) {
        Class class = NSClassFromString(model.property);
        if (class){
            NSObject *obj = [class performAction:@"new"];
            if ([obj isKindOfClass:[NSString class]]){
                model.value = @"";
            }else if ([obj isKindOfClass:[NSArray class]]){
                model.value = @[];
            }else if ([obj isKindOfClass:[NSDictionary class]]){
                model.value = @{};
            }else{
                unsigned int propertyCount;
                objc_property_t *properties = class_copyPropertyList(class, &propertyCount);
                NSMutableArray *params = [NSMutableArray array];
                for (unsigned int i = 0; i < propertyCount; i++) {
                    objc_property_t property = properties[i];
                    NSString *key = [NSString stringWithUTF8String:property_getName(property)];
                    BFRouterModel *item = BFRouterModel.new;
                    item.ivar = key;
                    NSString *propertyString = [NSString stringWithFormat:@"%s",property_getAttributes(properties[i])];
                    item.property = [propertyString regexPattern:@"@\"(.*?)\""].firstObject?:propertyString;
                    [params addObject:item];
                }
                free(properties);
                model.value = obj;
                model.params = params;
            }
        }else{
            model.value = @"0";
        }
    }
}

- (void)clickJumpAction{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (BFRouterModel *model in self.params) {
        [self remunedParams:model.params obj:model.value];
        [params setValue:model.value forKey:model.ivar];
    }
    [BFRouter jumpUrl:self.url params:params];
}

- (void)remunedParams:(NSArray *)params obj:(id)obj{
    for (BFRouterModel *item in params) {
        if (item.value) [obj setValue:item.value forKey:item.ivar];
        [self remunedParams:item.params obj:item.value];
    }
}

- (NSString *)cellClass{
    return BFString.tc_router_params;
}

#pragma mark -- UITableViewDelegate,UITableViewDataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    BFRouterModel *model = self.data[indexPath.row];
    if (model.params.count){
        [BFRouter jumpUrl:BFString.vc_router_params params:@{@"url":self.url,@"data":model.params,@"params":self.params}];
    }
}


@end
