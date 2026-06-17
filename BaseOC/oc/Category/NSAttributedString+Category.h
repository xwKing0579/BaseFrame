//
//  NSAttributedString+tools.h
//  SeniorLoans
//
//  Created by 祥伟 on 2019/8/6.
//  Copyright © 2019 weiMeng. All rights reserved.
//



NS_ASSUME_NONNULL_BEGIN

@interface NSAttributedString (Category)

/*
 *    富文本
 *    @param textArray  内容 文字、图片
 *    @param colorArray color数组， 取对应值，默认whiteColor
 *    @param sizeArray  大小，可以是NSNumber，UIFont
 *
 */
+ (NSMutableAttributedString *)attributedStringFromTextArray:(NSArray *)textArray colorArray:(NSArray <UIColor *>*)colorArray sizeArray:(NSArray *)sizeArray;

/*
 *    富文本
 *    @param textArray  内容 文字、图片
 *    @param colorArray color数组， 取对应值，默认whiteColor
 *    @param sizeArray  大小，可以是NSNumber，UIFont
 *    @param offset     NSBaselineOffsetAttributeName
 *
 */
+ (NSMutableAttributedString *)attributedStringFromTextArray:(NSArray *)textArray colorArray:(NSArray <UIColor *>*)colorArray sizeArray:(NSArray *)sizeArray baselineOffset:(NSNumber *)offset;

/*
 *    富文本
 *    @param textArray  内容 文字、图片
 *    @param colorArray color数组， 取对应值，默认whiteColor
 *    @param sizeArray  大小，可以是NSNumber，UIFont
 *    @param keyArray   其他属性值
 *
 */
+ (NSMutableAttributedString *)attributedStringFromTextArray:(NSArray *)textArray colorArray:(NSArray <UIColor *>*)colorArray sizeArray:(NSArray *)sizeArray keyArray:(NSArray *)keyArray;

@end

NS_ASSUME_NONNULL_END
