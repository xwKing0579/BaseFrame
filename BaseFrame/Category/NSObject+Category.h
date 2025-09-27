//
//  NSObject+Category.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (Category)

+ (void)swizzleClassMethod:(SEL)originSelector withSwizzleMethod:(SEL)swizzleSelector;
- (void)swizzleInstanceMethod:(SEL)originSelector withSwizzleMethod:(SEL)swizzleSelector;

- (NSArray <NSDictionary *>*)propertyList;
- (NSArray <NSDictionary *>*)customPropertyList:(NSArray <NSString *>*)properties;

- (NSDictionary *)parseModuleMappingJSON:(NSString *)resource;
- (NSSet *)parseModuleArrayJSON:(NSString *)resource;
@end

NS_ASSUME_NONNULL_END
