//
//  UIDevice+UniversalMethod.h
//  PintarTunai
//
//  Created by Invincible handsome brother on 2024/10/31.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDevice (UniversalMethod)

+ (NSString *)iphoneModel;


+ (NSString *)isConnectAgent;
+ (NSString *)isConnectVPN;

+ (NSString *)diskLen;
+ (NSString *)diskRestLen;

+ (NSString *)ramLen;
+ (NSString *)ramRestLen;

+ (NSString *)isSimuLator;
+ (NSString *)isJailbreakMachine;
@end

NS_ASSUME_NONNULL_END
