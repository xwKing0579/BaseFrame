//
//  BFSpamCodeWordViewController.m
//  OCProject
//
//  Created by 王祥伟 on 2024/3/27.
//

#import "BFSpamCodeWordViewController.h"
#import "BFConfoundModel.h"
#import "BFSpamMethod.h"
@interface BFSpamCodeWordViewController ()

@end

@implementation BFSpamCodeWordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"检测所有符合条件单词";
    self.data = [BFConfoundModel data_code_word];
    [self.tableView reloadData];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"筛选" style:(UIBarButtonItemStyleDone) target:self action:@selector(clickFilterWordsAction)];
}

- (void)clickFilterWordsAction{
    [BFToastManager showLoading];
    
    BFConfoundSetting *set = BFConfoundSetting.sharedManager;
    if (set.path){
        [BFSpamMethod getWordsProjectPath:set.path ignoreDirNames:@[@"Pods"]];
        self.data = [BFConfoundModel data_code_word];
        [self.tableView reloadData];
        [BFToastManager hideLoading];
    }else{
        [BFToastManager showText:@"先设置项目绝对路径"];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellString = BFString.tc_spam_code_model;
    return [NSObject performTarget:cellString.classString action:[self actionString] object:tableView object:self.data[indexPath.row]] ?: [UITableViewCell new];
}

@end
