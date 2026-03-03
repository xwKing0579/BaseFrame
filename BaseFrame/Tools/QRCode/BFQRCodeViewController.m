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
    
    UIImage *qrcodeImage = [UIImage generateQRCodeWithData:@"https://mp.weixin.qq.com/s?__biz=MzIwMTAwMTUyNA==&tempkey=MTM2M19iT2lGSzFQbGl0RzEzamx5Sk80LTFkejJlNm1hMThEelhISEVNczFkS0RrcXVIbHVzbjZ2bHlCRWhwT1RiNTN5dWhhUml1a3hlNlNpMnpGOE5Vai1nZUo0UzFuRDN6UGJyb0JGSjNiZTlrdjJ6RVFMbWxtZnFUak1VenFzWUFkMS1FZGE0VEFJV2hSMDJtSTQ0MFlPVEJvelQ5ck4wbWVET2kzVWZ3fn4%3D&chksm=0ef3c37839844a6e0dab4b7860c8ffc4b5949dbb14b8be4263e94406a799d063248bfd09aaa4&xtrack=1&scene=90&subscene=93&sessionid=1772247366&flutter_pos=0&clicktime=1772247367&enterid=1772247367&finder_biz_enter_id=4&ranksessionid=1772246964&jumppath=50094_1772247359827%2C1122_1772247362084%2C50094_1772247363369%2C50094_1772247366403&jumppathdepth=4&ascene=56&fasttmpl_type=4&fasttmpl_fullversion=8148062-zh_CN-zip&fasttmpl_flag=0&realreporttime=1772247367474#wechat_redirect" size:1024 logoImage:[UIImage imageNamed:@"logo"] ratio:1];
    UIImageWriteToSavedPhotosAlbum(qrcodeImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo: (void *) contextInfo{}

@end
