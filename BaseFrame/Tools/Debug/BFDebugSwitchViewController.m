//
//  BFDebugSwitchViewController.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/28.
//

#import "BFDebugSwitchViewController.h"

@implementation BFDebugSwitchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"开关";
    self.data = @[@{@"打印日志":@"BFLogManager"},
                  @{@"崩溃信息":@"BFCrashManager"},
                  @{@"卡顿检测":@"BFFluencyMonitor"},
                  @{@"视图层级":@"BFUIHierarchyManager"},
                  @{@"开启防护":@"TPSafeObjectManager"}];
    [self.tableView reloadData];
}

- (NSString *)cellClass{
    return BFString.tc_debug_switch;
}

@end


@interface BFDebugSwitchTableViewCell ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UISwitch *switchView;
@property (nonatomic, strong) NSString *targetName;
@end

@implementation BFDebugSwitchTableViewCell

+ (instancetype)initWithTableView:(UITableView *)tableView withObject:(NSDictionary *)obj{
    BFDebugSwitchTableViewCell *cell = [self initWithTableView:tableView];
    cell.titleLabel.text = obj.allKeys.firstObject;
    cell.targetName = [NSString stringWithFormat:@"%@",obj.allValues.firstObject].classString;
    cell.switchView.on = [[NSObject performTarget:cell.targetName action:@"isOn"] boolValue];
    return cell;
}

- (void)setUpSubViews{
    [self.contentView addSubviews:@[self.titleLabel,self.lineView,self.switchView]];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.top.mas_equalTo(15);
        make.right.mas_equalTo(-90);
        make.bottom.mas_equalTo(-15);
    }];
    [self.lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(0);
        make.height.mas_equalTo(0.5);
    }];
    [self.switchView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(0);
        make.right.mas_equalTo(-10);
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(30);
    }];
}

- (void)clickSwitchAction:(UISwitch *)sender{
    [NSObject performTarget:self.targetName action:self.switchView.isOn ? @"start" : @"stop"];
}

- (UILabel *)titleLabel{
    if (!_titleLabel){
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = UIFont.font14;
        _titleLabel.textColor = UIColor.c333333;
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}

- (UIView *)lineView{
    if (!_lineView){
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = UIColor.cEEEEEE;
    }
    return _lineView;
}

- (UISwitch *)switchView{
    if (!_switchView){
        _switchView = [[UISwitch alloc] init];
        [_switchView addTarget:self action:@selector(clickSwitchAction:) forControlEvents:UIControlEventValueChanged];
    }
    return _switchView;
}

@end
