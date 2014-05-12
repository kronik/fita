//
//  DKLocationManager.m
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 26/2/14.
//
//

#import "DKLocationManager.h"

#define LOCATION_ALERT_SHOW_STATUS @"LOCATION_ALERT_SHOW_STATUS"

@interface DKLocationManager () <CLLocationManagerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) DKLocationManagerCompletionBlock completionBlock;

@end

@implementation DKLocationManager

@synthesize locationManager = _locationManager;
@synthesize completionBlock = _completionBlock;
@synthesize currentLocation = _currentLocation;
@synthesize isAllowedToGetLocation = _isAllowedToGetLocation;

+ (instancetype)sharedInstance {
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static DKLocationManager *_sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[DKLocationManager alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}

- (id)init {
    self = [super init];
    
	if (self != nil) {

        _locationManager = [[CLLocationManager alloc] init];
    }
    
    return self;
}

- (BOOL)isAllowedToGetLocation {
    _isAllowedToGetLocation = ((CLLocationManager.authorizationStatus == kCLAuthorizationStatusAuthorized) ||
                               (CLLocationManager.authorizationStatus == kCLAuthorizationStatusNotDetermined));

    return _isAllowedToGetLocation;
}

- (void)dealloc {
    [self stopUpdatingLocation];
}

- (void)stopUpdatingLocation {
//    _completionBlock = nil;
    self.locationManager.delegate = nil;
    [self.locationManager stopUpdatingLocation];   
}

- (void)updateLocation: (DKLocationManagerCompletionBlock)completionBlock withInteractionAllowed: (BOOL)interactionAllowed {
    
    if (_completionBlock != completionBlock) {
        self.completionBlock = completionBlock;
    }
    
    if ((self.currentLocation != nil) && (self.completionBlock != nil)) {
        
        __weak typeof(self) this = self;
        
        CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
        
        [geoCoder reverseGeocodeLocation:self.currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                this.completionBlock(this.currentLocation, placemarks.firstObject);
            });
        }];
    }
    
    if (self.isAllowedToGetLocation == YES) {
        _locationManager.delegate = self;
//        _locationManager.distanceFilter = kCLDistanceFilterNone;
        _locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;

        [self.locationManager startUpdatingLocation];
    } else {
        
        if ((interactionAllowed == YES) && ([self isAlertShown] == NO)) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Location permission required", nil) message:NSLocalizedString(@"Please enable location in Settings", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
                [alertView show];
                
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:LOCATION_ALERT_SHOW_STATUS];
                [[NSUserDefaults standardUserDefaults] synchronize];
            });
        }
    }
}

- (BOOL)isAlertShown {
    
    return [[NSUserDefaults standardUserDefaults] boolForKey:LOCATION_ALERT_SHOW_STATUS];
}

- (void)openSettings {
    // Doesn't work on iOS > 5.0
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"prefs://root=LOCATION_SERVICES"]];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != 0) {
        [self performSelector:@selector(openSettings) withObject:nil afterDelay:1];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {

    if (self.completionBlock != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionBlock (nil, nil);
        });
    }

    [self stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if (CLLocationManager.authorizationStatus == kCLAuthorizationStatusAuthorized) {
        [self updateLocation:self.completionBlock withInteractionAllowed:NO];
    } else {
        _currentLocation = nil;

        if ((self.completionBlock != nil) &&
            ((status == kCLAuthorizationStatusDenied) || (status == kCLAuthorizationStatusRestricted))) {
                
            dispatch_async(dispatch_get_main_queue(), ^{
                self.completionBlock (nil, nil);
            });
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    
    _currentLocation = newLocation;
    
    [self stopUpdatingLocation];

    if (self.completionBlock != nil) {
        
        __weak typeof(self) this = self;

        CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
        
        [geoCoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                this.completionBlock(newLocation, placemarks.firstObject);
            });
        }];
    }
}

@end
