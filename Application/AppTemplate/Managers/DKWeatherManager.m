//
//  DKWeatherManager.m
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 23/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKWeatherManager.h"
#import "DKNetworkManager.h"
#import "DKSettingsManager.h"

#import "Flurry.h"

@import MapKit;

//#define kWeatherApiKey @"41e89c4fc184e754a6aabc0579bf3774"
#define kWeatherApiKey @"2065b0c772db40e49b0e44cf5c1f0311"

#define kWeatherCacheFieldTitle           @"title"
#define kWeatherCacheFieldUpdateTime      @"updateTime"
#define kWeatherCacheFieldCurrent         @"currentWeather"
#define kWeatherCacheFieldHourlyForecast  @"hourlyForecast"
#define kWeatherCacheFieldDailyForecast   @"dailyForecast"

#define kWeatherCacheInvalidateInterval 1 * 60 * 60 // 1 hour


@interface DKWeatherManager ()

@property (nonatomic, strong) NSMutableDictionary *weatherCache;

@end

@implementation DKWeatherManager

@synthesize weatherCache = _weatherCache;

+ (instancetype)sharedInstance {
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSMutableDictionary *)weatherCache {
    if (_weatherCache == nil) {
        NSMutableDictionary *oldData = [[[NSUserDefaults standardUserDefaults] objectForKey:kLocalSettingsWeatherCacheKey] mutableCopy];

        _weatherCache = [NSMutableDictionary new];

        if (oldData != nil) {
            for (NSString *key in oldData.keyEnumerator) {
                NSDictionary *cachedData = oldData[key];
                
                NSDate *lastUpdateTime = cachedData [kWeatherCacheFieldUpdateTime];
                DKWeatherCondition *currentWeatherData = [NSKeyedUnarchiver unarchiveObjectWithData:cachedData[kWeatherCacheFieldCurrent]];
                NSArray *forecastData = cachedData[kWeatherCacheFieldHourlyForecast];
                NSArray *dailyForecastData = cachedData[kWeatherCacheFieldDailyForecast];
                NSMutableArray *newForecastData = [NSMutableArray new];
                NSMutableArray *newDailyForecastData = [NSMutableArray new];

                for (NSData *data in forecastData) {
                    DKWeatherCondition *forecastItemData = [NSKeyedUnarchiver unarchiveObjectWithData:data];

                    if (forecastItemData) {
                        [newForecastData addObject:forecastItemData];
                    }
                }

                for (NSData *data in dailyForecastData) {
                    DKWeatherCondition *forecastItemData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                    
                    if (forecastItemData) {
                        [newDailyForecastData addObject:forecastItemData];
                    }
                }

                cachedData = @{kWeatherCacheFieldUpdateTime: lastUpdateTime,
                               kWeatherCacheFieldCurrent: currentWeatherData,
                               kWeatherCacheFieldHourlyForecast: newForecastData,
                               kWeatherCacheFieldDailyForecast: newDailyForecastData};
                
                _weatherCache[key] = cachedData;
            }
        }
    }
    
    return _weatherCache;
}

- (void)flushCache {
    
    NSMutableDictionary *dataToCache = [NSMutableDictionary new];
    
    for (NSString *key in self.weatherCache.keyEnumerator) {
        NSDictionary *cachedData = self.weatherCache[key];
        
        NSDate *lastUpdateTime = cachedData [kWeatherCacheFieldUpdateTime];
        DKWeatherCondition *currentWeatherData = cachedData[kWeatherCacheFieldCurrent];
        NSArray *forecastData = cachedData[kWeatherCacheFieldHourlyForecast];
        NSArray *dailyForecastData = cachedData[kWeatherCacheFieldDailyForecast];

        NSMutableArray *newForecastData = [NSMutableArray new];
        NSMutableArray *newDailyForecastData = [NSMutableArray new];
        
        for (DKWeatherCondition *data in forecastData) {
            
            NSData *forecastItemData = [NSKeyedArchiver archivedDataWithRootObject:data];
            
            if (forecastItemData) {
                [newForecastData addObject:forecastItemData];
            }
        }

        for (DKWeatherCondition *data in dailyForecastData) {
            
            NSData *forecastItemData = [NSKeyedArchiver archivedDataWithRootObject:data];
            
            if (forecastItemData) {
                [newDailyForecastData addObject:forecastItemData];
            }
        }

        cachedData = @{kWeatherCacheFieldUpdateTime: lastUpdateTime,
                       kWeatherCacheFieldCurrent: [NSKeyedArchiver archivedDataWithRootObject:currentWeatherData],
                       kWeatherCacheFieldHourlyForecast: newForecastData,
                       kWeatherCacheFieldDailyForecast: newDailyForecastData};
        
        dataToCache[key] = cachedData;
    }

    [[NSUserDefaults standardUserDefaults] setObject:dataToCache forKey:kLocalSettingsWeatherCacheKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id)init {
    self = [super init];
    
	if (self != nil) {
        
    }
    
    return self;
}

//http://api.geonames.org/postalCodeSearch?placename_startsWith='San'&isReduced=false&username=dklimkin

- (void)currentForecastForLatitude: (double)latitude
                      andLongitude: (double)longitude
                       forceReload: (BOOL)forceReload
                  withSuccessBlock: (WeatherSuccessBlock)successBlock
                     andErrorBlock: (ErrorBlock)errorBlock {


//    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
//    
//    NSDictionary *params = @{@"City": @"San"};
//    
//    [geocoder geocodeAddressDictionary:params completionHandler:^(NSArray *placemarks, NSError *error) {
//        if([placemarks count]) {
//            for (CLPlacemark *placemark in placemarks) {
//                NSLog(@"Found: %@", placemark);
//            }
//        }
//    }];
//
//    
//    
//    return;
//    
//    
//    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
//    request.naturalLanguageQuery = @"Mosc";
////    request.region = self.map.region;
//    
//    // Create and initialize a search object.
//    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
//    
//    // Start the search and display the results as annotations on the map.
//    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
//        NSMutableArray *placemarks = [NSMutableArray array];
//        for (MKMapItem *item in response.mapItems) {
//            [placemarks addObject:item.placemark];
//            
//            NSLog(@"Found: %@", item.placemark);
//        }
//        
//    }];
//    
//    return;
    
    __weak typeof(self) this = self;

    NSString *cacheKey = [NSString stringWithFormat:@"[%.2f, %.2f]", latitude, longitude];
    NSDictionary *cachedData = self.weatherCache[cacheKey];
    
    if (cachedData && !forceReload) {
        
        NSDate *currentTime = [NSDate date];
        NSDate *lastUpdateTime = cachedData [kWeatherCacheFieldUpdateTime];

        DKWeatherCondition *currentWeatherData = cachedData[kWeatherCacheFieldCurrent];
        NSArray *forecastData = cachedData[kWeatherCacheFieldHourlyForecast];
        NSArray *dailyForecastData = cachedData[kWeatherCacheFieldHourlyForecast];
        
        if ([currentTime timeIntervalSinceDate:lastUpdateTime] < kWeatherCacheInvalidateInterval) {
            
            successBlock (currentWeatherData, forecastData, dailyForecastData, YES);

            [Flurry logEvent:@"Weather cache hit"];

            return;
        } else {
            
            successBlock (currentWeatherData, forecastData, dailyForecastData, NO);

            [Flurry logEvent:@"Weather cache miss"];
        }
    } else {
        [Flurry logEvent:@"Weather cache miss"];
    }
    
    [[DKNetworkManager sharedInstance] forecastWithKey:kWeatherApiKey
                                              latitude:latitude
                                             longitude:longitude
                                      withSuccessBlock:^(NSDictionary *currentForecastData, NSArray *hourlyForecastData, NSArray *dailyForecastData) {
                                          
                                          
        DKWeatherCondition *currentWeather = [DKWeatherCondition weatherConditionFromData:currentForecastData];
        NSMutableArray *hourlyForecast = [NSMutableArray new];
        NSMutableArray *dailyForecast = [NSMutableArray new];
                                          
        for (NSDictionary *hourlyData in hourlyForecastData) {
            DKWeatherCondition *hourWeather = [DKWeatherCondition weatherConditionFromData:hourlyData];

            if (hourWeather) {
              [hourlyForecast addObject:hourWeather];
            }
        }

        for (NSDictionary *dailyData in dailyForecastData) {
            DKWeatherCondition *dailyWeather = [DKWeatherCondition weatherConditionFromData:dailyData];

            if (dailyWeather) {
              [dailyForecast addObject:dailyWeather];
            }
        }

        NSDictionary *cachedData = @{kWeatherCacheFieldUpdateTime: [NSDate date],
                                     kWeatherCacheFieldCurrent: currentWeather,
                                     kWeatherCacheFieldHourlyForecast: hourlyForecast,
                                     kWeatherCacheFieldDailyForecast: dailyForecast};

        this.weatherCache[cacheKey] = cachedData;
        [this flushCache];
                            
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock (currentWeather, hourlyForecast, dailyForecast, YES);
        });
                                          
    } andErrorBlock:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock(error);
        });
    }];
}

@end
