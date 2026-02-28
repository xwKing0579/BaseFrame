//
//  BFQRCodeViewController.m
//  BaseFrame
//
//  Created by King on 2026/2/28.
//

#import "BFQRCodeViewController.h"

@interface BFQRCodeViewController ()

@end

@implementation BFQRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIImage *qrcodeImage = [UIImage generateQRCodeWithData:@"111111111" size:1024 logoImage:[UIImage imageNamed:@"logo"] ratio:1];
    UIImageWriteToSavedPhotosAlbum(qrcodeImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo: (void *) contextInfo{}

@end
