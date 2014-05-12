//
//  DKWeatherManager.h
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 23/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

@import Foundation;

#import "DKNetworkManager.h"

typedef void (^WeatherSuccessBlock)(DKWeatherCondition *currentWeather, NSArray *hourlyForecast,
                                    NSArray *dailyForecast, BOOL finished);

@interface DKWeatherManager : NSObject

+ (instancetype)sharedInstance;

- (void)currentForecastForLatitude: (double)latitude
                      andLongitude: (double)longitude
                       forceReload: (BOOL)forceReload
                  withSuccessBlock: (WeatherSuccessBlock)successBlock
                     andErrorBlock: (ErrorBlock)errorBlock;

@end
