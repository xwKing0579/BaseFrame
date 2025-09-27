//
//  BFNetworkManager.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/5.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>

NS_ASSUME_NONNULL_BEGIN
@class AFHTTPSessionManager;

typedef void(^BFHTTPRequestResult)(BOOL success, NSError *_Nullable error, id _Nullable result);
typedef void(^BFHTTPRequestCache)(id responseCache);
typedef void(^BFHTTPProgress)(NSProgress *progress);

@interface BFNetworkManager : NSObject

@property (nonatomic, strong) AFHTTPSessionManager *managers;

+ (__kindof NSURLSessionTask *)get:(NSString *)url
                            params:(id _Nullable)params
                            result:(BFHTTPRequestResult)result;

+ (__kindof NSURLSessionTask *)get:(NSString *)url
                            params:(id _Nullable)params
                            result:(BFHTTPRequestResult)result
                     responseCache:(BFHTTPRequestCache _Nullable)responseCache;

+ (__kindof NSURLSessionTask *)get:(NSString *)url
                            params:(id _Nullable)params
                             model:(id _Nullable)model
                            result:(BFHTTPRequestResult)result;

+ (__kindof NSURLSessionTask *)get:(NSString *)url
                            params:(id _Nullable)params
                             model:(id _Nullable)model
                            result:(BFHTTPRequestResult)result
                     responseCache:(BFHTTPRequestCache _Nullable)responseCache;

+ (__kindof NSURLSessionTask *)post:(NSString *)url
                            params:(id _Nullable)params
                            result:(BFHTTPRequestResult)result;

+ (__kindof NSURLSessionTask *)post:(NSString *)url
                            params:(id _Nullable)params
                            result:(BFHTTPRequestResult)result
                     responseCache:(BFHTTPRequestCache _Nullable)responseCache;

+ (__kindof NSURLSessionTask *)post:(NSString *)url
                            params:(id _Nullable)params
                             model:(id _Nullable)model
                            result:(BFHTTPRequestResult)result;

+ (__kindof NSURLSessionTask *)post:(NSString *)url
                            params:(id _Nullable)params
                             model:(id _Nullable)model
                            result:(BFHTTPRequestResult)result
                     responseCache:(BFHTTPRequestCache _Nullable)responseCache;

+ (__kindof NSURLSessionTask *)uploadImagesWithURL:(NSString *)url
                                            params:(id _Nullable)params
                                              name:(NSString *)name
                                            images:(NSArray<UIImage *> *)images
                                         fileNames:(NSArray<NSString *> *)fileNames
                                        imageScale:(CGFloat)imageScale
                                         imageType:(NSString *)imageType
                                          progress:(BFHTTPProgress)progress
                                            result:(BFHTTPRequestResult)result;

+ (__kindof NSURLSessionTask *)uploadImagesWithURL:(NSString *)url
                                            params:(id _Nullable)params
                                              name:(NSString *)name
                                            images:(NSArray<UIImage *> *)images
                                         fileNames:(NSArray<NSString *> *)fileNames
                                        imageScale:(CGFloat)imageScale
                                         imageType:(NSString *)imageType
                                          progress:(BFHTTPProgress)progress
                                             model:(id _Nullable)model
                                            result:(BFHTTPRequestResult)result;

+ (__kindof NSURLSessionTask *)downloadWithURL:(NSString *)url
                                       fileDir:(NSString *)fileDir
                                      progress:(BFHTTPProgress)progress
                                        result:(BFHTTPRequestResult)result;

+ (__kindof NSURLSessionTask *)downloadWithURL:(NSString *)url
                                       fileDir:(NSString *)fileDir
                                      progress:(BFHTTPProgress)progress
                                         model:(id _Nullable)model
                                        result:(BFHTTPRequestResult)result;

+ (AFHTTPSessionManager *)manager;

+ (NSString *)baseUrl;
+ (void)managerConfig;
+ (NSString *)resultString;
+ (NSString *)messageString;
+ (NSString *)successCodeString;
+ (NSArray <NSString *>*)successCode;


@end

NS_ASSUME_NONNULL_END
