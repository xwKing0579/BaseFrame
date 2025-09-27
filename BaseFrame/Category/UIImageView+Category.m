//
//  UIImageView+Category.m
//  QuShou
//
//  Created by 王祥伟 on 2024/4/6.
//

#import "UIImageView+Category.h"

@implementation UIImageView (Category)

- (void)setImageUrl:(id)url{
    [self setImageUrl:url placeholder:nil];
}

- (void)setImageUrl:(id)url placeholder:(id _Nullable)placeholder{
    NSURL *URL = [self handleImageUrl:url];
    [self sd_setImageWithURL:URL placeholderImage:[self handlePlaceholder:placeholder]];
}

- (NSURL *)handleImageUrl:(id)url{
    NSURL *URL;
    if ([url isKindOfClass:[NSString class]]){
        URL = [NSURL URLWithString:url];
    }else if ([url isKindOfClass:[NSURL class]]){
        URL = url;
    }
    return URL;
}

- (UIImage *)handlePlaceholder:(id _Nullable)placeholder{
    UIImage *placeholderImage;
    if ([placeholder isKindOfClass:[NSString class]]){
        placeholderImage = [UIImage imageNamed:placeholder];
    }else if ([placeholder isKindOfClass:[UIImage class]]){
        placeholderImage = placeholder;
    }
    return placeholderImage;
}

@end
