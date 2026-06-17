//
//  UIImage+Confusion.m
//  BaseFrame
//
//  Created by King on 2025/9/26.
//

#import "UIImage+Confusion.h"
#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "BFWordsRackTool.h"
@implementation UIImage (Confusion)

+ (BOOL)processProjectImagesAtPath:(NSString *)projectPath intensity:(CGFloat)intensity {
    if (!projectPath || intensity <= 0) {
        NSLog(@"Invalid parameters: projectPath:%@, intensity:%f", projectPath, intensity);
        return NO;
    }
    
    // 确保路径存在
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:projectPath isDirectory:&isDirectory] || !isDirectory) {
        NSLog(@"Project path does not exist or is not a directory: %@", projectPath);
        return NO;
    }

    // 创建混淆图片输出目录
    NSString *confusedOutputPath = @"/Users/wangxiangwei/Desktop/大图_副本";
    if (![self createConfusedOutputDirectory:confusedOutputPath]) {
        NSLog(@"Failed to create confused output directory: %@", confusedOutputPath);
        return NO;
    }

    // 支持的图片格式
    NSSet *supportedImageExtensions = [NSSet setWithObjects:@"png", @"jpg", @"jpeg", @"gif", @"bmp", @"tiff", @"webp", nil];
    
    // 递归遍历项目目录
    BOOL success = YES;
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:projectPath error:nil];
    
    for (NSString *item in contents) {
        NSString *fullPath = [projectPath stringByAppendingPathComponent:item];
        
        BOOL isDirectory;
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory]) {
            if (isDirectory) {
                // 检查是否是 .imageset 目录
                if ([[item pathExtension] isEqualToString:@"imageset"]) {
                    BOOL imagesetSuccess = [self processImagesetAtPath:fullPath intensity:intensity confusedOutputPath:confusedOutputPath];
                    if (!imagesetSuccess) {
                        success = NO;
                    }
                } else {
                    // 递归处理子目录（跳过 .imageset 目录的重复处理）
                    if (![self isImagesetDirectory:fullPath]) {
                        BOOL subSuccess = [self processProjectImagesAtPath:fullPath intensity:intensity];
                        if (!subSuccess) {
                            success = NO;
                        }
                    }
                }
            } else {
                // 处理文件
                NSString *fileExtension = [[item pathExtension] lowercaseString];
                if ([supportedImageExtensions containsObject:fileExtension]) {
                    // 检查文件是否在 .imageset 目录中，如果是则跳过（避免重复处理）
                    if (![self isInImagesetDirectory:fullPath]) {
                        BOOL fileSuccess = [self processImageAtPath:fullPath intensity:intensity confusedOutputPath:confusedOutputPath];
                        if (!fileSuccess) {
                            success = NO;
                            NSLog(@"Failed to process image: %@", fullPath);
                        }
                    }
                }
            }
        }
    }
    
    return success;
}

// 创建混淆图片输出目录
+ (BOOL)createConfusedOutputDirectory:(NSString *)outputPath {
    BOOL isDirectory;
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath isDirectory:&isDirectory]) {
        if (isDirectory) {
            return YES; // 目录已存在
        } else {
            // 存在同名文件，删除它
            [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
        }
    }
    
    // 创建目录
    NSError *error;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:outputPath
                                             withIntermediateDirectories:YES
                                                              attributes:nil
                                                                   error:&error];
    if (!success) {
        NSLog(@"Failed to create output directory: %@", error);
    }
    return success;
}

// 专门处理 .imageset 目录
+ (BOOL)processImagesetAtPath:(NSString *)imagesetPath intensity:(CGFloat)intensity confusedOutputPath:(NSString *)confusedOutputPath {
    if (!imagesetPath || ![[NSFileManager defaultManager] fileExistsAtPath:imagesetPath]) {
        return NO;
    }
    
    // 检查 Contents.json 文件是否存在
    NSString *contentsJsonPath = [imagesetPath stringByAppendingPathComponent:@"Contents.json"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:contentsJsonPath]) {
        NSLog(@"Not a valid imageset directory (missing Contents.json): %@", imagesetPath);
        return NO;
    }
    
    NSLog(@"Processing imageset: %@", imagesetPath);
    
    // 支持的图片格式
    NSSet *supportedImageExtensions = [NSSet setWithObjects:@"png", @"jpg", @"jpeg", @"gif", @"bmp", @"tiff", @"webp", nil];
    
    BOOL success = YES;
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:imagesetPath error:nil];
    
    for (NSString *item in contents) {
        NSString *fullPath = [imagesetPath stringByAppendingPathComponent:item];
        
        BOOL isDirectory;
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory] && !isDirectory) {
            NSString *fileExtension = [[item pathExtension] lowercaseString];
            if ([supportedImageExtensions containsObject:fileExtension]) {
                // 处理图片文件
                BOOL fileSuccess = [self processImageInImageset:fullPath imagesetPath:imagesetPath intensity:intensity confusedOutputPath:confusedOutputPath];
                if (!fileSuccess) {
                    success = NO;
                    NSLog(@"Failed to process image in imageset: %@", fullPath);
                }
            }
        }
    }
    
    return success;
}

// 在 .imageset 目录中处理图片
+ (BOOL)processImageInImageset:(NSString *)imagePath imagesetPath:(NSString *)imagesetPath intensity:(CGFloat)intensity confusedOutputPath:(NSString *)confusedOutputPath {
    NSString *fileExtension = [[imagePath pathExtension] lowercaseString];
    
    // 处理GIF图片 - 不进行压缩，只进行混淆
    if ([fileExtension isEqualToString:@"gif"]) {
        NSLog(@"Processing GIF image in imageset (compression skipped): %@", imagePath);
        return [self createConfusedImageAtPath:imagePath intensity:intensity confusedOutputPath:confusedOutputPath];
    }
    
    // 压缩并处理其他图片格式
    return [self compressAndConfuseImageAtPath:imagePath intensity:intensity confusedOutputPath:confusedOutputPath];
}

// 处理普通图片
+ (BOOL)processImageAtPath:(NSString *)imagePath intensity:(CGFloat)intensity confusedOutputPath:(NSString *)confusedOutputPath {
    if (!imagePath || ![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
        return NO;
    }
    
    NSString *fileExtension = [[imagePath pathExtension] lowercaseString];
    
    // 处理GIF图片 - 不进行压缩，只进行混淆
    if ([fileExtension isEqualToString:@"gif"]) {
        NSLog(@"Processing GIF image (compression skipped): %@", imagePath);
        return [self createConfusedImageAtPath:imagePath intensity:intensity confusedOutputPath:confusedOutputPath];
    }
    
    // 压缩并处理其他图片格式
    return [self compressAndConfuseImageAtPath:imagePath intensity:intensity confusedOutputPath:confusedOutputPath];
}


// 压缩和混淆图片（统一方法）- 修复尺寸问题
+ (BOOL)compressAndConfuseImageAtPath:(NSString *)imagePath intensity:(CGFloat)intensity confusedOutputPath:(NSString *)confusedOutputPath {
    // 读取原始图片
    UIImage *originalImage = [UIImage imageWithContentsOfFile:imagePath];
    if (!originalImage) {
        NSLog(@"Failed to load image: %@", imagePath);
        return NO;
    }
    
    // 获取原始图片尺寸
    CGSize originalSize = originalImage.size;
    NSLog(@"Original image size: %.0fx%.0f", originalSize.width, originalSize.height);
    
    // 获取原始文件属性
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:imagePath error:nil];
    NSNumber *fileSize = fileAttributes[NSFileSize];
    NSLog(@"Original file size: %@ bytes", fileSize);
    
    // 高质量压缩（保持尺寸不变）
    NSData *compressedData = [self compressImage:originalImage intensity:intensity originalPath:imagePath];
    if (!compressedData || compressedData.length == 0) {
        NSLog(@"Compression failed for image: %@", imagePath);
        return NO;
    }
    
    NSLog(@"Compressed file size: %lu bytes (reduction: %.1f%%)",
          (unsigned long)compressedData.length,
          (1.0 - (double)compressedData.length / fileSize.doubleValue) * 100.0);
    
    // 备份原始图片
    NSString *backupPath = [self backupOriginalImage:imagePath];
    if (!backupPath) {
        NSLog(@"Failed to backup original image: %@", imagePath);
        return NO;
    }
    
    // 用压缩后的图片替换原图
    BOOL replaceSuccess = [compressedData writeToFile:imagePath atomically:YES];
    if (!replaceSuccess) {
        NSLog(@"Failed to replace original image with compressed version: %@", imagePath);
        // 恢复备份
        [self restoreImageFromBackup:backupPath toPath:imagePath];
        return NO;
    }
    
    // 验证压缩后图片尺寸
    UIImage *compressedImage = [UIImage imageWithContentsOfFile:imagePath];
    if (!compressedImage) {
        NSLog(@"Failed to load compressed image for verification: %@", imagePath);
        [self restoreImageFromBackup:backupPath toPath:imagePath];
        return NO;
    }
    
    if (!CGSizeEqualToSize(originalSize, compressedImage.size)) {
        NSLog(@"❌ 压缩后图片尺寸改变: 原始 %.0fx%.0f -> 压缩后 %.0fx%.0f",
              originalSize.width, originalSize.height,
              compressedImage.size.width, compressedImage.size.height);
        [self restoreImageFromBackup:backupPath toPath:imagePath];
        return NO;
    }
    
    // 在指定目录中创建混淆图片
    BOOL confuseSuccess = [self createConfusedImageFromBackup:backupPath originalPath:imagePath intensity:intensity confusedOutputPath:confusedOutputPath];
    
    // 清理备份文件
    [[NSFileManager defaultManager] removeItemAtPath:backupPath error:nil];
    
    return confuseSuccess;
}

// 智能PNG压缩 - 修复尺寸问题
+ (NSData *)smartPNGCompression:(UIImage *)image intensity:(CGFloat)intensity originalPath:(NSString *)originalPath {
    // 读取原始文件大小
    NSData *originalData = [NSData dataWithContentsOfFile:originalPath];
    NSUInteger originalSize = originalData.length;
    
    // 策略1：如果强度高，尽量保持原质量
    if (intensity > 0.8) {
        // 只进行轻微优化，不改变尺寸
        NSData *optimized = [self optimizePNGWithMinimalChanges:image];
        if (optimized.length < originalSize * 1.1) { // 增加不超过10%
            return optimized;
        }
        return originalData; // 如果优化后更大，返回原数据
    }
    
    // 策略2：中等强度，使用质量压缩但不改变尺寸
    if (intensity > 0.5) {
        return [self compressPNGByQuality:image intensity:intensity];
    }
    
    // 策略3：低强度，轻微质量压缩
    return [self compressPNGByQuality:image intensity:intensity];
}

// PNG质量压缩（不改变尺寸）
+ (NSData *)compressPNGByQuality:(UIImage *)image intensity:(CGFloat)intensity {
    @autoreleasepool {
        // 使用ImageIO进行可控的PNG压缩
        NSMutableData *data = [NSMutableData data];
        CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)data, kUTTypePNG, 1, NULL);
        
        if (destination) {
            // 根据强度设置压缩参数
            CGFloat compressionLevel = 1.0 - (intensity * 0.3); // 0.7-1.0
            compressionLevel = MAX(0.1, MIN(1.0, compressionLevel));
            
            NSDictionary *options = @{
                (__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @(compressionLevel),
                (__bridge NSString *)kCGImagePropertyPNGCompressionFilter: @(6) // 自适应压缩
            };
            
            CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef)options);
            CGImageDestinationFinalize(destination);
            CFRelease(destination);
            
            return [data copy];
        }
    }
    
    // 降级方案：使用UIImagePNGRepresentation
    return UIImagePNGRepresentation(image);
}

// 创建混淆图片（核心方法）- 修复尺寸问题
+ (BOOL)createConfusedImage:(UIImage *)originalImage atPath:(NSString *)originalPath intensity:(CGFloat)intensity confusedOutputPath:(NSString *)confusedOutputPath {
    // 生成混淆图片路径（在指定输出目录中）
    NSString *confusedPath = [self confusedImagePathForPath:originalPath confusedOutputPath:confusedOutputPath];
    if (!confusedPath) {
        return NO;
    }
    
    // 记录原始尺寸
    CGSize originalSize = originalImage.size;
    NSLog(@"创建混淆图片 - 原始尺寸: %.0fx%.0f, 路径: %@", originalSize.width, originalSize.height, confusedPath);
    
    // 应用多种混淆技术（保持尺寸）
    UIImage *confusedImage = [self applyConfusionTechniques:originalImage intensity:intensity];
    if (!confusedImage) {
        return NO;
    }
    
    // 验证混淆后图片尺寸
    if (!CGSizeEqualToSize(originalSize, confusedImage.size)) {
        NSLog(@"❌ 混淆后图片尺寸改变: 原始 %.0fx%.0f -> 混淆后 %.0fx%.0f",
              originalSize.width, originalSize.height,
              confusedImage.size.width, confusedImage.size.height);
        // 调整尺寸回原始尺寸
        confusedImage = [self resizeImage:confusedImage toSize:originalSize];
    }
    
    // 保存混淆图片
    NSString *fileExtension = [[originalPath pathExtension] lowercaseString];
    NSData *outputData = nil;
    
    if ([fileExtension isEqualToString:@"png"]) {
        outputData = UIImagePNGRepresentation(confusedImage);
    } else if ([fileExtension isEqualToString:@"gif"]) {
        // 对于GIF，保持原始数据
        outputData = [NSData dataWithContentsOfFile:originalPath];
    } else {
        outputData = UIImageJPEGRepresentation(confusedImage, 0.9);
    }
    
    BOOL success = [outputData writeToFile:confusedPath atomically:YES];
    
    if (success) {
        // 验证保存的图片尺寸
        UIImage *savedImage = [UIImage imageWithContentsOfFile:confusedPath];
        if (savedImage && !CGSizeEqualToSize(originalSize, savedImage.size)) {
            NSLog(@"⚠️ 保存的混淆图片尺寸不一致: %.0fx%.0f", savedImage.size.width, savedImage.size.height);
        }
        NSLog(@"✅ 成功创建混淆图片: %@ (尺寸: %.0fx%.0f)", confusedPath, originalSize.width, originalSize.height);
    } else {
        NSLog(@"❌ 创建混淆图片失败: %@", confusedPath);
    }
    
    return success;
}

// 调整图片尺寸到指定大小
+ (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)targetSize {
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, image.scale);
    [image drawInRect:CGRectMake(0, 0, targetSize.width, targetSize.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

// 高质量颜色调整 - 修复尺寸问题
+ (UIImage *)applyHighQualityColorAdjustment:(UIImage *)image intensity:(CGFloat)intensity {
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    
    CIFilter *colorControls = [CIFilter filterWithName:@"CIColorControls"];
    [colorControls setValue:ciImage forKey:kCIInputImageKey];
    [colorControls setValue:@(1.0 + intensity * 0.3) forKey:kCIInputContrastKey];
    [colorControls setValue:@(intensity * 0.1) forKey:kCIInputBrightnessKey];
    [colorControls setValue:@(1.0 + intensity * 0.4) forKey:kCIInputSaturationKey];
    
    CIFilter *vibrance = [CIFilter filterWithName:@"CIVibrance"];
    [vibrance setValue:[colorControls valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
    [vibrance setValue:@(intensity * 0.8) forKey:@"inputAmount"];
    
    CIImage *outputImage = [vibrance valueForKey:kCIOutputImageKey];
    
    CIContext *context = [CIContext contextWithOptions:@{
        kCIContextUseSoftwareRenderer: @NO,
        kCIContextHighQualityDownsample: @YES,
    }];
    
    // 使用原始图片的尺寸和scale
    CGRect outputRect = CGRectMake(0, 0, image.size.width * image.scale, image.size.height * image.scale);
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:outputRect];
    UIImage *resultImage = [UIImage imageWithCGImage:cgImage scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(cgImage);
    
    return resultImage;
}

// 纹理合成增强 - 修复尺寸问题
+ (UIImage *)applyTextureEnhancement:(UIImage *)image intensity:(CGFloat)intensity {
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    
    CIFilter *noiseFilter = [CIFilter filterWithName:@"CIRandomGenerator"];
    CIImage *noiseImage = [noiseFilter valueForKey:kCIOutputImageKey];
    
    // 裁剪噪声图像到原始图片尺寸
    CGRect imageRect = CGRectMake(0, 0, image.size.width * image.scale, image.size.height * image.scale);
    noiseImage = [noiseImage imageByCroppingToRect:imageRect];
    
    CIFilter *blendFilter = [CIFilter filterWithName:@"CISoftLightBlendMode"];
    [blendFilter setValue:ciImage forKey:kCIInputImageKey];
    [blendFilter setValue:noiseImage forKey:kCIInputBackgroundImageKey];
    
    CIImage *outputImage = [blendFilter valueForKey:kCIOutputImageKey];
    
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer: @NO}];
    
    // 使用原始图片的尺寸
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:imageRect];
    UIImage *resultImage = [UIImage imageWithCGImage:cgImage scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(cgImage);
    
    return resultImage;
}

// 光学效果处理 - 修复尺寸问题
+ (UIImage *)applyOpticalEffects:(UIImage *)image intensity:(CGFloat)intensity {
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    
    if (intensity > 0.3) {
        CIFilter *bloomFilter = [CIFilter filterWithName:@"CIBloom"];
        [bloomFilter setValue:ciImage forKey:kCIInputImageKey];
        [bloomFilter setValue:@(intensity * 0.8) forKey:kCIInputRadiusKey];
        [bloomFilter setValue:@(intensity * 0.4) forKey:kCIInputIntensityKey];
        ciImage = [bloomFilter valueForKey:kCIOutputImageKey];
    }
    
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer: @NO}];
    
    // 使用原始图片的尺寸
    CGRect imageRect = CGRectMake(0, 0, image.size.width * image.scale, image.size.height * image.scale);
    CGImageRef cgImage = [context createCGImage:ciImage fromRect:imageRect];
    UIImage *resultImage = [UIImage imageWithCGImage:cgImage scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(cgImage);
    
    return resultImage;
}

// 检查是否是 .imageset 目录
+ (BOOL)isImagesetDirectory:(NSString *)path {
    NSString *currentPath = path;
    while (![currentPath isEqualToString:[currentPath stringByDeletingLastPathComponent]]) {
        if ([[currentPath pathExtension] isEqualToString:@"imageset"]) {
            return YES;
        }
        currentPath = [currentPath stringByDeletingLastPathComponent];
        if ([currentPath isEqualToString:@"/"]) break;
    }
    return NO;
}

// 检查文件是否在 .imageset 目录中
+ (BOOL)isInImagesetDirectory:(NSString *)filePath {
    return [self isImagesetDirectory:[filePath stringByDeletingLastPathComponent]];
}

+ (BOOL)createConfusedImageAtPath:(NSString *)imagePath intensity:(CGFloat)intensity confusedOutputPath:(NSString *)confusedOutputPath {
    UIImage *originalImage = [UIImage imageWithContentsOfFile:imagePath];
    if (!originalImage) {
        return NO;
    }
    
    return [self createConfusedImage:originalImage atPath:imagePath intensity:intensity confusedOutputPath:confusedOutputPath];
}

+ (NSString *)confusedImagePathForPath:(NSString *)originalPath confusedOutputPath:(NSString *)confusedOutputPath {
    NSString *originalFilename = [originalPath lastPathComponent];
    NSString *extension = [originalPath pathExtension];
    
    NSString *filenameWithoutExt = [originalFilename stringByDeletingPathExtension];
    
    // 处理分辨率标识
    NSString *scaleSuffix = @"";
    NSString *baseFilename = filenameWithoutExt;
    
    if ([filenameWithoutExt hasSuffix:@"@3x"]) {
        scaleSuffix = @"@3x";
        baseFilename = [filenameWithoutExt substringToIndex:filenameWithoutExt.length - 3];
    } else if ([filenameWithoutExt hasSuffix:@"@2x"]) {
        scaleSuffix = @"@2x";
        baseFilename = [filenameWithoutExt substringToIndex:filenameWithoutExt.length - 3];
    } else if ([filenameWithoutExt hasSuffix:@"@1x"]) {
        scaleSuffix = @"@1x";
        baseFilename = [filenameWithoutExt substringToIndex:filenameWithoutExt.length - 3];
    }
    
    // 生成混淆文件名
    NSString *randomProperty = BFWordsRackTool.propertyNames[arc4random_uniform((uint32_t)BFWordsRackTool.propertyNames.count)];
    NSString *confusedFilename = [NSString stringWithFormat:@"%@%@%@.%@", baseFilename, randomProperty, scaleSuffix, extension];
    
    // 确保使用指定的输出路径
    return [confusedOutputPath stringByAppendingPathComponent:confusedFilename];
}

+ (BOOL)restoreImageFromBackup:(NSString *)backupPath toPath:(NSString *)targetPath {
    NSError *error;
    BOOL success = [[NSFileManager defaultManager] copyItemAtPath:backupPath toPath:targetPath error:&error];
    
    if (!success) {
        NSLog(@"Restore failed: %@", error);
    }
    
    return success;
}

+ (BOOL)createConfusedImageFromBackup:(NSString *)backupPath originalPath:(NSString *)originalPath intensity:(CGFloat)intensity confusedOutputPath:(NSString *)confusedOutputPath {
    UIImage *originalImage = [UIImage imageWithContentsOfFile:backupPath];
    if (!originalImage) {
        return NO;
    }
    
    return [self createConfusedImage:originalImage atPath:originalPath intensity:intensity confusedOutputPath:confusedOutputPath];
}

+ (NSData *)compressImage:(UIImage *)image intensity:(CGFloat)intensity originalPath:(NSString *)originalPath {
    CGFloat compressionIntensity = MAX(0.1, MIN(1.0, intensity));
    NSString *fileExtension = [[originalPath pathExtension] lowercaseString];
    
    if ([fileExtension isEqualToString:@"png"]) {
        // 对于PNG，使用更智能的压缩策略
        return [self smartPNGCompression:image intensity:compressionIntensity originalPath:originalPath];
    } else {
        // JPEG使用质量压缩
        CGFloat quality = 0.6 + (compressionIntensity * 0.3);
        return UIImageJPEGRepresentation(image, quality);
    }
}

+ (NSString *)backupOriginalImage:(NSString *)imagePath {
    NSString *backupPath = [imagePath stringByAppendingString:@".backup"];
    
    NSError *error;
    BOOL success = [[NSFileManager defaultManager] copyItemAtPath:imagePath toPath:backupPath error:&error];
    
    if (!success) {
        NSLog(@"Backup failed: %@", error);
        return nil;
    }
    
    return backupPath;
}


+ (NSData *)optimizePNGWithMinimalChanges:(UIImage *)image {
    @autoreleasepool {
        CGImageRef imageRef = image.CGImage;
        NSMutableData *data = [NSMutableData data];
        CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)data, kUTTypePNG, 1, NULL);
        
        if (destination) {
            NSDictionary *options = @{
                (__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @(0.9),
                (__bridge NSString *)kCGImagePropertyPNGCompressionFilter: @(5)
            };
            
            CGImageDestinationAddImage(destination, imageRef, (__bridge CFDictionaryRef)options);
            CGImageDestinationFinalize(destination);
            CFRelease(destination);
            
            return [data copy];
        }
    }
    
    return UIImagePNGRepresentation(image);
}

+ (UIImage *)applyConfusionTechniques:(UIImage *)image intensity:(CGFloat)intensity {
    UIImage *currentImage = image;
    
    // 1. 高质量颜色增强
    UIImage *image1 = [self applyHighQualityColorAdjustment:currentImage intensity:intensity];
    if (image1) currentImage = image1;
    
    // 2. 智能像素重排列
    UIImage *image2 = [self applySmartPixelRearrangement:currentImage intensity:intensity];
    if (image2) currentImage = image2;
    
    // 3. 纹理合成增强
    UIImage *image3 = [self applyTextureEnhancement:currentImage intensity:intensity];
    if (image3) currentImage = image3;
    
    // 4. 光学效果处理
    UIImage *image4 = [self applyOpticalEffects:currentImage intensity:intensity];
    if (image4) currentImage = image4;

    return currentImage ?: image;
}

+ (UIImage *)applySmartPixelRearrangement:(UIImage *)image intensity:(CGFloat)intensity {
    CGImageRef imageRef = image.CGImage;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    if (!context) {
        return image;
    }
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    UInt8 *rawData = (UInt8 *)CGBitmapContextGetData(context);
    
    if (!rawData) {
        CGContextRelease(context);
        return image;
    }
    
    NSInteger blockSize = 8 + (NSInteger)(intensity * 16);
    NSInteger maxDisplacement = 4 + (NSInteger)(intensity * 12);
    
    for (NSInteger y = 0; y < height; y += blockSize) {
        for (NSInteger x = 0; x < width; x += blockSize) {
            NSInteger dx = (arc4random_uniform(2 * maxDisplacement + 1) - maxDisplacement);
            NSInteger dy = (arc4random_uniform(2 * maxDisplacement + 1) - maxDisplacement);
            
            NSInteger newX = MAX(0, MIN(width - blockSize, x + dx));
            NSInteger newY = MAX(0, MIN(height - blockSize, y + dy));
            
            [self swapPixelBlockFromX:x fromY:y toX:newX toY:newY
                            blockSize:blockSize width:width height:height
                             rawData:rawData bytesPerRow:bytesPerRow];
        }
    }
    
    CGImageRef rearrangedImageRef = CGBitmapContextCreateImage(context);
    UIImage *resultImage = [UIImage imageWithCGImage:rearrangedImageRef scale:image.scale orientation:image.imageOrientation];
    
    CGContextRelease(context);
    CGImageRelease(rearrangedImageRef);
    
    return resultImage;
}

// 像素块交换
+ (void)swapPixelBlockFromX:(NSInteger)fromX fromY:(NSInteger)fromY
                        toX:(NSInteger)toX toY:(NSInteger)toY
                  blockSize:(NSInteger)blockSize width:(NSInteger)width height:(NSInteger)height
                   rawData:(UInt8 *)rawData bytesPerRow:(size_t)bytesPerRow {
    
    for (NSInteger y = 0; y < blockSize; y++) {
        for (NSInteger x = 0; x < blockSize; x++) {
            NSInteger srcX = fromX + x;
            NSInteger srcY = fromY + y;
            NSInteger dstX = toX + x;
            NSInteger dstY = toY + y;
            
            if (srcX < width && srcY < height && dstX < width && dstY < height) {
                size_t srcIndex = (bytesPerRow * srcY) + srcX * 4;
                size_t dstIndex = (bytesPerRow * dstY) + dstX * 4;
                
                if (srcIndex + 3 < bytesPerRow * height && dstIndex + 3 < bytesPerRow * height) {
                    UInt8 temp[4];
                    memcpy(temp, &rawData[srcIndex], 4);
                    memcpy(&rawData[srcIndex], &rawData[dstIndex], 4);
                    memcpy(&rawData[dstIndex], temp, 4);
                }
            }
        }
    }
}

@end

