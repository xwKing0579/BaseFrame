//
//  BFRouterModel.m
//  QuShou
//
//  Created by 王祥伟 on 2024/4/25.
//

#import "BFRouterModel.h"

@implementation BFRouterModel
static NSMutableDictionary *_filePathSet;
+ (void)load{
    _filePathSet = [NSMutableDictionary dictionary];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        [self computeFilePath:@"/Users/wangxiangwei/Desktop/CashCeria"];
    });
}

+ (NSDictionary *)hfiles{
    return _filePathSet;
}

+ (void)computeFilePath:(NSString *)projectPath{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:projectPath error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        if ([filePath isEqualToString:@"Pods"]) continue;
        NSString *path = [projectPath stringByAppendingPathComponent:filePath];
        
        if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
            [self computeFilePath:path];
            continue;
        }
        
        NSString *fileName = filePath.lastPathComponent;
        NSString *suffixString = @".h";
        if ([fileName hasSuffix:suffixString]){
            NSString *classString = [fileName stringByReplacingOccurrencesOfString:suffixString withString:@""];
            [_filePathSet setValue:path forKey:classString];
        }
    }
}
@end
