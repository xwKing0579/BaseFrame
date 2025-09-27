//
//  UIImage+Compare.m
//  BaseFrame
//
//  Created by King on 2025/9/26.
//

#import "UIImage+Compare.h"



@implementation UIImage (Compare)


+ (CGFloat)compareImage:(UIImage *)image1 withImage:(UIImage *)image2 {
    // 统一尺寸
    CGSize targetSize = CGSizeMake(256, 256);
    UIImage *img1 = [self resizeImage:image1 toSize:targetSize];
    UIImage *img2 = [self resizeImage:image2 toSize:targetSize];
    
    // 使用更稳定的多维度比较
    CGFloat structuralSimilarity = [self extremeStructuralSimilarity:img1 image2:img2];
    CGFloat histogramSimilarity = [self correlationHistogramComparison:img1 image2:img2];
    CGFloat edgeSimilarity = [self edgeFeatureSimilarity:img1 image2:img2]; // 新增边缘特征相似度
    
    NSLog(@"结构相似度: %.4f, 直方图相似度: %.4f, 边缘特征相似度: %.4f",
          structuralSimilarity, histogramSimilarity, edgeSimilarity);
    
    // 更合理的权重分配
    CGFloat finalSimilarity = structuralSimilarity * 0.6 +  histogramSimilarity * 0.25 + edgeSimilarity * 0.15;
    
    // 非线性校准
    CGFloat result = [self calibratedNonlinearTransform:finalSimilarity];
    
    // 输出分级结果
    [self printSimilarityLevel:result
                    structural:structuralSimilarity
                     histogram:histogramSimilarity
                          edge:edgeSimilarity];
    
    return result;
}

#pragma mark - 边缘特征相似度（替代像素相似度）
+ (CGFloat)edgeFeatureSimilarity:(UIImage *)image1 image2:(UIImage *)image2 {
    // 使用边缘检测来比较图像结构特征
    CGImageRef cgImage1 = image1.CGImage;
    CGImageRef cgImage2 = image2.CGImage;
    
    size_t width = CGImageGetWidth(cgImage1);
    size_t height = CGImageGetHeight(cgImage1);
    
    // 获取边缘特征图
    unsigned char *edge1 = [self extractEdgeFeatures:image1];
    unsigned char *edge2 = [self extractEdgeFeatures:image2];
    
    if (!edge1 || !edge2) return 0;
    
    // 计算边缘特征的相关性
    NSInteger totalPixels = width * height;
    NSInteger matchedEdges = 0;
    NSInteger totalEdges = 0;
    
    for (int i = 0; i < totalPixels; i++) {
        if (edge1[i] > 128 || edge2[i] > 128) { // 边缘像素
            totalEdges++;
            if (ABS(edge1[i] - edge2[i]) < 64) { // 容忍度
                matchedEdges++;
            }
        }
    }
    
    free(edge1);
    free(edge2);
    
    if (totalEdges == 0) return 1.0; // 都没有边缘，认为是纯色图，相似
    
    return (CGFloat)matchedEdges / totalEdges;
}

#pragma mark - 边缘特征提取
+ (unsigned char *)extractEdgeFeatures:(UIImage *)image {
    CGImageRef cgImage = image.CGImage;
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    
    // 先转换为灰度图
    unsigned char *grayPixels = [self convertToGrayPixels:image];
    unsigned char *edgePixels = malloc(width * height);
    
    // 简单的Sobel边缘检测
    for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
            int gx = (-1 * grayPixels[(y-1)*width + (x-1)]) +
                     (-2 * grayPixels[y*width + (x-1)]) +
                     (-1 * grayPixels[(y+1)*width + (x-1)]) +
                     (1 * grayPixels[(y-1)*width + (x+1)]) +
                     (2 * grayPixels[y*width + (x+1)]) +
                     (1 * grayPixels[(y+1)*width + (x+1)]);
            
            int gy = (-1 * grayPixels[(y-1)*width + (x-1)]) +
                     (-2 * grayPixels[(y-1)*width + x]) +
                     (-1 * grayPixels[(y-1)*width + (x+1)]) +
                     (1 * grayPixels[(y+1)*width + (x-1)]) +
                     (2 * grayPixels[(y+1)*width + x]) +
                     (1 * grayPixels[(y+1)*width + (x+1)]);
            
            int gradient = (int)sqrt(gx * gx + gy * gy);
            edgePixels[y * width + x] = MIN(255, gradient);
        }
    }
    
    free(grayPixels);
    return edgePixels;
}

#pragma mark - 校准的非线性变换
+ (CGFloat)calibratedNonlinearTransform:(CGFloat)similarity {
    // 根据新的权重分配调整校准曲线
    if (similarity > 0.95) {
        return 1.0 - pow(1.0 - similarity, 0.7); // 更平滑的极高相似度处理
    } else if (similarity > 0.8) {
        return similarity * 1.05; // 适度增强高相似度
    } else if (similarity > 0.5) {
        return similarity; // 中等相似度保持原样
    } else {
        return pow(similarity, 1.2); // 轻微惩罚低相似度
    }
}

#pragma mark - 更新输出方法
+ (void)printSimilarityLevel:(CGFloat)similarity
                  structural:(CGFloat)structural
                   histogram:(CGFloat)histogram
                        edge:(CGFloat)edge {
    
    NSString *level;
    NSString *description;
    NSString *recommendation;
    
    // 根据新的权重分布调整阈值
    if (similarity >= 0.97) { // 稍微降低阈值
        level = @"🟢 同一张图片";
        description = @"图片内容完全一致，可能是同一文件或完全复制";
        recommendation = @"确认为同一图片，无需进一步处理";
    } else if (similarity >= 0.88) { // 调整阈值
        level = @"🔴 抄袭图片";
        description = @"高度相似，仅进行微小修改，存在抄袭嫌疑";
        recommendation = @"存在抄袭风险，建议审查图片使用权限";
    } else if (similarity >= 0.65) { // 调整阈值
        level = @"🟡 相似图片";
        description = @"有明显相似之处，但存在一定差异";
        recommendation = @"存在相似性，建议评估是否构成侵权";
    } else if (similarity >= 0.25) { // 调整阈值
        level = @"🔵 原创图片";
        description = @"有相似元素但整体差异明显，属于原创范畴";
        recommendation = @"属于合理范围内的相似，可正常使用";
    } else {
        level = @"⚫ 完全不同图片";
        description = @"图片内容基本无关联";
        recommendation = @"图片差异明显，无相似性风险";
    }
    
    NSLog(@"\n"
          @"========================================\n"
          @"📊 图片相似度分析报告（优化权重版）\n"
          @"========================================\n"
          @"📈 总体相似度: %.4f\n"
          @"🏷️  相似等级: %@\n"
          @"📝 等级描述: %@\n"
          @"💡 处理建议: %@\n"
          @"----------------------------------------\n"
          @"🔍 详细分数分析:\n"
          @"   • 结构相似度: %.4f (权重: 60%%)\n"
          @"   • 直方图相似度: %.4f (权重: 25%%)\n"
          @"   • 边缘特征相似度: %.4f (权重: 15%%)\n"
          @"========================================",
          similarity, level, description, recommendation,
          structural, histogram, edge);
}

// 如果需要更简洁的版本
+ (void)printSimpleSimilarityLevel:(CGFloat)similarity {
    NSString *level;
    
    if (similarity >= 0.98) {
        level = @"同一张图片 🟢";
    } else if (similarity >= 0.90) {
        level = @"抄袭图片 🔴";
    } else if (similarity >= 0.70) {
        level = @"相似图片 🟡";
    } else if (similarity >= 0.30) {
        level = @"原创图片 🔵";
    } else {
        level = @"完全不同图片 ⚫";
    }
    
    NSLog(@"相似度: %.2f%% | 等级: %@", similarity * 100, level);
}

#pragma mark - 准确的结构相似度 (SSIM)
+ (CGFloat)extremeStructuralSimilarity:(UIImage *)image1 image2:(UIImage *)image2 {
    CGImageRef cgImage1 = image1.CGImage;
    CGImageRef cgImage2 = image2.CGImage;
    
    size_t width = CGImageGetWidth(cgImage1);
    size_t height = CGImageGetHeight(cgImage1);
    
    // 验证尺寸一致性
    if (width != CGImageGetWidth(cgImage2) || height != CGImageGetHeight(cgImage2)) {
        return 0.0f;
    }
    
    // 转换为灰度图
    float *gray1 = [self convertToNormalizedGrayPixels:image1];
    float *gray2 = [self convertToNormalizedGrayPixels:image2];
    
    if (!gray1 || !gray2) {
        return 0.0f;
    }
    
    // SSIM参数 (遵循标准SSIM参数)
    const int windowSize = 11;
    const double K1 = 0.01;
    const double K2 = 0.03;
    const double L = 255.0; // 像素值范围
    const double C1 = (K1 * L) * (K1 * L);
    const double C2 = (K2 * L) * (K2 * L);
    const double C3 = C2 / 2.0;
    
    double totalSSIM = 0.0;
    int windowCount = 0;
    
    // 使用高斯加权窗口
    double *gaussianWindow = [self createGaussianWindow:windowSize sigma:1.5];
    
    // 滑动窗口计算SSIM
    for (int y = 0; y <= height - windowSize; y += 4) { // 步长为4，避免过度重叠
        for (int x = 0; x <= width - windowSize; x += 4) {
            double mu1 = 0.0, mu2 = 0.0;
            double sigma1_sq = 0.0, sigma2_sq = 0.0, sigma12 = 0.0;
            
            // 使用高斯加权计算均值和方差
            for (int j = 0; j < windowSize; j++) {
                for (int i = 0; i < windowSize; i++) {
                    int px = x + i, py = y + j;
                    double weight = gaussianWindow[j * windowSize + i];
                    double p1 = gray1[py * width + px];
                    double p2 = gray2[py * width + px];
                    
                    mu1 += p1 * weight;
                    mu2 += p2 * weight;
                }
            }
            
            // 计算方差和协方差
            for (int j = 0; j < windowSize; j++) {
                for (int i = 0; i < windowSize; i++) {
                    int px = x + i, py = y + j;
                    double weight = gaussianWindow[j * windowSize + i];
                    double p1 = gray1[py * width + px];
                    double p2 = gray2[py * width + px];
                    
                    sigma1_sq += weight * (p1 - mu1) * (p1 - mu1);
                    sigma2_sq += weight * (p2 - mu2) * (p2 - mu2);
                    sigma12 += weight * (p1 - mu1) * (p2 - mu2);
                }
            }
            
            // 避免除零
            if (fabs(mu1) < 1e-10 && fabs(mu2) < 1e-10) {
                totalSSIM += 1.0; // 两个窗口都是黑色，认为完全相似
            } else if (fabs(mu1) < 1e-10 || fabs(mu2) < 1e-10) {
                totalSSIM += 0.0; // 一个窗口是黑色，另一个不是，认为不相似
            } else {
                // 标准SSIM计算公式
                double luminance = (2 * mu1 * mu2 + C1) / (mu1 * mu1 + mu2 * mu2 + C1);
                double contrast = (2 * sqrt(sigma1_sq) * sqrt(sigma2_sq) + C2) / (sigma1_sq + sigma2_sq + C2);
                double structure = (sigma12 + C3) / (sqrt(sigma1_sq) * sqrt(sigma2_sq) + C3);
                
                double windowSSIM = luminance * contrast * structure;
                
                // 处理异常值
                if (windowSSIM >= -1.0 && windowSSIM <= 1.0) {
                    totalSSIM += windowSSIM;
                } else {
                    totalSSIM += 0.0;
                }
            }
            
            windowCount++;
        }
    }
    
    free(gray1);
    free(gray2);
    free(gaussianWindow);
    
    if (windowCount == 0) return 0.0f;
    
    double avgSSIM = totalSSIM / windowCount;
    
    // 将SSIM从[-1, 1]映射到[0, 1]
    return MAX(0.0, (avgSSIM + 1.0) / 2.0);
}

#pragma mark - 准确的直方图相关性比较
+ (CGFloat)correlationHistogramComparison:(UIImage *)image1 image2:(UIImage *)image2 {
    // 分别计算RGB和HSV直方图，综合比较
    CGFloat rgbCorrelation = [self rgbHistogramCorrelation:image1 image2:image2];
    CGFloat hsvCorrelation = [self hsvHistogramCorrelation:image1 image2:image2];
    
    // 综合RGB和HSV直方图的相关性
    return (rgbCorrelation * 0.6 + hsvCorrelation * 0.4);
}

#pragma mark - RGB直方图相关性
+ (CGFloat)rgbHistogramCorrelation:(UIImage *)image1 image2:(UIImage *)image2 {
    const int bins = 16; // 每个通道16个bin
    
    // 计算RGB直方图
    float *hist1 = [self computeRGBHistogram:image1 bins:bins];
    float *hist2 = [self computeRGBHistogram:image2 bins:bins];
    
    if (!hist1 || !hist2) return 0.0f;
    
    int totalBins = bins * bins * bins;
    
    // 计算皮尔逊相关系数
    double sum1 = 0.0, sum2 = 0.0;
    double sum1Sq = 0.0, sum2Sq = 0.0;
    double sum12 = 0.0;
    
    for (int i = 0; i < totalBins; i++) {
        sum1 += hist1[i];
        sum2 += hist2[i];
        sum1Sq += hist1[i] * hist1[i];
        sum2Sq += hist2[i] * hist2[i];
        sum12 += hist1[i] * hist2[i];
    }
    
    free(hist1);
    free(hist2);
    
    double numerator = sum12 - (sum1 * sum2) / totalBins;
    double denominator = sqrt((sum1Sq - sum1 * sum1 / totalBins) *
                             (sum2Sq - sum2 * sum2 / totalBins));
    
    if (denominator < 1e-10) {
        return (fabs(sum1 - sum2) < 1e-10) ? 1.0 : 0.0;
    }
    
    double correlation = numerator / denominator;
    
    // 处理数值误差，确保在[-1, 1]范围内
    correlation = MAX(-1.0, MIN(1.0, correlation));
    
    // 映射到[0, 1]
    return (correlation + 1.0) / 2.0;
}

#pragma mark - HSV直方图相关性
+ (CGFloat)hsvHistogramCorrelation:(UIImage *)image1 image2:(UIImage *)image2 {
    const int hBins = 8;  // 色调8个bin
    const int sBins = 4;  // 饱和度4个bin
    const int vBins = 4;  // 亮度4个bin
    
    float *hist1 = [self computeHSVHistogram:image1 hBins:hBins sBins:sBins vBins:vBins];
    float *hist2 = [self computeHSVHistogram:image2 hBins:hBins sBins:sBins vBins:vBins];
    
    if (!hist1 || !hist2) return 0.0f;
    
    int totalBins = hBins * sBins * vBins;
    
    // 计算相关性
    double sum1 = 0.0, sum2 = 0.0;
    double sum1Sq = 0.0, sum2Sq = 0.0;
    double sum12 = 0.0;
    
    for (int i = 0; i < totalBins; i++) {
        sum1 += hist1[i];
        sum2 += hist2[i];
        sum1Sq += hist1[i] * hist1[i];
        sum2Sq += hist2[i] * hist2[i];
        sum12 += hist1[i] * hist2[i];
    }
    
    free(hist1);
    free(hist2);
    
    double numerator = sum12 - (sum1 * sum2) / totalBins;
    double denominator = sqrt((sum1Sq - sum1 * sum1 / totalBins) *
                             (sum2Sq - sum2 * sum2 / totalBins));
    
    if (denominator < 1e-10) {
        return (fabs(sum1 - sum2) < 1e-10) ? 1.0 : 0.0;
    }
    
    double correlation = numerator / denominator;
    correlation = MAX(-1.0, MIN(1.0, correlation));
    
    return (correlation + 1.0) / 2.0;
}

#pragma mark - 工具方法
+ (float *)convertToNormalizedGrayPixels:(UIImage *)image {
    CGImageRef cgImage = image.CGImage;
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    
    float *grayPixels = malloc(width * height * sizeof(float));
    if (!grayPixels) return NULL;
    
    // 获取RGB像素数据
    uint32_t *pixels = [self getARGBPixelData:image];
    if (!pixels) {
        free(grayPixels);
        return NULL;
    }
    
    // 转换为灰度并归一化到[0,1]
    for (int i = 0; i < width * height; i++) {
        uint32_t pixel = pixels[i];
        uint8_t r = (pixel >> 16) & 0xFF;
        uint8_t g = (pixel >> 8) & 0xFF;
        uint8_t b = pixel & 0xFF;
        
        // 使用标准灰度公式
        float gray = (0.299f * r + 0.587f * g + 0.114f * b) / 255.0f;
        grayPixels[i] = gray;
    }
    
    free(pixels);
    return grayPixels;
}

+ (double *)createGaussianWindow:(int)size sigma:(double)sigma {
    double *window = malloc(size * size * sizeof(double));
    double sum = 0.0;
    int center = size / 2;
    
    for (int y = 0; y < size; y++) {
        for (int x = 0; x < size; x++) {
            double dx = x - center;
            double dy = y - center;
            double value = exp(-(dx * dx + dy * dy) / (2 * sigma * sigma));
            window[y * size + x] = value;
            sum += value;
        }
    }
    
    // 归一化
    for (int i = 0; i < size * size; i++) {
        window[i] /= sum;
    }
    
    return window;
}

+ (float *)computeHSVHistogram:(UIImage *)image hBins:(int)hBins sBins:(int)sBins vBins:(int)vBins {
    CGImageRef cgImage = image.CGImage;
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    
    uint32_t *pixels = [self getARGBPixelData:image];
    if (!pixels) return NULL;
    
    int totalBins = hBins * sBins * vBins;
    float *histogram = calloc(totalBins, sizeof(float));
    NSInteger totalPixels = width * height;
    
    for (int i = 0; i < totalPixels; i++) {
        uint32_t pixel = pixels[i];
        uint8_t r = (pixel >> 16) & 0xFF;
        uint8_t g = (pixel >> 8) & 0xFF;
        uint8_t b = pixel & 0xFF;
        
        // 转换为HSV
        float h, s, v;
        [self rgbToHSV:r g:g b:b h:&h s:&s v:&v];
        
        int hBin = (int)(h * hBins);
        int sBin = (int)(s * sBins);
        int vBin = (int)(v * vBins);
        
        hBin = MIN(hBins - 1, MAX(0, hBin));
        sBin = MIN(sBins - 1, MAX(0, sBin));
        vBin = MIN(vBins - 1, MAX(0, vBin));
        
        int index = (hBin * sBins + sBin) * vBins + vBin;
        histogram[index] += 1.0;
    }
    
    // 归一化
    for (int i = 0; i < totalBins; i++) {
        histogram[i] /= totalPixels;
    }
    
    free(pixels);
    return histogram;
}

+ (void)rgbToHSV:(uint8_t)r g:(uint8_t)g b:(uint8_t)b h:(float *)h s:(float *)s v:(float *)v {
    float rf = r / 255.0f;
    float gf = g / 255.0f;
    float bf = b / 255.0f;
    
    float max = fmaxf(fmaxf(rf, gf), bf);
    float min = fminf(fminf(rf, gf), bf);
    float delta = max - min;
    
    // Value
    *v = max;
    
    // Saturation
    if (max < 1e-5) {
        *s = 0;
    } else {
        *s = delta / max;
    }
    
    // Hue
    if (delta < 1e-5) {
        *h = 0;
    } else if (max == rf) {
        *h = 60 * fmodf((gf - bf) / delta, 6);
    } else if (max == gf) {
        *h = 60 * ((bf - rf) / delta + 2);
    } else {
        *h = 60 * ((rf - gf) / delta + 4);
    }
    
    if (*h < 0) {
        *h += 360;
    }
    *h /= 360; // 归一化到[0,1]
}

#pragma mark - 工具方法
+ (unsigned char *)convertToGrayPixels:(UIImage *)image {
    CGImageRef cgImage = image.CGImage;
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    
    unsigned char *grayPixels = malloc(width * height);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(grayPixels, width, height, 8, width, colorSpace, kCGImageAlphaNone);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    return grayPixels;
}

+ (uint32_t *)getARGBPixelData:(UIImage *)image {
    CGImageRef cgImage = image.CGImage;
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    
    uint32_t *pixels = malloc(width * height * sizeof(uint32_t));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * 4, colorSpace,
                                               kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    return pixels;
}

+ (float *)computeRGBHistogram:(UIImage *)image bins:(int)bins {
    CGImageRef cgImage = image.CGImage;
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    
    uint32_t *pixels = [self getARGBPixelData:image];
    if (!pixels) return NULL;
    
    int totalBins = bins * bins * bins;
    float *histogram = calloc(totalBins, sizeof(float));
    NSInteger totalPixels = width * height;
    
    for (int i = 0; i < totalPixels; i++) {
        uint32_t pixel = pixels[i];
        uint8_t r = (pixel >> 16) & 0xFF;
        uint8_t g = (pixel >> 8) & 0xFF;
        uint8_t b = pixel & 0xFF;
        
        int rBin = r * bins / 256;
        int gBin = g * bins / 256;
        int bBin = b * bins / 256;
        int index = (rBin * bins + gBin) * bins + bBin;
        
        histogram[index] += 1.0;
    }
    
    // 归一化
    for (int i = 0; i < totalBins; i++) {
        histogram[i] /= totalPixels;
    }
    
    free(pixels);
    return histogram;
}

+ (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}
@end
