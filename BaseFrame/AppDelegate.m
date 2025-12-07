//
//  AppDelegate.m
//  BaseFrame
//
//  Created by 王祥伟 on 2024/7/30.
//

#import "AppDelegate.h"
#import "UIDevice+Memory.h"
#import "UIDevice+UniversalMethod.h"

#import "BFHunxiaoTool.h"
#import "BFGrabWordsTool.h"
#import "BFFileContentTool.h"
#import "UIImage+Confusion.h"

#import "BFConfuseManager.h"
#import "BFConfuseProject.h"
#import "BFConfuseFile.h"
#import "BFConfuseDirectory.h"
#import "BFConfuseMethod.h"
#import "BFConfuseProperty.h"
#import "BFConfuseVariable.h"
#import "BFConfuseImage.h"
#import "BFConfuseMarker.h"
#import "BFChineseStringFinder.h"
#import "BFWordCheckTool.h"
#import "BFConstantString.h"
#import "BFConfuseModel.h"
#import "BFConfusePBXUUID.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (void)checkTool:(NSString *)directory{
    //查出重复的字符串
    [self chaChongInAllWords2];
    
    //    [BFConfuseDirectory calculateAndPrintDirectorySizes:directory];
    //类名
//    NSArray *fileList = [BFConfuseFile getTotalControllersInDirectory:directory];
//    NSLog(@"%@",fileList);
    
    //方法名
//    NSArray *methodList = [BFConfuseMethod extractAllMethodNamesFromProject:directory];
//    NSLog(@"%@",methodList);
    
    //常量字符串
//    NSArray *constantList = [BFConstantString findMacrosInProjectPath:directory];
//    NSLog(@"%@",constantList);
    
//        NSDictionary *dict = [BFConstantString mapConstantStringDict103];
//        [BFConfuseMethod detectMultipleSettersInProject:directory propertyNames:dict.allKeys excludeFolders:@[@"Pods"]];
//        NSLog(@"%ld - %ld",dict.allKeys.count, [NSMutableSet setWithArray:dict.allKeys].allObjects.count);
//        for (NSString *key in dict.allKeys) {
//            if ([BFConfuseMethod.sysMethodList containsObject:key]){
//                NSLog(@"========+>>>>>> 白名单  %@",key);
//            }
//        }
    
//    NSArray *wordList = [BFConfuseManager detectStringsInDirectory:directory targetStrings:BFConfuseMethod.mapMethodDict103.allKeys];
//    NSLog(@"%@",wordList);
    
//    NSArray *list = @[@"qmuictl_",@"qmui_",@"qbt_",@"qimgv_",@"qwsm_",@"qcl_",@"qmuiTheme_"];
//    NSLog(@"%@",[BFConfuseManager searchFilesInDirectory:directory matchingPrefixes:list]);
    
//    NSArray *imageList = [BFConfuseImage allAssetFilenamesInProject:directory];
//    NSLog(@"%@",imageList);
    
//    [BFConfuseImage replaceImagesFromDirectoryA:@"/Users/wangxiangwei/Desktop/icon调整" toDirectoryB:directory];
    
//    [BFConfuseImage findUnusedImagesInProject:directory excludeDirs:@[] shouldDelete:YES];
    
//    [BFConfuseImage removeAt1xSuffixFromImagesInDirectory:@"/Users/wangxiangwei/Desktop/社交/yayj_副本/yayj/XYAssetCollection/Assets.xcassets"];
    
    //代码对齐
//    [BFCodeFormatter formatProjectAtPath:directory];
    

//    NSLog(@"%@",[BFUnusedFileFinder findUnusedFilesInProject:directory]);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [NSObject performTarget:BFString.bf_debug_tool.classString action:@"start"];
    NSDictionary *atsSettings = @{
          @"NSAllowsArbitraryLoads": @(1)
      };
      [[NSUserDefaults standardUserDefaults] setObject:atsSettings forKey:@"NSAppTransportSecurity"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self testWithNativeNSURLSession];
    });
    NSString *directory = @"/Users/wangxiangwei/Desktop/reader/bookios_副本";
//    NSString *directory = @"/Users/wangxiangwei/Desktop/test";
//        [UIImage processProjectImagesAtPath:directory intensity:0.1];
    //检查工具
//    [self checkTool:directory];
    

//    NSLog(@"%@",[BFConfuseModel extractModelPropertiesFromProjectPath:directory pathWhitelist:@[] pathBlacklist:@[@"Pods"]]);
    
    
//        [BFConfuseProject renameProjectAtPath:directory oldName:@"DeepBooks" newName:@"JingYueGe"];
    
//        [BFConfuseDirectory processProjectAtPath:directory renameMapping:BFConfuseDirectory.dict2];
    
//          [BFConfuseModel auditAndFixProjectAtPath:directory propertyMappings:BFConfuseModel.mapModelDict2 whitelistedPods:@[@"Pods"]]; //需要放在前面，因为是根据Model后缀判断数据模型的
    
//        [BFConfuseFile replaceInDirectory:directory replaceDict:BFConfuseFile.fileMapping3];
    
//            [BFConfuseMethod safeReplaceContentInDirectory:directory excludeDirs:@[@"Pods"] renameMapping:BFConfuseMethod.mapMethodDict4];
    
//        [BFConfuseProperty safeReplaceContentInDirectory:directory renameMapping:BFConfuseProperty.mapPropertyDict4];
    
//        [BFConfuseVariable safeReplaceContentInDirectory:directory renameMapping:BFConfuseVariable.mapVariableDict4];
    
//        [BFConfuseVariable safeReplaceContentInDirectory:directory renameSetMapping:BFConfuseVariable.mapSetVariableDict4];
    
//        [BFConstantString replaceStringsInProjectAtPath:directory];
//        [BFConstantString safeReplaceContentInDirectory:directory renameMapping:BFConstantString.mapConstantStringDict4];
    
//        [BFConfuseImage renameImageAssetsAndCodeReferencesInProject:directory renameMapping:BFConfuseImage.mapImageDict4];
    
//        [BFConfuseFile globalReplaceInDirectory:directory oldName:@"DBKit" newName:@"YueGeJing"];
    
//        [BFConfuseProperty insertRandomPropertiesInDirectory:directory namePool:BFWordsRackTool.propertyNames averageCount:9];
    
      //插入随机方法
//    [BFConfuseMethod injectRandomCodeToExistingMethodsInPath:directory];
    
//        [BFConfuseMarker deleteCommentsInDirectory:directory ignoreDirNames:@[@"Pods",@"LEEAlert"]];
    
//        [BFConfuseMarker addCommentsToProjectAtPath:directory];
    
//        [BFConfusePBXUUID obfuscateUUIDsInProjectAtPath:directory];
    
    /*
     
     //检测混淆命名是否重复，丢失等问题
     [BFWordCheckTool checkNewDict:BFConfuseFile.fileMapping oldDict:BFConfuseFile.fileMapping2];
     
     
     //修改工程名
     [BFConfuseProject renameProjectAtPath:directory oldName:@"DeepBooks" newName:@"XXSmallHouse"];
     
     
     //修改目录名
     [BFConfuseDirectory processProjectAtPath:directory renameMapping:BFConfuseDirectory.dict];
     
     
     //类名 并存储对应映射文件.txt
     [BFConfuseFile replaceInDirectory:directory replaceDict:BFConfuseFile.fileMapping];
     
     //类别名 特殊处理
     [BFConfuseFile globalReplaceInDirectory:directory oldName:@"DBKit" newName:@"XXSmall"];
     
     //检查需要替换的方法名
     NSArray *methodList = [BFConfuseMethod extractMethodNamesFromProjectPath:directory];
     NSArray *list = [BFConfuseMethod retainsFilterin:methodList];
     //方法名 替换
     [BFConfuseMethod safeReplaceContentInDirectory:directory excludeDirs:@[@"Pods"] renameMapping:BFConfuseMethod.mapMethodDict];
     
     //属性名 替换
     [BFConfuseProperty safeReplaceContentInDirectory:directory renameMapping:BFConfuseProperty.mapPropertyDict];
     
     //变量名 替换1
     [BFConfuseVariable safeReplaceContentInDirectory:directory renameMapping:BFConfuseVariable.mapVariableDict];
     
     //变量名 set替换2
     [BFConfuseVariable safeReplaceContentInDirectory:directory renameMapping:BFConfuseVariable.mapSetVariableDict];
     
     //常量字符串 替换
     [BFConstantString safeReplaceContentInDirectory:directory renameMapping:BFConstantString.mapConstantStringDict];
     
     //添加随机模型属性
     [BFConfuseProperty insertRandomPropertiesInDirectory:directory namePool:BFWordsRackTool.propertyNames averageCount:18];
     
     //图片名 替换
     [BFConfuseImage renameImageAssetsAndCodeReferencesInProject:directory renameMapping:BFConfuseImage.mapImageDict];
     
     //删除所有注释
     [BFConfuseMarker deleteCommentsInDirectory:directory ignoreDirNames:@[@"Pods",@"DBSDKModule"]];
     
     //添加随机注释
     [BFConfuseMarker addCommentsToProjectAtPath:directory];
     
     
     
     
     //添加注释
     //NSArray *methodList = [BFConfuseMethod extractMethodNamesFromProjectPath:directory]; //这个方法是获取所有方法名 - (void)xxx
     [BFConfuseMarker processProjectPath:directory excludeDirs:@[@"Pods"] methodComments:BFConfuseMarker.markDict];
     
     //先去掉属性行尾部注释
     [BFConfuseMarker cleanSemicolonCommentsInProject:directory];
     
     //检索中文
     [BFChineseStringFinder findChineseStringsInDirectory:directory];
     */
    

    return YES;
}

- (void)testWithNativeNSURLSession {
    NSURL *url = [NSURL URLWithString:@"http://42fd10627po1.vicp.fun:14120/enterprise/helpInterface/getMessage"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    // 设置方法为POST
    request.HTTPMethod = @"POST";
    
    // 完全复制WKWebView的请求头
    [request setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"zh-CN,zh;q=0.9" forHTTPHeaderField:@"Accept-Language"];
    [request setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    
    // 设置参数
    NSString *postString = @"mobilePhone=17521000579&type=10"; // 你的参数
    request.HTTPBody = [postString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"❌ 原生NSURLSession失败: %@", error);
        } else {
            NSLog(@"✅ 原生NSURLSession成功");
            NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"响应: %@", responseString);
        }
    }];
    [task resume];
}
- (void)testGETRequest {
    NSDictionary *parameters = @{@"mobilePhone":@"17521000579",@"type":@"10"};
    
    // 构建带参数的URL
    NSString *baseURL = @"http://42fd10627po1.vicp.fun:40739/enterprise/helpInterface/getMessage";
    NSString *urlWithParams = [self buildURLWithBase:baseURL parameters:parameters];
    
    NSURL *url = [NSURL URLWithString:urlWithParams];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    // 添加浏览器相同的Header
    [request setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"❌ GET请求失败: %@", error);
        } else {
            NSLog(@"✅ GET请求成功!");
            NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"响应: %@", responseString);
            
            // 如果GET成功，说明服务器要求GET而不是POST
            if (responseString) {
               
            }
        }
    }];
    [task resume];
}

// 构建带参数的URL
- (NSString *)buildURLWithBase:(NSString *)baseURL parameters:(NSDictionary *)parameters {
    if (!parameters || parameters.count == 0) {
        return baseURL;
    }
    
    NSMutableArray *queryItems = [NSMutableArray array];
    for (NSString *key in parameters.allKeys) {
        NSString *value = [parameters[key] description];
        NSString *encodedKey = [key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSString *encodedValue = [value stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [queryItems addObject:[NSString stringWithFormat:@"%@=%@", encodedKey, encodedValue]];
    }
    
    NSString *queryString = [queryItems componentsJoinedByString:@"&"];
    
    // 检查原URL是否已经有参数
    if ([baseURL containsString:@"?"]) {
        return [NSString stringWithFormat:@"%@&%@", baseURL, queryString];
    } else {
        return [NSString stringWithFormat:@"%@?%@", baseURL, queryString];
    }
}

- (void)chaChongInAllWords{
    NSMutableSet *allWords = [NSMutableSet set];
    [BFConfuseDirectory.dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([allWords containsObject:key]){
            NSLog(@"==========>>>>>>>>>>>已包含key %@",key);
        }else{
            [allWords addObject:key];
        }
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    
    
    [BFConfuseFile.fileMapping1 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([allWords containsObject:key]){
            NSLog(@"==========>>>>>>>>>>>已包含key %@",key);
        }else{
            [allWords addObject:key];
        }
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    [BFConfuseFile.fileMapping2 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    [BFConfuseFile.fileMapping3 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    
    
    [BFConfuseMethod.mapMethodDict1 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    [BFConfuseMethod.mapMethodDict2 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    [BFConfuseMethod.mapMethodDict4 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    
    
    [BFConfuseProperty.mapPropertyDict1 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([allWords containsObject:key]){
            NSLog(@"==========>>>>>>>>>>>已包含key %@",key);
        }else{
            [allWords addObject:key];
        }
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    [BFConfuseProperty.mapPropertyDict2 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    [BFConfuseProperty.mapPropertyDict4 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    
    [BFConfuseVariable.mapVariableDict1 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([allWords containsObject:key]){
            NSLog(@"==========>>>>>>>>>>>已包含key %@",key);
        }else{
            [allWords addObject:key];
        }
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    [BFConfuseVariable.mapVariableDict4 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    
    [BFConfuseVariable.mapSetVariableDict1 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([allWords containsObject:key]){
            NSLog(@"==========>>>>>>>>>>>已包含key %@",key);
        }else{
            [allWords addObject:key];
        }
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    [BFConfuseVariable.mapSetVariableDict4 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    
    [BFConstantString.mapConstantStringDict1 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([allWords containsObject:key]){
            NSLog(@"==========>>>>>>>>>>>已包含key %@",key);
        }else{
            [allWords addObject:key];
        }
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    [BFConstantString.mapConstantStringDict4 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    
    [BFConfuseImage.mapImageDict1 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    [BFConfuseImage.mapImageDict4 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    
    [BFConfuseModel.mapModelDict1 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    [BFConfuseModel.mapModelDict2 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
}

- (void)chaChongInAllWords2{
    NSMutableSet *allWords = [NSMutableSet set];
    [BFConfuseFile.fileMapping102 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([allWords containsObject:key]){
            NSLog(@"==========>>>>>>>>>>>已包含key %@",key);
        }else{
            [allWords addObject:key];
        }
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    [BFConfuseFile.fileMapping103 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    
    [BFConfuseVariable.mapSetVariableDict102 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([allWords containsObject:key]){
            NSLog(@"==========>>>>>>>>>>>已包含key %@",key);
        }else{
            [allWords addObject:key];
        }
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    [BFConfuseVariable.mapSetVariableDict103 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    
    [BFConfuseMethod.mapMethodDict103 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([allWords containsObject:key]){
            NSLog(@"==========>>>>>>>>>>>已包含key %@",key);
        }else{
            [allWords addObject:key];
        }
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    
    [BFConstantString.mapConstantStringDict103 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([allWords containsObject:key]){
            NSLog(@"==========>>>>>>>>>>>已包含key %@",key);
        }else{
            [allWords addObject:key];
        }
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    
    [BFConfuseModel.mapModelDict103 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([allWords containsObject:key]){
            NSLog(@"==========>>>>>>>>>>>已包含key %@",key);
        }else{
            [allWords addObject:key];
        }
        if ([obj length] > 0){
            if ([allWords containsObject:obj]){
                NSLog(@"==========>>>>>>>>>>>已包含value %@",obj);
            }else{
                [allWords addObject:obj];
            }
        }
    }];
    
}

NSDictionary *processDictionaries(NSDictionary *dictA, NSDictionary *dictB) {
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
    NSMutableDictionary *nonEmptyValues = [NSMutableDictionary dictionary];
    
    // 获取字典B的所有key
    NSArray *keysB = [dictB allKeys];
    
    // 处理每个键
    for (NSString *key in keysB) {
        id value = dictA[key]; // 检查字典A中是否有这个key
        if (value) {
            nonEmptyValues[key] = value; // 使用字典A的值
        } else {
            resultDict[key] = @""; // 设为空字符串
        }
    }
    
    // 将非空值添加到结果字典
    [resultDict addEntriesFromDictionary:nonEmptyValues];
    
    return [resultDict copy];
}

#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
