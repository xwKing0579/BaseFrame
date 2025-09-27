//
//  UIImage+Compare.h
//  BaseFrame
//
//  Created by King on 2025/9/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ImageSimilarityLevel) {
    ImageSimilarityLevelIdentical,      // 同一张图片
    ImageSimilarityLevelPlagiarized,    // 抄袭图片
    ImageSimilarityLevelSimilar,        // 相似图片
    ImageSimilarityLevelOriginal,       // 原创图片
    ImageSimilarityLevelDistinct        // 完全不同图片
};

@interface UIImage (Compare)

///相似度
+ (CGFloat)compareImage:(UIImage *)image1 withImage:(UIImage *)image2;

@end

NS_ASSUME_NONNULL_END
