//
//  BFSpamCodeModelTableViewCell.m
//  OCProject
//
//  Created by 王祥伟 on 2024/3/25.
//

#import "BFSpamCodeModelTableViewCell.h"
#import "BFConfoundModel.h"
#import "BFConfoundSetting.h"
@interface BFSpamCodeModelTableViewCell ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextField *textFiled;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) BFConfoundModel *model;
@end

@implementation BFSpamCodeModelTableViewCell

+ (instancetype)initWithTableView:(UITableView *)tableView withObject:(BFConfoundModel *)obj{
    BFSpamCodeModelTableViewCell *cell = [self initWithTableView:tableView];
    cell.titleLabel.text = obj.title;
    cell.textFiled.text = obj.content;
    cell.model = obj;
    NSLog(@"筛选结果===>>>>%@",obj.content);
    return cell;
}

- (void)setUpSubViews{
    [self.contentView addSubviews:@[self.titleLabel,self.textFiled,self.lineView]];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(0);
        make.left.mas_equalTo(15);
        make.width.mas_equalTo(88);
    }];
    [self.textFiled mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.titleLabel.mas_right).offset(8);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(15);
        make.bottom.mas_equalTo(-15);
    }];
    [self.lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(0);
        make.height.mas_equalTo(0.5);
    }];
}

- (void)textFieldDidChange:(UITextField *)textField{
    NSString *text = textField.text.whitespace;
    [BFConfoundModel editContent:text idStr:self.model.idStr];
    self.model.content = text;
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

- (UITextField *)textFiled{
    if (!_textFiled){
        _textFiled = [[UITextField alloc] init];
        _textFiled.textColor = UIColor.c333333;
        _textFiled.font = UIFont.font14;
        _textFiled.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 0)];
        _textFiled.leftViewMode = UITextFieldViewModeAlways;
        _textFiled.clearButtonMode = UITextFieldViewModeWhileEditing;
        UIImageView *rightView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        rightView.image = [UIImage imageNamed:@"edit"];
        _textFiled.rightView = rightView;
        _textFiled.rightViewMode = UITextFieldViewModeAlways;
        [_textFiled addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    }
    return _textFiled;
}

- (UIView *)lineView{
    if (!_lineView){
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = UIColor.cEEEEEE;
    }
    return _lineView;
}

@end

