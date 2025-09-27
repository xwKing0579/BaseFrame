//
//  BFConfoundViewController.m
//  OCProject
//
//  Created by 王祥伟 on 2024/3/22.
//

#import "BFConfoundViewController.h"
#import "BFConfoundModel.h"
#import "BFSpamMethod.h"
#import "BFModifyProject.h"

#import "BFHunxiaoTool.h"
@interface BFConfoundViewController ()<UITextViewDelegate>
@property (nonatomic, strong) UITextView *textView;
@end

@implementation BFConfoundViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"马甲包工具";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"开始" style:(UIBarButtonItemStyleDone) target:self action:@selector(startConfoundAction)];
    BFConfoundSetting.sharedManager.path = @"/Users/wangxiangwei/Desktop/test";
    self.data = [BFConfoundModel data];
    [self.tableView reloadData];
    
}

- (void)startConfoundAction{
    BFConfoundSetting *set = BFConfoundSetting.sharedManager;
    BFSpamCodeSetting *codeSet = set.spamSet;
    BFSpamCodeFileSetting *fileSet = codeSet.spamFileSet;
    BFModifyProjectSetting *modifySet = set.modifySet;
//    modifySet.oldName = @"TiaoPiChat";
//    modifySet.modifyName = @"SCodeProject";
    NSString *path = set.path;
    if (!path.length) {
        [BFToastManager showText:@"请输入绝对路径"];
        return;
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]){
        [BFToastManager showText:@"路径不对，没找到文件"];
        return;
    }
    
    if (set.isModifyProject && (!modifySet.oldName.length || !modifySet.modifyName.length)){
        [BFToastManager showText:@"请填写修改项目名称的内容"];
        return;
    }
    
    if (set.isModifyClass && (!modifySet.oldPrefix.length || !modifySet.modifyPrefix.length)){
        [BFToastManager showText:@"请填写修改类名称前缀的内容"];
        return;
    }
    [BFToastManager showLoading];
    
    NSArray *ignoreDirNames = @[@"Pods",@"pch"];
    
 
    ///垃圾代码
    if (set.isSpam) {
        if (codeSet.isSpamOldWords){
            [BFSpamMethod getWordsProjectPath:path ignoreDirNames:ignoreDirNames];
        }
        NSString *dirPath;
        if (set.spamSet.isSpamInNewDir){
            dirPath = [path stringByAppendingPathComponent:set.spamSet.spamFileSet.dirName];
            if (![fm fileExistsAtPath:dirPath]){
                NSError *error = nil;
                [fm createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error];
                if (error){
                    [BFToastManager showText:@"创建文件夹失败"];
                    [BFToastManager hideLoading];
                    return;
                }
            }
            
            NSSet *result = [BFSpamMethod combinedWords:codeSet.combinedWords minLen:2 maxLen:3 count:fileSet.spamFileNum];
            NSString *importFile = @"";
            for (NSString *name in result.allObjects) {
                
                //后缀
                NSArray *classArr = @[@"NSObject",@"UIView",@"UIViewController",@"UIButton",@"UILabel",@"UITextView",@"UITextField",@"UIImageView",@"UIControl",@"UIImage",@"UIAlertController",@"UIColor",@"UIFont",@"UISwitch",@"UISearchBar",@"UINavigationBar",@"UISegmentedControl",@"UIScreen",@"UITableViewCell",@"UICollectionViewCell",@"UIScrollView",@"UIPickerView",@"UICollectionView",@"UIDevice",@"NSData",@"NSDate",@"NSString",@"NSArray",@"NSMutableString",@"NSMutableArray",@"NSDictionary",@"NSMutableDictionary",@"NSSet",@"NSMutableSet",@"NSNumber",@"NSURL",@"NSOperation",@"NSFileManager",@"NSBundle"];
                
                NSString *classString = classArr[arc4random()%classArr.count];
                NSString *className = [classString stringByReplacingOccurrencesOfString:@"UI" withString:@""];
                className = [className stringByReplacingOccurrencesOfString:@"NS" withString:@""];
                if ([classString isEqualToString:@"NSObject"]){
                    className = @"Model";
                }
                
                NSString *nameString = [name stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[name substringToIndex:1] uppercaseString]];
                NSString *fileName = [NSString stringWithFormat:@"%@%@%@",codeSet.isSpamMethod ? safeString(fileSet.spamClassPrefix) : @"",nameString,className];
                importFile = [importFile stringByAppendingString:[NSString stringWithFormat:@"#import \"%@.h\"\n",fileName]];
                NSString *filePathHead = [dirPath stringByAppendingPathComponent:fileName];
                NSArray *files = @[[filePathHead stringByAppendingString:@".h"],[filePathHead stringByAppendingString:@".m"]];
                
                for (NSString *filePath in files) {
                    if ([fm fileExistsAtPath:filePath]){
                        continue;
                    }
                    NSString *string = fileSet.spammFileContent;
                    if ([filePath hasSuffix:@".h"]){
                        string =  fileSet.spamhFileContent;
                        string = [string stringByReplacingOccurrencesOfString:@"UIView" withString:classString];
                        if ([classString isEqualToString:@"NSObject"]){
                            string = [string stringByReplacingOccurrencesOfString:@"UIKit/UIKit" withString:@"Foundation/Foundation"];
                        }
                    }
                    string = [string stringByReplacingOccurrencesOfString:@"file" withString:fileName];
                    int macr = arc4random()%12+1;
                    int arc = arc4random()%28;
                    string = [string stringByReplacingOccurrencesOfString:@"date" withString:[NSString stringWithFormat:@"2024/%02d/%2d",macr,arc]];
                    [string writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
                }
            }
            NSString *importPath = [dirPath stringByAppendingPathComponent:fileSet.dirName];
            importPath = [importPath stringByAppendingString:@".h"];
            if ([fm fileExistsAtPath:importPath]){
                NSError *error = nil;
                NSMutableString *content = [NSMutableString stringWithContentsOfFile:importPath encoding:NSUTF8StringEncoding error:&error];
                importFile = [content stringByAppendingString:importFile];
            }else{
                importFile = [fileSet.spamFileDesContent stringByAppendingString:importFile];
            }
            [importFile writeToFile:importPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
        
        NSString *projectPath = codeSet.isSpamInOldCode ? path : dirPath;
        [BFSpamMethod spamCodeProjectPath:projectPath ignoreDirNames:ignoreDirNames];
    }
    
    //修改项目名称
    if (set.isModifyProject){
        //[BFModifyProject modifyProjectName:path oldName:modifySet.oldName newName:modifySet.modifyName];
        [BFHunxiaoTool renameProjectAtPath:path fromOldName:modifySet.oldName toNewName:modifySet.modifyName error:nil];
    }
    
    ///修改文件前缀
    if (set.isModifyClass){
        [BFModifyProject modifyFilePrefix:path otherPrefix:modifySet.isModifyPrefixOther oldPrefix:modifySet.oldPrefix newPrefix:modifySet.modifyPrefix];
    }
    
    //删除注释
    if (set.isClearComment){
        [BFModifyProject clearCodeComment:path ignoreDirNames:ignoreDirNames];
    }
    
    //方法名替换
    if (set.isMethodConfusion){
        
    }
    
    [BFToastManager hideLoading];
}

- (NSString *)cellClass{
    return BFString.tc_confound;
}

#pragma mark -- UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView{
    NSString *path = textView.text.whitespace;
    
    BFConfoundSetting *set = BFConfoundSetting.sharedManager;
    set.path = path;
}

#pragma mark -- UITableViewDelegate,UITableViewDataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    BFConfoundModel *model = self.data[indexPath.row];
    [BFRouter jumpUrl:model.url];
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, UIDevice.width, 80)];
    
    UITextView *textView = [[UITextView alloc] init];
    textView.font = UIFont.font14;
    textView.textColor = UIColor.c000000;
    textView.layer.masksToBounds = YES;
    textView.layer.borderColor = UIColor.cBFBFBF.CGColor;
    textView.layer.borderWidth = 0.5;
    textView.placeholder = @"输入文件夹绝对路径";
    textView.contentInset = UIEdgeInsetsMake(15, 15, 15, 15);
    textView.delegate = self;
    textView.text = BFConfoundSetting.sharedManager.path;
    [view addSubview:textView];
    self.textView = textView;
    
    [textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 80;
}

@end
