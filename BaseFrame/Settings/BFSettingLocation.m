//
//  BFSettingLocation.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/6.
//

#import "BFSettingLocation.h"
#import <CoreLocation/CoreLocation.h>

@interface BFSettingLocation ()<CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, assign) BFSettingState state;
@property (nonatomic, copy) void (^completion)(BFSettingState state,NSDictionary *info);
@end

@implementation BFSettingLocation

+ (instancetype)sharedManager {
    static BFSettingLocation *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    
    return sharedManager;
}

- (instancetype)init{
    if (self = [super init]) {
        
    }
    return self;
}

+ (BOOL)isAuthorized{
    CLAuthorizationStatus status;
    if (@available(iOS 14.0, *)) {
        status = [[self sharedManager].locationManager authorizationStatus];
    } else {
        status = [CLLocationManager authorizationStatus];
    }
    return (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse);
}

+ (void)requestAuthorization:(void(^)(BFSettingState state,NSDictionary *info))completion{
    CLAuthorizationStatus status;
    if (@available(iOS 14.0, *)) {
        status = [[self sharedManager].locationManager authorizationStatus];
    } else {
        status = [CLLocationManager authorizationStatus];
    }
    
    BFSettingLocation *shareManager = [BFSettingLocation sharedManager];
    CLLocationManager *locationManager = shareManager.locationManager;
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            shareManager.completion = completion;
            shareManager.state = BFSettingStateNotDetermined;
            [locationManager requestAlwaysAuthorization];
            [locationManager startUpdatingLocation];
            break;
        case kCLAuthorizationStatusRestricted:
            completion(BFSettingStateRestricted,nil);
            break;
        case kCLAuthorizationStatusDenied:
            completion(BFSettingStateDenied,nil);
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            shareManager.completion = completion;
            shareManager.state = BFSettingStateAuthorized;
            [locationManager startUpdatingLocation];
        default:
            completion(BFSettingStateUnknown,nil);
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    if (locations.firstObject){
        [self.geocoder reverseGeocodeLocation:locations.firstObject completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            CLPlacemark *placemark = [placemarks firstObject];
            if (placemark){
                BFSettingLocation *shareManager = [BFSettingLocation sharedManager];
                if (shareManager.completion) {
                    shareManager.completion(shareManager.state, @{@"placemark":placemark});
                }
                if (!shareManager.alwayUpdating) {
                    [shareManager.locationManager stopUpdatingLocation];
                }
            }
        }];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"%@",error);
}

- (CLLocationManager *)locationManager{
    if (!_locationManager){
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (CLGeocoder *)geocoder{
    if (!_geocoder){
        _geocoder = [[CLGeocoder alloc] init];
    }
    return _geocoder;
}

@end
