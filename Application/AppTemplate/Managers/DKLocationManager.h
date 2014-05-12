//
//  DKLocationManager.h
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 26/2/14.
//
//

@import Foundation;
@import CoreLocation;

@class DKLocationManager;

typedef void (^DKLocationManagerCompletionBlock)(CLLocation *newLocation, CLPlacemark *place);

@interface DKLocationManager : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, strong, readonly) CLLocation *currentLocation;
@property (nonatomic, readonly) BOOL isAllowedToGetLocation;

- (void)updateLocation: (DKLocationManagerCompletionBlock)completionBlock withInteractionAllowed: (BOOL)interactionAllowed;
- (void)stopUpdatingLocation;

@end
