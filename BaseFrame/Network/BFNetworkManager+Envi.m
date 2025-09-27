//
//  BFNetworkManager+Envi.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/6.
//

#import "BFNetworkManager+Envi.h"
#import "BFEnviConfig.h"

@implementation BFNetworkManager (Envi)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
+ (NSString *)baseUrl{
#ifdef DEBUG
    BFSchemeEnvi envi = [BFEnviConfig envi];
    if (envi == BFSchemeEnviDev) {
        return @"http://127.0.0.1:8090";
    }else if (envi == BFSchemeEnviPreRelese){
        return @"http://47.108.179.23:8090";
    }else if (envi == BFSchemeEnviRelese){
        return @"http://47.108.179.23:8090";
    }
#endif
    return @"http://47.108.179.23:8090";
}

#pragma clang diagnostic pop

@end
