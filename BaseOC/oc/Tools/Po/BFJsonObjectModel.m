//
//  BFJsonObjectModel.m
//  FXTP
//
//  Created by 王祥伟 on 2024/6/4.
//

#import "BFJsonObjectModel.h"

@implementation BFJsonObjectModel
+ (void)toJson:(NSObject *)obj{
    if (obj && ([obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDictionary class]])){
        [BFRouter jumpUrl:BFString.vc_json_object params:@{@"obj":obj}];
        return;
    }
    UIPasteboard *pastboard = [UIPasteboard generalPasteboard];
    NSString *content = pastboard.string.whitespace;
    if (content.length == 0) {
        [BFToastManager showText:@"请复制后再解析"];
        return;
    }
  
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
      
    if (error) {
        [BFToastManager showText:@"解析失败"];
        return;
    }
    
    if (jsonObject) [BFRouter jumpUrl:BFString.vc_json_object params:@{@"obj":jsonObject}];
}
@end
