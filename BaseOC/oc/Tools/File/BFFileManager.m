//
//  BFFileManager.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/15.
//

#import "BFFileManager.h"

@implementation BFFileManager

+ (NSArray <BFFileModel *>*)defaultFile{
    NSMutableArray *data = [NSMutableArray array];
    
    NSArray *paths = @[NSHomeDirectory(),[NSBundle mainBundle].bundlePath];
    [paths enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BFFileModel *model = [BFFileModel new];
        model.isDirectory = YES;
        model.filePath = obj;
        model.fileName = obj.lastPathComponent;
        model.fileExtension = obj.pathExtension;
        model.fileType = BFFileTypeDirectory;
        model.fileSize = [self fileSize:obj];
        model.fileDate = [NSDate timeFromDate:[self fileDate:obj]];
        [data addObject:model];
    }];
     
    return data;
}

+ (NSArray <BFFileModel *>*)dataForFilePath:(NSString *)filePath{
    NSMutableArray *data = [NSMutableArray array];
    NSString *charactersToEscape = @"?!@#$^&%*+,:;='\"`<>()[]{}/\\| ";
    NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:charactersToEscape] invertedSet];
    NSURL *pathURL = [NSURL URLWithString:[filePath stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters]];
    if (!pathURL) return data;
    
    NSError *error;
    NSArray <NSURL *>*fileURLs = [NSFileManager.defaultManager contentsOfDirectoryAtURL:pathURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    [fileURLs enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL isDirectory = NO;
        [NSFileManager.defaultManager fileExistsAtPath:obj.path isDirectory:&isDirectory];
        
        BFFileModel *model = [BFFileModel new];
        model.isDirectory = isDirectory;
        model.filePath = obj.path;
        model.fileName = obj.lastPathComponent;
        model.fileExtension = obj.pathExtension;
        model.fileType = isDirectory ? BFFileTypeDirectory : [self typeWithFileExtension:obj.pathExtension];
        model.fileSize = [self fileSize:obj.path];
        model.fileDate = [NSDate timeFromDate:[self fileDate:obj.path]];
        [data addObject:model];
    }];
    return data;
}

+ (BFFileType)typeWithFileExtension:(NSString *)fileExtension{
    BFFileType type = BFFileTypeDefault;
    if (!fileExtension.length) return type;
    
    if ([fileExtension containsString:@"png"] ||
        [fileExtension containsString:@"jpg"] ||
        [fileExtension containsString:@"jpeg"] ||
        [fileExtension containsString:@"gif"]) {
        type = BFFileTypeImage;
    }else if ([fileExtension containsString:@"mp3"] ||
              [fileExtension containsString:@"m4a"]){
        type = BFFileTypeAudio;
    }else if ([fileExtension containsString:@"db"] ||
              [fileExtension containsString:@"database"] ||
              [fileExtension containsString:@"sqlite"]){
        type = BFFileTypeDB;
    }else if ([fileExtension containsString:@"mp4"]){
        type = BFFileTypeVideo;
    }else if ([fileExtension containsString:@"pdf"]){
        type = BFFileTypePDF;
    }else if ([fileExtension containsString:@"doc"]){
        type = BFFileTypeDOC;
    }else if ([fileExtension containsString:@"ppt"]){
        type = BFFileTypePPT;
    }else if ([fileExtension containsString:@"plist"]){
        type = BFFileTypePlist;
    }else if ([fileExtension containsString:@"json"]){
        type = BFFileTypeJson;
    }else if ([fileExtension containsString:@"zip"]){
        type = BFFileTypeZip;
    }else if ([fileExtension containsString:@"html"]){
        type = BFFileTypeHTML;
    }
    return type;
}

+ (unsigned long long)fileSize:(NSString *)filePath{
    unsigned long long size = 0;
    NSFileManager *manager = [NSFileManager defaultManager];
    
    BOOL isDirectory = NO;
    BOOL isExist = [NSFileManager.defaultManager fileExistsAtPath:filePath isDirectory:&isDirectory];
    if (!isExist) return size;
    
    if (isDirectory){
        NSDirectoryEnumerator *enumerator = [manager enumeratorAtPath:filePath];
        for (NSString *subPath in enumerator) {
            NSString *fullPath = [filePath stringByAppendingPathComponent:subPath];
            size += [manager attributesOfItemAtPath:fullPath error:nil].fileSize;
        }
    }else{
        size += [manager attributesOfItemAtPath:filePath error:nil].fileSize;
    }
    return size;
}

+ (NSDate *)fileDate:(NSString *)filePath{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSDictionary *fileAttr = [manager attributesOfItemAtPath:filePath error:nil];
    return [fileAttr objectForKey:NSFileCreationDate];
}

@end
