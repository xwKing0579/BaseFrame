//
//  BFRouterParamsTableViewCell.m
//  QuShou
//
//  Created by 王祥伟 on 2024/4/25.
//

#import "BFRouterParamsTableViewCell.h"
#import "BFRouterModel.h"
@interface BFRouterParamsTableViewCell ()<UITextViewDelegate>
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) UIView *lineView;

@property (nonatomic, strong) BFRouterModel *model;
@end

@implementation BFRouterParamsTableViewCell

+ (instancetype)initWithTableView:(UITableView *)tableView withObject:(BFRouterModel *)model{
    BFRouterParamsTableViewCell *cell = [self initWithTableView:tableView];
    cell.model = model;
    cell.titleLabel.text = model.ivar;
    cell.contentLabel.text = model.property;
    cell.textView.text = [model.value description];
    cell.arrowImageView.hidden = !model.params.count;
    cell.textView.userInteractionEnabled = !model.params.count;
    return cell;
}

- (void)textViewDidChange:(UITextView *)textView{
    self.model.value = textView.text.whitespace;
    [UIViewController.currentViewController performAction:@""];
}

- (void)setUpSubViews{
    [self.contentView addSubviews:@[self.titleLabel,self.contentLabel,self.textView,self.lineView,self.arrowImageView]];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(30);
        make.bottom.mas_equalTo(-30);
        make.left.mas_equalTo(15);
        make.width.mas_equalTo(60);
    }];
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(0);
        make.left.mas_equalTo(self.titleLabel.mas_right).offset(10);
        make.width.mas_equalTo(90);
    }];
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.contentLabel.mas_right).offset(10);
        make.right.mas_equalTo(-30);
        make.top.bottom.mas_equalTo(0);
    }];
    [self.arrowImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(0);
        make.right.mas_equalTo(-10);
        make.width.mas_equalTo(8);
        make.height.mas_equalTo(12);
    }];
    [self.lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(0);
        make.height.mas_equalTo(0.5);
    }];
}

- (UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = UIFont.font14;
        _titleLabel.textColor = UIColor.c000000;
        _titleLabel.numberOfLines = 3;
    }
    return _titleLabel;
}

- (UILabel *)contentLabel{
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = UIFont.font14;
        _contentLabel.textColor = UIColor.c000000;
        _contentLabel.numberOfLines = 3;
    }
    return _contentLabel;
}

- (UITextView *)textView{
    if (!_textView){
        _textView = [[UITextView alloc] init];
        _textView.backgroundColor = UIColor.cFFFFFF;
        _textView.textContainerInset = UIEdgeInsetsMake(15, 15, 15, 15);
        _textView.textColor = UIColor.c000000;
        _textView.font = UIFont.font14;
        _textView.delegate = self;
        _textView.returnKeyType = UIReturnKeyDone;
    }
    return _textView;
}

- (UIView *)lineView{
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = UIColor.cEEEEEE;
    }
    return _lineView;
}

- (UIImageView *)arrowImageView{
    if (!_arrowImageView){
        _arrowImageView = [[UIImageView alloc] init];
        _arrowImageView.image = [UIImage imageNamed:@"arrow"];
    }
    return _arrowImageView;
}
@end
