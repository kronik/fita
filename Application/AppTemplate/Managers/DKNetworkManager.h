//
//  DKNetworkManager.h
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 22/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "MKNetworkEngine.h"
#import "DKWeatherCondition.h"

typedef void (^ErrorBlock)(NSError *error);
typedef void (^EmptyResponseBlock)();
typedef void (^ImageCompletionBlock)(UIImage *image);
typedef void (^OauthTokenBlock)(NSString *oauthToken);
typedef void (^DownloadSuccessBlock)(NSData *fileData);
typedef void (^SuccessBlock)(NSDictionary *responseData);
typedef void (^ListSuccessBlock)(NSArray *items);
typedef void (^WeatherDataSuccessBlock)(NSDictionary *currentForecastData,
                                        NSArray *hourlyForecastData,
                                        NSArray *dayilyForecastData);

@interface DKNetworkManager : MKNetworkEngine

+ (instancetype)sharedInstance;

@property (nonatomic, strong, readonly) NSString *deviceId;

- (void)performPendingRequests;
- (void)cancelAllOperations;

- (void)downloadFile:(NSString *)url
        onCompletion:(DownloadSuccessBlock)completionBlock
onDownloadProgressChanged:(MKNKProgressBlock)downloadProgressBlock
             onError:(ErrorBlock)errorBlock;

- (void)getDataForUrl:(NSString *)url
         onCompletion:(SuccessBlock)completionBlock
              onError:(ErrorBlock)errorBlock;

- (void)forecastWithKey: (NSString *)apiKey
               latitude: (double)latitude
              longitude: (double)longitude
       withSuccessBlock: (WeatherDataSuccessBlock)successBlock
          andErrorBlock: (ErrorBlock)errorBlock;

- (void)placesStartingWith: (NSString *)placePrefix
          withSuccessBlock: (ListSuccessBlock)successBlock
             andErrorBlock: (ErrorBlock)errorBlock;

@end
