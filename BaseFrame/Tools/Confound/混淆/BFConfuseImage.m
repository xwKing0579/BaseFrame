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

@end
