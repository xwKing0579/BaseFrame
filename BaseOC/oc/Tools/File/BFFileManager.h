//
//  BFFileManager.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/15.
//

#import <Foundation/Foundation.h>
#import "BFFileModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface BFFileManager : NSObject

+ (NSArray <BFFileModel *>*)defaultFile;
+ (NSArray <BFFileModel *>*)dataForFilePath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
