//
//  BFDebugToolViewController.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/7.
//

#import "BFDebugToolViewController.h"
#import "BFDebugTool.h"

static NSString *identifier = @"BFDebugToolViewCell";
@interface BFDebugToolViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray <BFDebugToolModel *>*data;
//@property (nonatomic, copy) id block;
@end

@implementation BFDebugToolViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"DebugTool";
    [self setUpSubViews];
}

- (void)setUpSubViews{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"switch"].original style:(UIBarButtonItemStyleDone) target:self action:@selector(clickSwitchAction)];
    self.data = [BFDebugToolModel data];
    [self.collectionView reloadData];
}

- (void)clickSwitchAction{
    [BFRouter jumpUrl:BFString.vc_debug_switch];
}

///路由测试
+ (void)routerEntry{
   __block UIAlertController *alertController = [UIAlertController alertTitle:@"路由测试" message:nil cancel:@"取消" cancelBlock:^(NSString * _Nonnull cancel) {
       alertController = nil;
    } confirm:@"跳转" confirmBlock:^(NSUInteger index) {
        UITextField *textField = alertController.textFields.firstObject;
        [BFRouter jumpUrl:textField.text];
        alertController = nil;
    }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入url";
    }];
    [UIViewController.currentViewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UICollectionViewDelegate,UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.data.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    BFDebugToolViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    cell.model = self.data[indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    BFDebugToolModel *model = self.data[indexPath.row];
    id obj = model.url;
    if ([model.action isEqualToString:@"enviConfig:"]) {
        void (^block)(void) = ^{
            [self setUpSubViews];
        };
        obj = block;
        
        //self.block = block; //内存泄漏测试
    }
    if (model.target){
        [NSObject performTarget:model.target action:model.action object:obj];
    }else{
        [BFRouter jumpUrl:obj];
    }
}

- (UICollectionView *)collectionView{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        //最小行间距
        layout.minimumLineSpacing = 0;
        //最小列间距
        layout.minimumInteritemSpacing = 0;
        //item大小
        CGFloat width = self.view.width/4;
        layout.itemSize = CGSizeMake(width, width);
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        [_collectionView registerClass:NSClassFromString(identifier) forCellWithReuseIdentifier:identifier];
        [self.view addSubview:_collectionView];
    }
    return _collectionView;
}

@end


@interface BFDebugToolViewCell ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation BFDebugToolViewCell

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]){
        [self setUpSubViews];
    }
    return self;
}

- (void)setUpSubViews{
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.imageView];
    
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(0);
        make.width.height.mas_equalTo(34);
        make.top.mas_equalTo(15);
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(0);
        make.top.equalTo(self.imageView.mas_bottom).offset(6);
    }];
}

- (void)setModel:(BFDebugToolModel *)model{
    self.titleLabel.text = model.title;
    self.imageView.image = [UIImage imageNamed:model.image];
}

- (UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = UIFont.font16;
        _titleLabel.textColor = UIColor.c000000;
        _titleLabel.numberOfLines = 2;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UIImageView *)imageView{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
    }
    return _imageView;
}

@end


@implementation BFDebugToolModel

+ (NSArray *)data{
    NSString *envi = [NSString stringWithFormat:@"环境:%@",[NSObject performTarget:@"TPEnviConfig".classString action:@"enviToSting"]];

    NSMutableString *startTime = [NSMutableString stringWithString:@"启动时间:"];
    id value = [[NSUserDefaults standardUserDefaults] valueForKey:@"kBFStartupTimeKey"];
    if (value)[startTime appendString:[NSString stringWithFormat:@"%.3f",[value doubleValue]]];
   
    NSArray *data = @[
        @{@"title":startTime,@"image":@"startup"},
        @{@"title":@"路由",@"image":@"router",@"url":BFString.vc_router},
        @{@"title":envi,@"image":@"setting",@"target":@"TPEnviConfig".classString,@"action":@"enviConfig:"},
        
        @{@"title":@"app信息",@"image":@"appInfo",@"url":BFString.vc_app_info},
        @{@"title":@"app文件",@"image":@"file",@"url":BFString.vc_file},
        @{@"title":@"UserDefaults",@"image":@"data",@"url":BFString.vc_user_defaults},
        @{@"title":@"可用字体",@"image":@"font",@"url":BFString.vc_font},
        @{@"title":@"内存泄漏",@"image":@"leaks",@"url":BFString.vc_leaks},
        @{@"title":@"审核",@"image":@"confound",@"url":BFString.vc_confound},
        
        @{@"title":@"打印日志",@"image":@"log",@"url":BFString.vc_log},
        @{@"title":@"崩溃信息",@"image":@"crash",@"url":BFString.vc_crash},
        @{@"title":@"卡顿检测",@"image":@"caton",@"url":BFString.vc_monitor},
        @{@"title":@"网络数据",@"image":@"network",@"url":BFString.vc_network_monitor},
        @{@"title":@"视图数据",@"image":@"pointView",@"url":BFString.vc_fast_point},
        @{@"title":@"生成二维码",@"image":@"pointView",@"url":@"BFQRCodeViewController"},
    ];
    
    return [NSArray yy_modelArrayWithClass:[self class] json:data];
}

@end
