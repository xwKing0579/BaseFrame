//
//  BFConfuseImage.m
//  BaseFrame
//
//  Created by 王祥伟 on 2025/5/2.
//

#import "BFConfuseImage.h"
#import "BFConfuseManager.h"
#import <ImageIO/ImageIO.h>
#import <CommonCrypto/CommonCrypto.h>
#import <Accelerate/Accelerate.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "UIImage+Compare.h"
@implementation BFConfuseImage


+ (NSDictionary *)mapImageDict{
    return [self parseModuleMappingJSON:@"imageName_jingyuege"];
}

+ (NSDictionary *)mapImageDict1{
    return [self parseModuleMappingJSON:@"imageName_xixi"];
}

+ (NSDictionary *)mapImageDict4{
    return [self parseModuleMappingJSON:@"imageName_jingyuege"];
}

+ (void)renameAssetsInDirectory:(NSString *)directory{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    
    // 获取目录内容，增加错误处理
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:directory error:&error];
    if (error) {
        NSLog(@"Error reading directory: %@", error.localizedDescription);
        return;
    }
    
    BOOL isDirectory;
    for (NSString *fileName in files) {
        @autoreleasepool {
            NSString *filePath = [directory stringByAppendingPathComponent:fileName];
            
            // 检查是否是目录
            if ([fm fileExistsAtPath:filePath isDirectory:&isDirectory] && isDirectory) {
                [self renameAssetsInDirectory:filePath];
                continue;
            }
            
            // 只处理 Contents.json 文件
            if (![fileName isEqualToString:@"Contents.json"]) continue;
            
            // 检查是否在 .imageset 目录中
            NSString *contentsDirectoryName = filePath.stringByDeletingLastPathComponent.lastPathComponent;
            if (![contentsDirectoryName hasSuffix:@".imageset"]) continue;
            
            // 读取文件内容
            NSString *fileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
            if (!fileContent || error) {
                NSLog(@"Error reading file: %@", error.localizedDescription);
                continue;
            }
            
            // 使用更精确的JSON解析代替正则表达式
            NSData *jsonData = [fileContent dataUsingEncoding:NSUTF8StringEncoding];
            NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
            if (!jsonDict || error) {
                NSLog(@"Error parsing JSON: %@", error.localizedDescription);
                continue;
            }
            
            // 处理images数组
            NSMutableArray *images = jsonDict[@"images"];
            BOOL modified = NO;
            
            for (NSMutableDictionary *imageInfo in images) {
                NSString *originalName = imageInfo[@"filename"];
                if (!originalName) continue;
                
                NSString *originalPath = [filePath.stringByDeletingLastPathComponent stringByAppendingPathComponent:originalName];
                if (![fm fileExistsAtPath:originalPath]) continue;
                
                // 生成唯一新文件名
                NSString *extension = originalName.pathExtension;
                NSString *newName = [self generateUniqueFilenameWithExtension:extension inDirectory:filePath.stringByDeletingLastPathComponent];
                NSString *newPath = [filePath.stringByDeletingLastPathComponent stringByAppendingPathComponent:newName];
                
                // 重命名文件
                if ([fm moveItemAtPath:originalPath toPath:newPath error:&error]) {
                    imageInfo[@"filename"] = newName;
                    modified = YES;
                } else {
                    NSLog(@"Error renaming file: %@", error.localizedDescription);
                }
            }
            
            // 如果有修改，写回文件
            if (modified) {
                NSData *updatedData = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&error];
                if (updatedData) {
                    [updatedData writeToFile:filePath atomically:YES];
                } else {
                    NSLog(@"Error serializing JSON: %@", error.localizedDescription);
                }
            }
        }
    }
}

// 生成唯一文件名
+ (NSString *)generateUniqueFilenameWithExtension:(NSString *)extension inDirectory:(NSString *)directory {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *filename;
    NSUInteger attempt = 0;
    do {
        NSString *imagePrefix = @"img_";
        filename = [NSString stringWithFormat:@"%@%08x",imagePrefix,arc4random_uniform(0xFFFFFFFF)];
        if (extension.length) {
            filename = [filename stringByAppendingPathExtension:extension];
        }
        attempt++;
    } while ([fm fileExistsAtPath:[directory stringByAppendingPathComponent:filename]] && attempt < 100);
    
    return filename;
}



+ (void)renameImageAssetsAndCodeReferencesInProject:(NSString *)projectDirectory
                                      renameMapping:(NSDictionary<NSString *, NSString *> *)renameMapping {
    
    NSString *methodMap = [BFConfuseManager readObfuscationMappingFileAtPath:projectDirectory name:@"图片名映射"];
    if (methodMap){
        NSData *jsonData = [methodMap dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
        renameMapping = dict;
    }
    
    NSString *assetsPath = [self findAssetsPathInDirectory:projectDirectory];
    if (!assetsPath) {
        NSLog(@"❌ Assets.xcassets 目录未找到，请检查项目结构");
        return;
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:assetsPath]) {
        [self renameImageAssetsInDirectory:assetsPath renameMapping:renameMapping];
    }
    
    // 2. 然后更新代码中的引用
    [self updateCodeReferencesInDirectory:projectDirectory renameMapping:renameMapping];
    
    [BFConfuseManager writeData:renameMapping toPath:projectDirectory fileName:@"混淆/图片名映射"];
}

+ (NSString *)findAssetsPathInDirectory:(NSString *)directory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directory];
    
    NSString *filePath;
    while ((filePath = [enumerator nextObject]) != nil) {
        if ([[filePath lastPathComponent] isEqualToString:@"Assets.xcassets"]) {
            return [directory stringByAppendingPathComponent:filePath];
        }
    }
    return nil;
}

#pragma mark - 资源文件重命名

+ (void)renameImageAssetsInDirectory:(NSString *)assetsDirectoryPath
                       renameMapping:(NSDictionary<NSString *, NSString *> *)renameMapping {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:assetsDirectoryPath];
    
    // 先收集所有需要重命名的.imageset目录
    NSMutableDictionary *imageSetsToRename = [NSMutableDictionary dictionary];
    
    NSString *filePath;
    while ((filePath = [enumerator nextObject]) != nil) {
        @autoreleasepool {
            NSString *fullPath = [assetsDirectoryPath stringByAppendingPathComponent:filePath];
            BOOL isDirectory;
            [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
            
            // 只处理.imageset目录
            if (isDirectory && [[filePath pathExtension] isEqualToString:@"imageset"]) {
                NSString *imageSetName = [filePath.lastPathComponent stringByDeletingPathExtension];
                NSString *baseName = [self baseNameFromImageName:imageSetName];
                
                // 检查是否需要重命名这个.imageset目录
                NSString *newBaseName = renameMapping[baseName];
                if (newBaseName) {
                    NSString *newImageSetName = [self applyScaleSuffix:[self scaleSuffixFromImageName:imageSetName]
                                                            toBaseName:newBaseName];
                    imageSetsToRename[fullPath] = newImageSetName;
                }
            }
        }
    }
    
    // 先重命名.imageset目录（避免处理过程中路径变化）
    for (NSString *oldImageSetPath in imageSetsToRename.allKeys) {
        NSString *newImageSetName = imageSetsToRename[oldImageSetPath];
        NSString *newImageSetPath = [[oldImageSetPath stringByDeletingLastPathComponent]
                                     stringByAppendingPathComponent:
                                         [newImageSetName stringByAppendingPathExtension:@"imageset"]];
        
        // 跳过同名目录（不需要重命名）
        if ([oldImageSetPath isEqualToString:newImageSetPath]) {
            continue;
        }
        
        NSError *error;
        if ([fileManager moveItemAtPath:oldImageSetPath toPath:newImageSetPath error:&error]) {
            NSLog(@"✅ Renamed .imageset directory: %@ -> %@",
                  oldImageSetPath.lastPathComponent,
                  newImageSetPath.lastPathComponent);
        } else {
            NSLog(@"❌ Failed to rename .imageset directory %@: %@",
                  oldImageSetPath.lastPathComponent,
                  error.localizedDescription);
        }
    }
    
    // 然后处理每个.imageset目录内部的内容
    enumerator = [fileManager enumeratorAtPath:assetsDirectoryPath];
    while ((filePath = [enumerator nextObject]) != nil) {
        @autoreleasepool {
            NSString *fullPath = [assetsDirectoryPath stringByAppendingPathComponent:filePath];
            BOOL isDirectory;
            [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
            
            if (isDirectory && [[filePath pathExtension] isEqualToString:@"imageset"]) {
                [self processImageSetAtPath:fullPath renameMapping:renameMapping];
            }
        }
    }
}

+ (void)processImageSetAtPath:(NSString *)imageSetPath renameMapping:(NSDictionary *)renameMapping {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *contentsPath = [imageSetPath stringByAppendingPathComponent:@"Contents.json"];
    
    // 1. 读取Contents.json
    NSError *error;
    NSData *contentsData = [NSData dataWithContentsOfFile:contentsPath];
    if (!contentsData) {
        NSLog(@"❌ Failed to read Contents.json at %@", imageSetPath);
        return;
    }
    
    NSMutableDictionary *contentsJSON = [NSJSONSerialization JSONObjectWithData:contentsData
                                                                        options:NSJSONReadingMutableContainers
                                                                          error:&error];
    if (!contentsJSON || error) {
        NSLog(@"❌ Failed to parse JSON at %@: %@", contentsPath, error.localizedDescription);
        return;
    }
    
    // 2. 处理images数组
    NSArray *images = contentsJSON[@"images"];
    if (![images isKindOfClass:[NSArray class]]) {
        return;
    }
    
    BOOL needsUpdate = NO;
    NSMutableArray *newImages = [NSMutableArray array];
    
    for (NSDictionary *imageInfo in images) {
        NSMutableDictionary *newImageInfo = [imageInfo mutableCopy];
        NSString *filename = imageInfo[@"filename"];
        
        if ([filename isKindOfClass:[NSString class]] && filename.length > 0) {
            // 提取基础名称和分辨率标识
            NSString *baseName = [self baseNameFromImageName:filename];
            NSString *scaleSuffix = [self scaleSuffixFromImageName:filename];
            NSString *extension = [filename pathExtension];
            
            // 检查是否需要重命名
            NSString *newBaseName = renameMapping[baseName];
            if (newBaseName) {
                // 构建新文件名（保留原来的分辨率标识和扩展名）
                NSString *newFilename = [self applyScaleSuffix:scaleSuffix
                                                    toBaseName:newBaseName
                                                 withExtension:extension];
                
                newImageInfo[@"filename"] = newFilename;
                needsUpdate = YES;
                
                // 3. 重命名实际图片文件
                NSString *oldImagePath = [imageSetPath stringByAppendingPathComponent:filename];
                NSString *newImagePath = [imageSetPath stringByAppendingPathComponent:newFilename];
                
                if ([fileManager fileExistsAtPath:oldImagePath]) {
                    NSError *moveError;
                    if ([fileManager moveItemAtPath:oldImagePath toPath:newImagePath error:&moveError]) {
                        NSLog(@"✅ Renamed image: %@ -> %@", filename, newFilename);
                    } else {
                        NSLog(@"❌ Failed to rename image %@: %@", filename, moveError.localizedDescription);
                    }
                }
            }
        }
        [newImages addObject:newImageInfo];
    }
    
    // 4. 更新Contents.json
    if (needsUpdate) {
        contentsJSON[@"images"] = newImages;
        
        NSData *updatedData = [NSJSONSerialization dataWithJSONObject:contentsJSON
                                                              options:NSJSONWritingPrettyPrinted
                                                                error:&error];
        if (updatedData) {
            if ([updatedData writeToFile:contentsPath atomically:YES]) {
                NSLog(@"✅ Updated Contents.json at %@", imageSetPath);
            } else {
                NSLog(@"❌ Failed to write updated Contents.json");
            }
        } else {
            NSLog(@"❌ Failed to serialize updated JSON: %@", error.localizedDescription);
        }
    }
}

#pragma mark - 代码引用更新

+ (void)updateCodeReferencesInDirectory:(NSString *)directoryPath
                          renameMapping:(NSDictionary<NSString *, NSString *> *)renameMapping {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directoryPath];
    
    // 需要处理的代码文件扩展名
    NSSet *codeFileExtensions = [NSSet setWithObjects:@"m", @"mm", @"swift", @"h", @"xib", @"storyboard", nil];
    
    NSString *filePath;
    while ((filePath = [enumerator nextObject]) != nil) {
        @autoreleasepool {
            NSString *fullPath = [directoryPath stringByAppendingPathComponent:filePath];
            BOOL isDirectory;
            [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
            
            if (isDirectory) {
                // 跳过某些目录
                if ([filePath hasSuffix:@".xcassets"] || [filePath hasSuffix:@".framework"]) {
                    [enumerator skipDescendants];
                }
                continue;
            }
            
            // 只处理代码文件
            if ([codeFileExtensions containsObject:[filePath pathExtension]]) {
                [self updateCodeReferencesInFile:fullPath renameMapping:renameMapping];
            }
        }
    }
}

+ (void)updateCodeReferencesInFile:(NSString *)filePath
                     renameMapping:(NSDictionary<NSString *, NSString *> *)renameMapping {
    
    NSError *error;
    NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:filePath
                                                                    encoding:NSUTF8StringEncoding
                                                                       error:&error];
    if (!fileContent) {
        NSLog(@"❌ Failed to read file %@: %@", filePath, error.localizedDescription);
        return;
    }
    
    BOOL fileModified = NO;
    
    // 构建正则表达式匹配 @"image_name" 格式的字符串
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"@\"([^\"]+)\""
                                                                           options:0
                                                                             error:&error];
    if (!regex) {
        NSLog(@"❌ Failed to create regex: %@", error.localizedDescription);
        return;
    }
    
    // 查找所有匹配的字符串
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:fileContent
                                                              options:0
                                                                range:NSMakeRange(0, fileContent.length)];
    
    // 反向遍历匹配结果（从后往前修改，避免影响range）
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        if (match.numberOfRanges >= 2) {
            NSRange imageNameRange = [match rangeAtIndex:1];
            NSString *imageName = [fileContent substringWithRange:imageNameRange];
            
            // 检查是否是图片引用（可能是基础名称或完整名称）
            NSString *baseName = [self baseNameFromImageName:imageName];
            NSString *newBaseName = renameMapping[baseName];
            
            if (newBaseName) {
                NSString *scaleSuffix = [self scaleSuffixFromImageName:imageName];
                NSString *newImageName = [self applyScaleSuffix:scaleSuffix toBaseName:newBaseName];
                
                // 替换文件中的字符串
                [fileContent replaceCharactersInRange:imageNameRange withString:newImageName];
                fileModified = YES;
                
                NSLog(@"✅ Updated reference in %@: %@ -> %@",
                      filePath.lastPathComponent,
                      imageName,
                      newImageName);
            }
        }
    }
    
    // 如果文件有修改，则写回
    if (fileModified) {
        if ([fileContent writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            NSLog(@"✅ Successfully updated %@", filePath.lastPathComponent);
        } else {
            NSLog(@"❌ Failed to write updated file %@: %@", filePath.lastPathComponent, error.localizedDescription);
        }
    }
}

#pragma mark - Helper Methods

// 从图片名中提取基础名称（去掉@2x/@3x等后缀）
+ (NSString *)baseNameFromImageName:(NSString *)imageName {
    NSString *nameWithoutExtension = [imageName stringByDeletingPathExtension];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"@[0-9]+x$"
                                                                           options:0
                                                                             error:nil];
    NSRange range = [regex rangeOfFirstMatchInString:nameWithoutExtension
                                             options:0
                                               range:NSMakeRange(0, nameWithoutExtension.length)];
    
    if (range.location != NSNotFound) {
        return [nameWithoutExtension substringToIndex:range.location];
    }
    
    return nameWithoutExtension;
}

// 从图片名中提取分辨率后缀（如@2x、@3x）
+ (NSString *)scaleSuffixFromImageName:(NSString *)imageName {
    NSString *nameWithoutExtension = [imageName stringByDeletingPathExtension];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"@[0-9]+x$"
                                                                           options:0
                                                                             error:nil];
    NSRange range = [regex rangeOfFirstMatchInString:nameWithoutExtension
                                             options:0
                                               range:NSMakeRange(0, nameWithoutExtension.length)];
    
    if (range.location != NSNotFound) {
        return [nameWithoutExtension substringFromIndex:range.location];
    }
    
    return @"";
}

// 应用分辨率后缀到基础名称
+ (NSString *)applyScaleSuffix:(NSString *)scaleSuffix toBaseName:(NSString *)baseName {
    return [NSString stringWithFormat:@"%@%@", baseName, scaleSuffix];
}

// 应用分辨率后缀和扩展名到基础名称
+ (NSString *)applyScaleSuffix:(NSString *)scaleSuffix
                    toBaseName:(NSString *)baseName
                 withExtension:(NSString *)extension {
    return [NSString stringWithFormat:@"%@%@.%@", baseName, scaleSuffix, extension];
}

+ (NSArray<NSString *> *)allAssetFilenamesInProject:(NSString *)projectRoot {
    // 1. 查找 Assets.xcassets 路径
    NSString *assetsPath = [self findAssetsPathInDirectory:projectRoot];
    
    if (!assetsPath) {
        NSLog(@"❌ Assets.xcassets 目录未找到！");
        return @[];
    }
    
    NSLog(@"✅ 找到 Assets.xcassets 路径: %@", assetsPath);
    
    // 2. 遍历并收集所有文件名
    return [self enumerateAllAssetsInAssetsPath:assetsPath];
}

+ (NSArray<NSString *> *)enumerateAllAssetsInAssetsPath:(NSString *)assetsPath {
    NSMutableArray<NSString *> *filenames = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:assetsPath];
    
    NSString *filePath;
    while ((filePath = [enumerator nextObject]) != nil) {
        NSString *fullPath = [assetsPath stringByAppendingPathComponent:filePath];
        BOOL isDirectory;
        [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
        
        // 只处理 .imageset 目录
        if (isDirectory && [[filePath pathExtension] isEqualToString:@"imageset"]) {
            // 获取 .imageset 中的文件名
            NSArray *filesInImageSet = [self filenamesInImageSet:fullPath];
            if (filesInImageSet.count > 0) {
                [filenames addObjectsFromArray:filesInImageSet];
            }
        }
    }
    
    return [filenames copy];
}

// 获取单个 .imageset 中的文件名（已处理后缀）
+ (NSArray<NSString *> *)filenamesInImageSet:(NSString *)imageSetPath {
    NSMutableArray<NSString *> *filenames = [NSMutableArray array];
    NSString *contentsPath = [imageSetPath stringByAppendingPathComponent:@"Contents.json"];
    
    NSError *error;
    NSData *contentsData = [NSData dataWithContentsOfFile:contentsPath];
    if (!contentsData) {
        NSLog(@"  ❌ 无法读取 Contents.json");
        return @[];
    }
    
    NSDictionary *contentsJSON = [NSJSONSerialization JSONObjectWithData:contentsData
                                                                 options:0
                                                                   error:&error];
    if (!contentsJSON || error) {
        NSLog(@"  ❌ 解析 JSON 失败: %@", error.localizedDescription);
        return @[];
    }
    
    NSArray *images = contentsJSON[@"images"];
    if (![images isKindOfClass:[NSArray class]]) {
        return @[];
    }
    
    for (NSDictionary *imageInfo in images) {
        NSString *filename = imageInfo[@"filename"];
        if ([filename isKindOfClass:[NSString class]] && filename.length > 0) {
            // 处理文件名：去掉 @2x.png, @3x.png 等后缀
            NSString *baseFilename = [self baseFilenameFromAssetFilename:filename];
            if (baseFilename) {
                [filenames addObject:baseFilename];
            }
        }
    }
    
    return [filenames copy];
}

// 从资源文件名中提取基础文件名（去掉 @2x.png 等后缀）
+ (NSString *)baseFilenameFromAssetFilename:(NSString *)filename {
    // 去掉 .png 后缀
    NSString *result = [filename stringByDeletingPathExtension];
    
    // 去掉 @2x, @3x 等比例后缀
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"@[0-9]+x$"
                                                                        options:0
                                                                          error:nil];
    NSRange range = NSMakeRange(0, result.length);
    result = [regex stringByReplacingMatchesInString:result
                                            options:0
                                              range:range
                                       withTemplate:@""];
    
    return result;
}





@end
