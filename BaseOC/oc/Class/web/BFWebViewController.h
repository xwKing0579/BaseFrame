//
//  BFWebViewController.h
//  MoQia
//
//  Created by 王祥伟 on 2024/7/10.
//

#import "BFBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFWebViewController : BFBaseViewController
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *titleString;
@end

NS_ASSUME_NONNULL_END
