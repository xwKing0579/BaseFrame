//
//  BFNetworkManager.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/5.
//

#import "BFNetworkManager.h"
#import "BFNetworkCache.h"
@implementation BFNetworkManager

+ (AFHTTPSessionManager *)manager {
    static AFHTTPSessionManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [AFHTTPSessionManager manager];
    });
    return manager;
}

+ (NSString *)fullUrl:(NSString *)url{
    if ([url hasPrefix:@"/"]) url = [url substringFromIndex:1];
    return [NSString stringWithFormat:@"%@/%@",[self baseUrl],url];
}

+ (NSString *)baseUrl{return @"";}

+ (void)managerConfig{}

+ (__kindof NSURLSessionTask *)get:(NSString *)url
                            params:(id _Nullable)params
                            result:(BFHTTPRequestResult)result{
    return [self get:url params:params result:result responseCache:nil];
}

+ (__kindof NSURLSessionTask *)get:(NSString *)url
                            params:(id _Nullable)params
                            result:(BFHTTPRequestResult)result
                     responseCache:(BFHTTPRequestCache _Nullable)responseCache{
    return [self get:url params:params model:nil result:result responseCache:responseCache];
}

+ (__kindof NSURLSessionTask *)get:(NSString *)url
                            params:(id _Nullable)params
                             model:(id _Nullable)model
                            result:(BFHTTPRequestResult)result{
    return [self get:url params:params model:model result:result responseCache:nil];
}

+ (__kindof NSURLSessionTask *)get:(NSString *)url
                            params:(id _Nullable)params
                             model:(id _Nullable)model
                            result:(BFHTTPRequestResult)result
                     responseCache:(BFHTTPRequestCache _Nullable)responseCache{
    responseCache == nil ? nil : responseCache([BFNetworkCache httpCacheForURL:url params:params]);
    return [self.manager GET:[self fullUrl:url] parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self resultWithResponseObject:responseObject model:model result:result];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        !result ?: result(NO ,error, nil);
    }];
}

+ (__kindof NSURLSessionTask *)post:(NSString *)url
                            params:(id _Nullable)params
                             result:(BFHTTPRequestResult)result{
    return [self post:url params:params result:result responseCache:nil];
}

+ (__kindof NSURLSessionTask *)post:(NSString *)url
                            params:(id _Nullable)params
                            result:(BFHTTPRequestResult)result
                      responseCache:(BFHTTPRequestCache _Nullable)responseCache{
    return [self post:url params:params model:nil result:result responseCache:responseCache];
}

+ (__kindof NSURLSessionTask *)post:(NSString *)url
                            params:(id _Nullable)params
                             model:(id _Nullable)model
                             result:(BFHTTPRequestResult)result{
    return [self post:url params:params model:model result:result responseCache:nil];
}

+ (__kindof NSURLSessionTask *)post:(NSString *)url
                            params:(id _Nullable)params
                             model:(id _Nullable)model
                            result:(BFHTTPRequestResult)result
                      responseCache:(BFHTTPRequestCache _Nullable)responseCache{
    responseCache == nil ? nil : responseCache([BFNetworkCache httpCacheForURL:url params:params]);
    return [self.manager POST:[self fullUrl:url] parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self resultWithResponseObject:responseObject model:model result:result];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        !result ?: result(NO ,error, nil);
    }];
}

+ (__kindof NSURLSessionTask *)uploadImagesWithURL:(NSString *)url
                                            params:(id _Nullable)params
                                              name:(NSString *)name
                                            images:(NSArray<UIImage *> *)images
                                         fileNames:(NSArray<NSString *> *)fileNames
                                        imageScale:(CGFloat)imageScale
                                         imageType:(NSString *)imageType
                                          progress:(BFHTTPProgress)progress
                                            result:(BFHTTPRequestResult)result{
    return [self uploadImagesWithURL:url params:params name:name images:images fileNames:fileNames imageScale:imageScale imageType:imageType progress:progress model:nil result:result];
}

+ (__kindof NSURLSessionTask *)uploadImagesWithURL:(NSString *)url
                                            params:(id _Nullable)params
                                              name:(NSString *)name
                                            images:(NSArray<UIImage *> *)images
                                         fileNames:(NSArray<NSString *> *)fileNames
                                        imageScale:(CGFloat)imageScale
                                         imageType:(NSString *)imageType
                                          progress:(BFHTTPProgress)progress
                                             model:(id _Nullable)model
                                            result:(BFHTTPRequestResult)result{
    return [self.manager POST:[self fullUrl:url] parameters:params headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        for (NSUInteger i = 0; i < images.count; i++) {
            // 图片经过等比压缩后得到的二进制文件
            NSData *imageData = UIImageJPEGRepresentation(images[i], imageScale ?: 1.f);
            // 默认图片的文件名, 若fileNames为nil就使用
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            NSString *imageFileName = [NSString stringWithFormat:@"%@%ld.%@",str,i,imageType?:@"jpg"];
            
            [formData appendPartWithFileData:imageData
                                        name:name
                                    fileName:fileNames ? [NSString stringWithFormat:@"%@.%@",fileNames[i],imageType?:@"jpg"] : imageFileName
                                    mimeType:[NSString stringWithFormat:@"image/%@",imageType ?: @"jpg"]];
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(uploadProgress) : nil;
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self resultWithResponseObject:responseObject model:model result:result];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        !result ?: result(NO ,error, nil);
    }];
}

+ (__kindof NSURLSessionTask *)downloadWithURL:(NSString *)url
                                       fileDir:(NSString *)fileDir
                                      progress:(BFHTTPProgress)progress
                                        result:(BFHTTPRequestResult)result{
    return [self downloadWithURL:url fileDir:fileDir progress:progress model:nil result:result];
}

+ (__kindof NSURLSessionTask *)downloadWithURL:(NSString *)url
                                       fileDir:(NSString *)fileDir
                                      progress:(BFHTTPProgress)progress
                                         model:(id _Nullable)model
                                        result:(BFHTTPRequestResult)result{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[self fullUrl:url]]];
    NSURLSessionDownloadTask *task = [self.manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(downloadProgress) : nil;
        });
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileDir ? fileDir : @"Download"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        !result ?: result(NO ,error, filePath);
    }];
    [task resume];
    return task;
}

+ (NSString *)resultString{
    return @"data";
}

+ (NSString *)messageString{
    return @"msg";
}

+ (NSString *)successCodeString{
    return @"code";
}

+ (NSArray <NSString *>*)successCode{
    return @[@"0",@"200"];
}

+ (void)resultWithResponseObject:(id)responseObject model:(id _Nullable)model result:(BFHTTPRequestResult)result{
    NSError *error;
    id resultData;
    BOOL success;
    if ([responseObject isKindOfClass:[NSDictionary class]]){
        NSDictionary *obj = (NSDictionary *)responseObject;
        NSString *code = [obj valueForKey:[self successCodeString]];
        NSString *msg = [obj valueForKey:[self messageString]];
        resultData = [obj valueForKey:[self resultString]];
        if (code.intValue == 401){
            //重新登陆
            return;
        }
        
        error = [NSError errorWithDomain:[self baseUrl] code:[code intValue] userInfo:@{NSLocalizedDescriptionKey:msg}];
        if (model){
            Class cls = [model class];
            if ([model isKindOfClass:[NSString class]]){
                cls = NSClassFromString(model);
            }
            resultData = [cls yy_modelWithJSON:resultData];
        }
    }
    !result ?: result(success ,error, resultData);
}

@end
