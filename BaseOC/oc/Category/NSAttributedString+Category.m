//
//  NSAttributedString+tools.m
//  SeniorLoans
//
//  Created by 祥伟 on 2019/8/6.
//  Copyright © 2019 weiMeng. All rights reserved.
//

#import "NSAttributedString+Category.h"

@implementation NSAttributedString (Category)

+ (NSMutableAttributedString *)attributedStringFromTextArray:(NSArray *)textArray colorArray:(NSArray <UIColor *>*)colorArray sizeArray:(NSArray *)sizeArray{
    
    return [self attributedStringFromTextArray:textArray colorArray:colorArray sizeArray:sizeArray keyArray:nil baselineOffset:nil];
}

+ (NSMutableAttributedString *)attributedStringFromTextArray:(NSArray *)textArray colorArray:(NSArray <UIColor *>*)colorArray sizeArray:(NSArray *)sizeArray baselineOffset:(NSNumber *)offset{
    
    return [self attributedStringFromTextArray:textArray colorArray:colorArray sizeArray:sizeArray keyArray:nil baselineOffset:offset];
}

+ (NSMutableAttributedString *)attributedStringFromTextArray:(NSArray *)textArray colorArray:(NSArray <UIColor *>*)colorArray sizeArray:(NSArray *)sizeArray keyArray:(NSArray *)keyArray{
    
    return [self attributedStringFromTextArray:textArray colorArray:colorArray sizeArray:sizeArray keyArray:keyArray baselineOffset:nil];
}

+ (NSMutableAttributedString *)attributedStringFromTextArray:(NSArray *)textArray colorArray:(NSArray <UIColor *>*)colorArray sizeArray:(NSArray *)sizeArray keyArray:(NSArray *)keyArray baselineOffset:(NSNumber *)offset{
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    
    [textArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([textArray[idx] isKindOfClass:[UIImage class]]) {
            NSTextAttachment *textAttachment = [[NSTextAttachment alloc]init];
            textAttachment.image = textArray[idx];
            
            CGFloat scale = 1;
            if (sizeArray.count > idx) {
                scale = [sizeArray[idx] floatValue];
            }
            CGFloat imgW = textAttachment.image.size.width*scale;
            CGFloat imgH = textAttachment.image.size.height*scale;
            
            if (!textAttachment.image) return ;
            CGSize sizeValue = CGSizeMake(imgW, imgH);
            if (sizeArray.count > idx) {
                if ([sizeArray[idx] isKindOfClass:[NSString class]]) {
                    sizeValue = CGSizeFromString(sizeArray[idx]);
                }
            }
            //居中
            CGFloat orgin_y = 0.0;
            if (imgH > sizeValue.height) {
                orgin_y = (imgH-sizeValue.height)/2;
            }
            textAttachment.bounds = CGRectMake(0.0, orgin_y, sizeValue.width, sizeValue.height);
            [attributedString appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment]];
        }else if ([obj isKindOfClass:[NSString class]]){
            NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:obj];
            
            UIColor *colorValue = UIColor.cFFFFFF;
            if (colorArray.count > idx) {
                if ([colorArray[idx] isKindOfClass:[UIColor class]]) {
                    colorValue = colorArray[idx];
                }
            }else{
                if ([[colorArray lastObject] isKindOfClass:[UIColor class]]) {
                    colorValue = [colorArray lastObject];
                }
            }
            
            UIFont *fontValue = UIFont.font14;
            if (sizeArray.count > idx) {
                if ([sizeArray[idx] isKindOfClass:[UIFont class]]) {
                    fontValue = sizeArray[idx];
                }else if ([sizeArray[idx] isKindOfClass:[NSNumber class]]){
                    fontValue = [UIFont systemFontOfSize:[sizeArray[idx] floatValue]];
                }
            }else{
                if ([[sizeArray lastObject] isKindOfClass:[NSNumber class]]) {
                    fontValue = [UIFont systemFontOfSize:[[sizeArray lastObject] floatValue]];
                }else if([[sizeArray lastObject] isKindOfClass:[UIFont class]]){
                    fontValue = [sizeArray lastObject];
                }
            }
            
            
            [attrString addAttributes:@{
                                        NSForegroundColorAttributeName: colorValue,
                                        NSFontAttributeName: fontValue
                                        } range:NSMakeRange(0, attrString.length)];
            
            if (keyArray.count) {
                if (keyArray.count > idx) {
                    id thing = keyArray[idx];
                    if ([thing isKindOfClass:[NSDictionary class]]) {
                        [attrString addAttributes:thing range:NSMakeRange(0, attrString.length)];
                    }
                }
            }
            
            if (offset) {
                [attrString addAttributes:@{NSBaselineOffsetAttributeName: offset} range:NSMakeRange(0, attrString.length)];
            }
            
            [attributedString appendAttributedString:attrString];
        }
        
    }];
    return attributedString;
}

@end
