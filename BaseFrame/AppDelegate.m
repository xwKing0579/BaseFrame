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
#import "UIImage+Compare.h"

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
    [self chaChongInAllWords];
    
//    [BFConfuseDirectory calculateAndPrintDirectorySizes:directory];
    //类名
//    NSArray *fileList = [BFConfuseFile getTotalControllersInDirectory:directory];
//    NSLog(@"%@",fileList);
    
    //方法名
//    NSArray *fileList = [BFConfuseMethod extractAllMethodNamesFromProject:directory];
 
    
//    NSDictionary *dict = [BFConfuseMethod mapMethodDict100];
//    NSLog(@"%ld - %ld",dict.allKeys.count, [NSMutableSet setWithArray:dict.allKeys].allObjects.count);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [NSObject performTarget:BFString.bf_debug_tool.classString action:@"start"];

  
    NSString *directory = @"/Users/wangxiangwei/Desktop/社交/yueyixinban_副本/YueYiYis";
//    NSString *directory = @"/Users/wangxiangwei/Desktop/大图_副本";
//    [UIImage processProjectImagesAtPath:directory intensity:1.0];
    //检查工具
//    [self checkTool:directory];
    

//    //处理缺失的值
//    NSDictionary *originalDict = processDictionaries(BFConfuseProperty.mapPropertyDict1, BFConfuseProperty.mapPropertyDict);
//    NSMutableDictionary *emptyValuesDict = [NSMutableDictionary dictionary];
//    NSMutableDictionary *nonEmptyValuesDict = [NSMutableDictionary dictionary];
//
//    // 遍历原字典，分离空值和非空值
//    [originalDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
//        if (obj == nil || obj == [NSNull null] || ([obj isKindOfClass:[NSString class]] && [obj isEqualToString:@""])) {
//            emptyValuesDict[key] = obj;
//        } else {
//            nonEmptyValuesDict[key] = obj;
//        }
//    }];
//
//    NSLog(@"%@", emptyValuesDict);
//    NSLog(@"%@", nonEmptyValuesDict);
    
    
//    NSLog(@"%@",[BFConfuseModel extractModelPropertiesFromProjectPath:directory pathWhitelist:@[] pathBlacklist:@[@"Pods"]]);
    
    
//    [BFConfuseProject renameProjectAtPath:directory oldName:@"DeepBooks" newName:@"YueGeJing"];
//    [BFConfuseDirectory processProjectAtPath:directory renameMapping:BFConfuseDirectory.dict2];
//      [BFConfuseModel auditAndFixProjectAtPath:directory propertyMappings:BFConfuseModel.mapModelDict2 whitelistedPods:@[@"Pods"]]; //需要放在前面，因为是根据Model后缀判断数据模型的
//    [BFConfuseFile customReplaceInDirectory:directory replaceDict:BFConfuseFile.fileMapping102];
//    [BFConfuseMethod safeReplaceContentInDirectory:directory excludeDirs:@[@"Pods"] renameMapping:BFConfuseMethod.mapMethodDict102];
//    [BFConfuseProperty safeReplaceContentInDirectory:directory renameMapping:BFConfuseProperty.mapPropertyDict4];
//    [BFConfuseVariable safeReplaceContentInDirectory:directory renameMapping:BFConfuseVariable.mapVariableDict4];
//    [BFConfuseVariable safeReplaceContentInDirectory:directory renameSetMapping:BFConfuseVariable.mapSetVariableDict4];
////    [BFConstantString replaceStringsInProjectAtPath:directory];
//    [BFConstantString safeReplaceContentInDirectory:directory renameMapping:BFConstantString.mapConstantStringDict4];
//    [BFConfuseImage renameImageAssetsAndCodeReferencesInProject:directory renameMapping:BFConfuseImage.mapImageDict4];
//    [BFConfuseFile globalReplaceInDirectory:directory oldName:@"DBKit" newName:@"YueGeJing"];
//    [BFConfuseProperty insertRandomPropertiesInDirectory:directory namePool:BFWordsRackTool.propertyNames averageCount:33];
//    [BFConfuseMarker deleteCommentsInDirectory:directory ignoreDirNames:@[@"Pods",@"LEEAlert"]];
//    [BFConfuseMarker addCommentsToProjectAtPath:directory];
//    [BFConfusePBXUUID obfuscateUUIDsInProjectAtPath:directory];
    /*
     
     //检测混淆命名是否重复，丢失等问题
     [BFWordCheckTool checkNewDict:BFConfuseFile.fileMapping oldDict:BFConfuseFile.fileMapping2];
     
     
     //修改工程名
     [BFConfuseProject renameProjectAtPath:directory oldName:@"DeepBooks" newName:@"XXSmallHouse"];
     
     
     //修改目录名
     [BFConfuseDirectory processProjectAtPath:directory renameMapping:BFConfuseDirectory.dict];
     
     
     //类名 并存储对应映射文件.txt
     [BFConfuseFile customReplaceInDirectory:directory replaceDict:BFConfuseFile.fileMapping];
     
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


- (void)chaChongInAllWords{
//    NSLog(@"directory:\n%@",BFConfuseDirectory.dict1);
//    NSLog(@"file:\n%@",BFConfuseFile.fileMapping1);
//    NSLog(@"method:\n%@",BFConfuseMethod.mapMethodDict1);
//    NSLog(@"property:\n%@",BFConfuseProperty.mapPropertyDict1);
//    NSLog(@"variable:\n%@",BFConfuseVariable.mapVariableDict1);
//    NSLog(@"set:\n%@",BFConfuseVariable.mapSetVariableDict1);
//    NSLog(@"constant:\n%@",BFConstantString.mapConstantStringDict1);
//    NSLog(@"imageName:\n%@",BFConfuseImage.mapImageDict1);
//    NSLog(@"model:\n%@",BFConfuseModel.mapModelDict1);
    
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


    [BFConfuseMethod.mapMethodDict100 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
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
