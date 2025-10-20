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

+ (NSDictionary *)mapImageDict103{
    return [self parseModuleMappingJSON:@"imageName_yueyi 3"];
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





// 替换两个目录中的同名图片
+ (void)replaceImagesFromDirectoryA:(NSString *)dirAPath
                      toDirectoryB:(NSString *)dirBPath {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 检查目录是否存在
    if (![fileManager fileExistsAtPath:dirAPath]) {
        NSLog(@"❌ 目录A不存在: %@", dirAPath);
        return;
    }
    
    if (![fileManager fileExistsAtPath:dirBPath]) {
        NSLog(@"❌ 目录B不存在: %@", dirBPath);
        return;
    }
    
    NSLog(@"📁 目录A: %@", dirAPath);
    NSLog(@"📁 目录B: %@", dirBPath);
    
    // 获取目录A中的所有图片文件
    NSError *error = nil;
    NSArray *dirAContents = [fileManager contentsOfDirectoryAtPath:dirAPath error:&error];
    if (error) {
        NSLog(@"❌ 读取目录A失败: %@", error.localizedDescription);
        return;
    }
    
    // 过滤出图片文件并打印所有图片
    NSArray *imageExtensions = @[@"png", @"jpg", @"jpeg", @"gif", @"bmp", @"tiff", @"webp"];
    NSMutableArray *imageFiles = [NSMutableArray array];
    
    NSLog(@"\n📋 目录A中的图片文件:");
    for (NSString *file in dirAContents) {
        NSString *extension = [[file pathExtension] lowercaseString];
        if ([imageExtensions containsObject:extension]) {
            [imageFiles addObject:file];
            NSLog(@"   - %@", file);
        }
    }
    
    NSLog(@"📁 目录A中找到 %lu 个图片文件", (unsigned long)imageFiles.count);
    
    // 在目录B中查找所有的Assets.xcassets（排除Pods目录）
    NSArray *assetsCatalogs = [self findAllAssetsCatalogsInDirectory:dirBPath];
    
    if (assetsCatalogs.count == 0) {
        NSLog(@"❌ 在目录B中未找到Assets.xcassets");
        return;
    }
    
    NSLog(@"\n📋 找到的Assets.xcassets目录:");
    for (NSString *assetsPath in assetsCatalogs) {
        NSLog(@"   - %@", [self relativePath:assetsPath fromBase:dirBPath]);
    }
    
    NSInteger totalReplaced = 0;
    
    // 遍历所有找到的Assets.xcassets目录
    for (NSString *assetsCatalogPath in assetsCatalogs) {
        NSLog(@"\n🔍 处理Assets.xcassets: %@", [self relativePath:assetsCatalogPath fromBase:dirBPath]);
        
        NSInteger replacedInThisCatalog = [self processAssetsCatalog:assetsCatalogPath
                                                  withImagesFromDirA:dirAPath
                                                          imageFiles:imageFiles];
        totalReplaced += replacedInThisCatalog;
    }
    
    NSLog(@"\n📊 替换完成!");
    NSLog(@"✅ 总共替换了 %ld 个图片", (long)totalReplaced);
}

+ (NSString *)relativePath:(NSString *)path fromBase:(NSString *)basePath {
    if ([path hasPrefix:basePath]) {
        NSString *relativePath = [path substringFromIndex:basePath.length];
        if ([relativePath hasPrefix:@"/"]) {
            relativePath = [relativePath substringFromIndex:1];
        }
        return relativePath;
    }
    return path;
}

+ (NSArray *)findAllAssetsCatalogsInDirectory:(NSString *)directory {
    NSMutableArray *assetsCatalogs = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directory];
    NSString *file;
    
    while ((file = [enumerator nextObject])) {
        // 跳过Pods目录
        if ([file containsString:@"/Pods/"] || [file hasPrefix:@"Pods/"]) {
            [enumerator skipDescendants];
            continue;
        }
        
        // 检查是否是Assets.xcassets目录
        if ([[file lastPathComponent] isEqualToString:@"Assets.xcassets"]) {
            NSString *assetsPath = [directory stringByAppendingPathComponent:file];
            [assetsCatalogs addObject:assetsPath];
        }
    }
    
    return [assetsCatalogs copy];
}

+ (NSInteger)processAssetsCatalog:(NSString *)assetsCatalogPath
               withImagesFromDirA:(NSString *)dirAPath
                       imageFiles:(NSArray *)imageFiles {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    // 获取Assets.xcassets中的所有内容
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:assetsCatalogPath error:&error];
    if (error) {
        NSLog(@"❌ 读取Assets.xcassets失败: %@", assetsCatalogPath);
        return 0;
    }
    
    NSInteger replacedCount = 0;
    
    // 遍历Assets.xcassets中的所有项目
    for (NSString *item in contents) {
        NSString *itemPath = [assetsCatalogPath stringByAppendingPathComponent:item];
        
        BOOL isDirectory;
        if ([fileManager fileExistsAtPath:itemPath isDirectory:&isDirectory] && isDirectory) {
            if ([item hasSuffix:@".imageset"]) {
                // 处理图片集
                replacedCount += [self processImageSet:itemPath
                                    withImagesFromDirA:dirAPath
                                            imageFiles:imageFiles];
            } else {
                // 递归处理子目录
                replacedCount += [self findAndProcessImageSetsInDirectory:itemPath
                                                       withImagesFromDirA:dirAPath
                                                               imageFiles:imageFiles];
            }
        }
    }
    
    return replacedCount;
}

+ (NSInteger)findAndProcessImageSetsInDirectory:(NSString *)directory
                             withImagesFromDirA:(NSString *)dirAPath
                                     imageFiles:(NSArray *)imageFiles {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSInteger replacedCount = 0;
    
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directory];
    NSString *file;
    
    while ((file = [enumerator nextObject])) {
        if ([file hasSuffix:@".imageset"]) {
            NSString *imageSetPath = [directory stringByAppendingPathComponent:file];
            replacedCount += [self processImageSet:imageSetPath
                                withImagesFromDirA:dirAPath
                                        imageFiles:imageFiles];
        }
    }
    
    return replacedCount;
}

+ (NSInteger)processImageSet:(NSString *)imageSetPath
          withImagesFromDirA:(NSString *)dirAPath
                  imageFiles:(NSArray *)imageFiles {
    
    // 提取图片集名称（去掉.imageset后缀）
    NSString *imageSetName = [[imageSetPath lastPathComponent] stringByDeletingPathExtension];
    
    NSLog(@"\n   🔍 检查图片集: %@", imageSetName);
    
    // 读取Contents.json来获取实际的文件名
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *contentsPath = [imageSetPath stringByAppendingPathComponent:@"Contents.json"];
    
    if (![fileManager fileExistsAtPath:contentsPath]) {
        NSLog(@"   ❌ Contents.json不存在");
        return 0;
    }
    
    NSData *contentsData = [NSData dataWithContentsOfFile:contentsPath];
    if (!contentsData) {
        NSLog(@"   ❌ 无法读取Contents.json");
        return 0;
    }
    
    NSError *jsonError = nil;
    NSDictionary *contentsDict = [NSJSONSerialization JSONObjectWithData:contentsData
                                                                 options:0
                                                                   error:&jsonError];
    if (jsonError || !contentsDict) {
        NSLog(@"   ❌ 解析Contents.json失败");
        return 0;
    }
    
    // 获取图片信息数组
    NSArray *images = contentsDict[@"images"];
    if (!images) {
        NSLog(@"   ❌ 无法获取images数组");
        return 0;
    }
    
    NSInteger replacedCount = 0;
    
    // 遍历Contents.json中定义的每个图片文件
    for (NSDictionary *imageInfo in images) {
        NSString *targetFilename = imageInfo[@"filename"];
        if (!targetFilename) {
            continue;
        }
        
        NSLog(@"   📄 需要文件: %@", targetFilename);
        
        // 在目录A中查找精确匹配的文件（包括缩放后缀）
        NSString *matchingImageFile = nil;
        for (NSString *imageFile in imageFiles) {
            // 精确匹配文件名（包括@2x/@3x后缀）
            if ([imageFile isEqualToString:targetFilename]) {
                matchingImageFile = imageFile;
                NSLog(@"     ✅ 找到精确匹配: %@", imageFile);
                break;
            }
        }
        
        if (matchingImageFile) {
            // 进行替换
            NSString *sourceImagePath = [dirAPath stringByAppendingPathComponent:matchingImageFile];
            if ([self replaceSpecificImageInImageSet:imageSetPath
                                    withSourceImage:sourceImagePath
                                           filename:targetFilename]) {
                NSLog(@"   ✅ 成功替换: %@", targetFilename);
                replacedCount++;
            } else {
                NSLog(@"   ⚠️ 替换失败: %@", targetFilename);
            }
        } else {
            NSLog(@"     ❌ 未找到匹配文件: %@", targetFilename);
        }
    }
    
    if (replacedCount == 0) {
        NSLog(@"   ❌ 在此图片集中未找到任何匹配的图片");
    }
    
    return replacedCount;
}

// 替换图片集中指定的图片文件
+ (BOOL)replaceSpecificImageInImageSet:(NSString *)imageSetPath
                      withSourceImage:(NSString *)sourceImagePath
                             filename:(NSString *)targetFilename {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *targetImagePath = [imageSetPath stringByAppendingPathComponent:targetFilename];
    
    // 检查源文件是否存在
    if (![fileManager fileExistsAtPath:sourceImagePath]) {
        NSLog(@"   ❌ 源图片不存在: %@", sourceImagePath);
        return NO;
    }
    
    // 检查目标文件是否存在（不管是否有备份，都要替换）
    if (![fileManager fileExistsAtPath:targetImagePath]) {
        NSLog(@"   ❌ 目标图片不存在: %@", targetImagePath);
        return NO;
    }
    
    // 删除目标文件（强制替换）
    NSError *removeError = nil;
    if ([fileManager removeItemAtPath:targetImagePath error:&removeError]) {
        NSLog(@"   🗑️ 已删除原文件: %@", targetFilename);
    } else {
        NSLog(@"   ⚠️ 删除原文件失败: %@", removeError.localizedDescription);
        // 继续尝试复制，可能会覆盖
    }
    
    // 复制新图片
    NSError *copyError = nil;
    if ([fileManager copyItemAtPath:sourceImagePath toPath:targetImagePath error:&copyError]) {
        NSLog(@"   ✅ 成功替换文件: %@", targetFilename);
        return YES;
    } else {
        NSLog(@"   ❌ 复制图片失败: %@", copyError.localizedDescription);
        return NO;
    }
}







/// 检测未使用的图片资源并可选删除
+ (NSArray<NSString *> *)findUnusedImagesInProject:(NSString *)projectPath
                                       excludeDirs:(NSArray<NSString *> *)excludeDirs
                                      shouldDelete:(BOOL)shouldDelete {
    
    // 1. 检测未使用的图片
    NSArray<NSString *> *unusedImages = [self findAllUnusedImagesInProject:projectPath excludeDirs:excludeDirs];
    
    if (unusedImages.count == 0) {
        NSLog(@"🎉 没有找到未使用的图片资源");
        return @[];
    }
    
    // 2. 输出检测结果
    [self logUnusedImages:unusedImages];
    
    // 3. 如果要求删除，则执行删除操作
    if (shouldDelete) {
        NSArray<NSString *> *deletedImages = [self deleteImages:unusedImages];
        return deletedImages;
    }
    
    return unusedImages;
}

#pragma mark - 私有核心方法

/// 查找所有未使用的图片
+ (NSArray<NSString *> *)findAllUnusedImagesInProject:(NSString *)projectPath
                                          excludeDirs:(NSArray<NSString *> *)excludeDirs {
    
    // 1. 收集所有图片资源（包括 Assets.xcassets）
    NSArray<NSString *> *allImages = [self findAllImageResourcePathsInProject:@"/Users/wangxiangwei/Desktop/yayj_副本/yayj/yuelian" excludeDirs:excludeDirs];
    NSLog(@"找到 %lu 个图片资源", (unsigned long)allImages.count);
    
    if (allImages.count == 0) {
        return @[];
    }
    
    // 2. 收集所有代码文件（排除 Assets.xcassets）
    NSArray<NSString *> *codeFiles = [self findAllCodeFilesInProject:projectPath excludeDirs:excludeDirs];
    NSLog(@"扫描 %lu 个代码文件...", (unsigned long)codeFiles.count);
    
    // 3. 检测未使用的图片
    NSMutableArray<NSString *> *unusedImages = [NSMutableArray array];
    
    for (NSString *imagePath in allImages) {
        NSString *imageName = [self imageNameFromPath:imagePath];
        
        // 检查图片名是否在代码文件中被引用
        if (![self isImageUsed:imageName inCodeFiles:codeFiles]) {
            [unusedImages addObject:imagePath];
        }
    }
    
    return [unusedImages copy];
}

/// 检查图片是否在代码文件中被使用
+ (BOOL)isImageUsed:(NSString *)imageName inCodeFiles:(NSArray<NSString *> *)codeFiles {
    if (imageName.length == 0) {
        return NO;
    }
    
    for (NSString *codeFile in codeFiles) {
        @autoreleasepool {
            NSError *error = nil;
            NSString *content = [NSString stringWithContentsOfFile:codeFile encoding:NSUTF8StringEncoding error:&error];
            
            if (error) {
                // 如果UTF-8失败，尝试其他编码
                content = [NSString stringWithContentsOfFile:codeFile usedEncoding:nil error:&error];
            }
            
            if (content && [self isImageName:imageName usedInContent:content]) {
                return YES;
            }
        }
    }
    
    NSLog(@"❌ 图片未使用: %@", imageName);
    return NO;
}

/// 检查图片名是否在文件内容中被使用
+ (BOOL)isImageName:(NSString *)imageName usedInContent:(NSString *)content {
    // 多种图片引用模式
    NSArray<NSString *> *patterns = @[
        [NSString stringWithFormat:@"@\"%@\"", imageName],
        [NSString stringWithFormat:@"imageNamed:@\"%@\"", imageName],
        [NSString stringWithFormat:@"UIImage imageNamed:@\"%@\"", imageName],
        [NSString stringWithFormat:@"\\\"%@\\\"", imageName],  // 转义引号
        [NSString stringWithFormat:@"image=\\\"%@\\\"", imageName],  // xib/storyboard
        [NSString stringWithFormat:@"value=\\\"%@\\\"", imageName]   // plist
    ];
    
    for (NSString *pattern in patterns) {
        NSRange range = [content rangeOfString:pattern];
        if (range.location != NSNotFound) {
            return YES;
        }
    }
    
    return NO;
}

/// 删除图片数组
+ (NSArray<NSString *> *)deleteImages:(NSArray<NSString *> *)images {
    NSMutableArray<NSString *> *deletedImages = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSLog(@"🗑️ 开始删除未使用的图片资源...");
    
    // 先收集所有需要删除的 .imageset 文件夹
    NSMutableSet *imagesetFoldersToDelete = [NSMutableSet set];
    
    for (NSString *imagePath in images) {
        @autoreleasepool {
            // 检查文件是否存在
            if (![fileManager fileExistsAtPath:imagePath]) {
                NSLog(@"⚠️ 文件不存在: %@", imagePath);
                continue;
            }
            
            // 如果是 Assets.xcassets 中的图片，记录 .imageset 文件夹
            if ([imagePath containsString:@".imageset"]) {
                NSString *imagesetPath = [imagePath stringByDeletingLastPathComponent];
                if ([[imagesetPath pathExtension] isEqualToString:@"imageset"]) {
                    [imagesetFoldersToDelete addObject:imagesetPath];
                }
                continue; // 稍后统一删除 .imageset 文件夹
            }
            
            // 删除普通图片文件
            NSError *error = nil;
            BOOL success = [fileManager removeItemAtPath:imagePath error:&error];
            
            if (success) {
                [deletedImages addObject:imagePath];
                NSLog(@"✅ 删除成功: %@", imagePath);
            } else {
                NSLog(@"❌ 删除失败: %@, 错误: %@", imagePath, error.localizedDescription);
            }
        }
    }
    
    // 删除所有 .imageset 文件夹
    for (NSString *imagesetPath in imagesetFoldersToDelete) {
        [self deleteImagesetFolder:imagesetPath];
        [deletedImages addObject:imagesetPath];
    }
    
    NSLog(@"🎉 删除完成: 成功删除 %lu 个文件/文件夹", (unsigned long)deletedImages.count);
    return [deletedImages copy];
}

/// 删除整个 .imageset 文件夹
+ (void)deleteImagesetFolder:(NSString *)imagesetPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:imagesetPath]) {
        NSLog(@"⚠️ .imageset 文件夹不存在: %@", imagesetPath);
        return;
    }
    
    NSError *error = nil;
    BOOL success = [fileManager removeItemAtPath:imagesetPath error:&error];
    
    if (success) {
        NSLog(@"✅ 删除 .imageset 文件夹成功: %@", imagesetPath);
        
        // 检查父目录（通常是 .xcassets 文件夹）是否为空，如果为空也删除
        NSString *parentDir = [imagesetPath stringByDeletingLastPathComponent];
        if ([[parentDir pathExtension] isEqualToString:@"xcassets"]) {
            NSArray *contents = [fileManager contentsOfDirectoryAtPath:parentDir error:nil];
            if (contents.count == 0) {
                [fileManager removeItemAtPath:parentDir error:nil];
                NSLog(@"✅ 删除空 .xcassets 文件夹: %@", parentDir);
            }
        }
    } else {
        NSLog(@"❌ 删除 .imageset 文件夹失败: %@, 错误: %@", imagesetPath, error.localizedDescription);
    }
}

/// 查找所有图片资源路径（包括 Assets.xcassets）
+ (NSArray<NSString *> *)findAllImageResourcePathsInProject:(NSString *)projectPath
                                                excludeDirs:(NSArray<NSString *> *)excludeDirs {
    
    NSMutableArray<NSString *> *imagePaths = [NSMutableArray array];
    NSArray<NSString *> *imageExtensions = @[@"png", @"jpg", @"jpeg", @"gif", @"bmp", @"pdf"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *projectURL = [NSURL fileURLWithPath:projectPath];
    
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:projectURL
                                          includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                             options:NSDirectoryEnumerationSkipsHiddenFiles
                                                        errorHandler:^BOOL(NSURL *url, NSError *error) {
        return YES;
    }];
    
    for (NSURL *fileURL in enumerator) {
        NSError *error;
        NSNumber *isDirectory;
        if (![fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            continue;
        }
        
        NSString *filePath = [fileURL path];
        
        // 检查是否应该排除该路径（不排除 Assets.xcassets）
        if ([self shouldExcludePath:filePath projectPath:projectPath excludeDirs:excludeDirs]) {
            if ([isDirectory boolValue]) {
                [enumerator skipDescendants];
            }
            continue;
        }
        
        // 如果是 .imageset 文件夹，跳过其子文件的遍历（我们只需要记录文件夹路径）
        if ([isDirectory boolValue] && [[filePath pathExtension] isEqualToString:@"imageset"]) {
            // 收集 .imageset 文件夹中的所有图片文件
            [self addImagesFromImageset:filePath toArray:imagePaths];
            [enumerator skipDescendants];
            continue;
        }
        
        // 如果是目录，继续遍历
        if ([isDirectory boolValue]) {
            continue;
        }
        
        NSString *fileExtension = [[filePath pathExtension] lowercaseString];
        
        // 检查是否是图片文件（不包括 .imageset 中的，因为上面已经处理了）
        if ([imageExtensions containsObject:fileExtension] && ![filePath containsString:@".imageset"]) {
            [imagePaths addObject:filePath];
        }
    }
    
    return [imagePaths copy];
}

/// 从 .imageset 文件夹中添加所有图片文件
+ (void)addImagesFromImageset:(NSString *)imagesetPath toArray:(NSMutableArray<NSString *> *)imagePaths {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray<NSString *> *imageExtensions = @[@"png", @"jpg", @"jpeg", @"gif", @"bmp", @"pdf"];
    
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:imagesetPath error:&error];
    
    if (error) {
        NSLog(@"❌ 读取 .imageset 内容失败: %@", imagesetPath);
        return;
    }
    
    for (NSString *file in contents) {
        NSString *fileExtension = [[file pathExtension] lowercaseString];
        if ([imageExtensions containsObject:fileExtension]) {
            NSString *imagePath = [imagesetPath stringByAppendingPathComponent:file];
            [imagePaths addObject:imagePath];
        }
    }
}

/// 从图片路径中提取图片名（去除 @2x/@3x 和扩展名）
+ (NSString *)imageNameFromPath:(NSString *)imagePath {
    NSString *fileName = [[imagePath lastPathComponent] stringByDeletingPathExtension];
    // 去除 @2x, @3x 等后缀，只保留基础名称
    return [self baseImageName:fileName];
}

/// 查找所有代码文件（排除 Assets.xcassets）
+ (NSArray<NSString *> *)findAllCodeFilesInProject:(NSString *)projectPath
                                       excludeDirs:(NSArray<NSString *> *)excludeDirs {
    
    NSMutableArray<NSString *> *codeFiles = [NSMutableArray array];
    NSArray<NSString *> *codeExtensions = @[@"m", @"mm", @"h", @"xib", @"storyboard", @"swift", @"plist", @"json", @"cpp", @"c"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *projectURL = [NSURL fileURLWithPath:projectPath];
    
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:projectURL
                                          includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                             options:NSDirectoryEnumerationSkipsHiddenFiles
                                                        errorHandler:^BOOL(NSURL *url, NSError *error) {
        return YES;
    }];
    
    for (NSURL *fileURL in enumerator) {
        NSError *error;
        NSNumber *isDirectory;
        if (![fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            continue;
        }
        
        NSString *filePath = [fileURL path];
        
        // 检查是否应该排除该路径（包括 Assets.xcassets）
        if ([self shouldExcludePath:filePath projectPath:projectPath excludeDirs:excludeDirs] ||
            [filePath containsString:@".xcassets"]) {
            if ([isDirectory boolValue]) {
                [enumerator skipDescendants];
            }
            continue;
        }
        
        // 如果是目录，继续遍历
        if ([isDirectory boolValue]) {
            continue;
        }
        
        NSString *fileExtension = [[filePath pathExtension] lowercaseString];
        
        if ([codeExtensions containsObject:fileExtension]) {
            [codeFiles addObject:filePath];
        }
    }
    
    return [codeFiles copy];
}

#pragma mark - 工具方法

/// 获取基础图片名（去除 @2x, @3x 等后缀）
+ (NSString *)baseImageName:(NSString *)imageName {
    // 使用正则表达式去除 @2x, @3x 等后缀
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"@[0-9]+x$"
                                                                           options:0
                                                                             error:nil];
    NSString *baseName = [regex stringByReplacingMatchesInString:imageName
                                                         options:0
                                                           range:NSMakeRange(0, imageName.length)
                                                    withTemplate:@""];
    
    return baseName;
}

/// 检查是否应该排除该路径
+ (BOOL)shouldExcludePath:(NSString *)fullPath projectPath:(NSString *)projectPath excludeDirs:(NSArray<NSString *> *)excludeDirs {
    if (!excludeDirs || excludeDirs.count == 0) {
        excludeDirs = @[@"Pods", @"DerivedData", @".git", @"build", @"Carthage"];
    }
    
    // 获取相对于项目路径的相对路径
    NSString *relativePath = [fullPath substringFromIndex:projectPath.length];
    if ([relativePath hasPrefix:@"/"]) {
        relativePath = [relativePath substringFromIndex:1];
    }
    
    // 检查路径的每一级目录
    NSArray<NSString *> *pathComponents = [relativePath pathComponents];
    
    for (NSString *component in pathComponents) {
        for (NSString *excludeDir in excludeDirs) {
            if ([component isEqualToString:excludeDir]) {
                return YES;
            }
        }
    }
    
    return NO;
}

/// 输出未使用的图片列表
+ (void)logUnusedImages:(NSArray<NSString *> *)unusedImages {
    NSLog(@"\n=== 检测结果 ===");
    NSLog(@"找到 %lu 个未使用的图片资源:", (unsigned long)unusedImages.count);
    
    for (NSString *imagePath in unusedImages) {
        NSString *imageName = [self imageNameFromPath:imagePath];
        NSLog(@"📄 %@ -> 检测名称: %@", [imagePath lastPathComponent], imageName);
    }
    NSLog(@"==============\n");
}

/// 调试方法：检查特定图片的使用情况
+ (void)debugImageUsage:(NSString *)imageName inProject:(NSString *)projectPath excludeDirs:(NSArray<NSString *> *)excludeDirs {
    NSArray<NSString *> *codeFiles = [self findAllCodeFilesInProject:projectPath excludeDirs:excludeDirs];
    
    NSLog(@"🔍 调试图片: %@", imageName);
    
    for (NSString *codeFile in codeFiles) {
        @autoreleasepool {
            NSError *error = nil;
            NSString *content = [NSString stringWithContentsOfFile:codeFile encoding:NSUTF8StringEncoding error:&error];
            
            if (!error && content) {
                NSArray<NSString *> *patterns = @[
                    [NSString stringWithFormat:@"@\"%@\"", imageName],
                    [NSString stringWithFormat:@"imageNamed:@\"%@\"", imageName]
                ];
                
                for (NSString *pattern in patterns) {
                    NSRange range = [content rangeOfString:pattern];
                    if (range.location != NSNotFound) {
                        NSLog(@"✅ 在文件 %@ 中找到匹配: %@", [codeFile lastPathComponent], pattern);
                    }
                }
            }
        }
    }
}


@end
