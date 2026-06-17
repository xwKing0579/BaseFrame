//
//  BFFileModel.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//枚举常见文件类型
typedef NS_ENUM(NSUInteger, BFFileType) {
    BFFileTypeDefault = 0,
    BFFileTypeDirectory,
    BFFileTypeDB,
    BFFileTypeJson,
    BFFileTypePlist,
    BFFileTypeImage,
    BFFileTypeAudio,
    BFFileTypeVideo,
    BFFileTypePDF,
    BFFileTypeDOC,
    BFFileTypePPT,
    BFFileTypeZip,
    BFFileTypeHTML,
};

@interface BFFileModel : NSObject
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *fileExtension;
@property (nonatomic, assign) BOOL isDirectory;
@property (nonatomic, assign) BFFileType fileType;
@property (nonatomic, assign) long long fileSize;
@property (nonatomic, copy) NSString *fileDate;
@end

NS_ASSUME_NONNULL_END
