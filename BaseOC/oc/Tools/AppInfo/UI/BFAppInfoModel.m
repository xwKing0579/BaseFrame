//
//  BFAppInfoModel.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/12.
//

#import "BFAppInfoModel.h"
#import "BFAppInfoManager.h"
#import "BFRAMUsage.h"
@implementation BFAppInfoModel

+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{@"item" : [BFAppInfoListModel class]};
}

+ (NSArray <NSDictionary *>*)data{
    NSArray *data = @[
        @{@"title":@"app信息",
          @"item":@[
              @{@"name":@"bundle name",@"content":[BFAppInfoManager bundleName]},
              @{@"name":@"名称",@"content":[BFAppInfoManager appName]},
              @{@"name":@"bundle",@"content":[BFAppInfoManager appBundle]},
              @{@"name":@"版本",@"content":[BFAppInfoManager appVersion]},
              @{@"name":@"最低系统版本",@"content":[BFAppInfoManager appMinSystemVersion]},
              @{@"name":@"内存使用",@"content":[NSString sizeString:[BFRAMUsage getAppRAMUsage]]},
          ]},
        @{@"title":@"设备信息",
          @"item":@[
              @{@"name":@"名称",@"content":[BFAppInfoManager deviceName]},
              @{@"name":@"型号",@"content":[BFAppInfoManager deviceModel]},
              @{@"name":@"尺寸",@"content":[BFAppInfoManager deviceSize]},
              @{@"name":@"scale",@"content":[BFAppInfoManager deviceScale]},
              @{@"name":@"版本",@"content":[BFAppInfoManager systemVersion]},
              @{@"name":@"语言",@"content":[BFAppInfoManager systemLanguage]},
              @{@"name":@"内存使用",@"content":[NSString sizeString:[BFRAMUsage getSystemRAMUsage]]},
              @{@"name":@"内存剩余",@"content":[NSString sizeString:[BFRAMUsage getSystemRAMAvailable]]},
              @{@"name":@"内存总量",@"content":[NSString sizeString:[BFRAMUsage getSystemRAMTotal]]},
          ]}
    ];
    return [NSArray yy_modelArrayWithClass:[self class] json:data];
}

@end


@implementation BFAppInfoListModel

@end
