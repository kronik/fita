//
//  DKNetworkManager.m
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 22/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKNetworkManager.h"
#import "DKSettingsManager.h"

#import "UIDevice+IdentifierAddition.h"
#import "MKNetworkOperation+Duplicate.h"
#import "NSString+URLEncoding.h"

#define LOG_SERVER_RESPONSES 1

#define HTTP_METHOD_GET @"GET"
#define HTTP_METHOD_POST @"POST"
#define HTTP_METHOD_PUT @"PUT"
#define HTTP_METHOD_DELETE @"DELETE"

#define kSimulatorDeviceID @"43ad78d3cdg21ffff4412abgdvfsc2hh12adf781"

typedef void (^ResponseDataBlock)(NSDictionary *data);

static NSString * const DKNetworkManagerBaseURLString = @"google.com";

@interface DKNetworkManager ()

- (void)clearOperationsQueue;

@property (nonatomic, strong) NSMutableArray *pendingOperations;

@end

@implementation DKNetworkManager

@synthesize pendingOperations = mPendingOperations;
@synthesize deviceId = _deviceId;

+ (instancetype)sharedInstance {
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static DKNetworkManager *_sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        
#if REMOTE_SERVER_AVAILABLE
        
//        [BaasBox setBaseURL:REMOTE_SERVER_URL appCode:REMOTE_SERVER_APP_CODE];
//        BAAClient *client = [BAAClient sharedClient];
//        
//        NSString *token = [DKSettingsManager sharedInstance][kSettingGoogleToken];
//        
//        if (client.isAuthenticated == NO) {
//            [client authenticateSocialUserWithToken:token secret:@"AIzaSyB4XPPWf0OmSgR-6MyjzNLKxf2Rf7PfGMQ" type:kSocialAuthTypeGooglePlus completion:^(BOOL success, NSError *error) {
//                NSLog(success ? @"YES":@"NO");
//            }];
//        }
#endif
        _sharedObject = [[self alloc] initWithHostName:DKNetworkManagerBaseURLString];

        __weak DKNetworkManager *this = _sharedObject;

        _sharedObject.pendingOperations = [[NSMutableArray alloc] init];
        _sharedObject.reachabilityChangedHandler = ^(NetworkStatus status) {
            [this handleConnectionStatus: status];
        };
        
        [_sharedObject useCache];
    });
    
    // returns the same object each time
    return _sharedObject;
}

- (NSString *)deviceId {
    if (_deviceId == nil) {
        _deviceId = [[UIDevice currentDevice] uniqueDeviceIdentifier];
        
        if ([[[UIDevice currentDevice] name] isEqualToString:@"iPhone Simulator"]) {
            _deviceId = kSimulatorDeviceID;
        }
    }
    return _deviceId;
}

- (void)handleConnectionStatus: (NetworkStatus)status {
    
    if (status == NotReachable) {
    }
}

- (NSDictionary *)updateParams: (NSDictionary *)parameters {
    return parameters;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) clearOperationsQueue {
    
    [DKNetworkManager cancelOperationsMatchingBlock:^BOOL(MKNetworkOperation *op) {
        return YES;
    }];
}

-(void) cancelAllOperations {
    [self clearOperationsQueue];
}

- (void)performPendingRequests {
    @synchronized (self) {
        for (MKNetworkOperation *pendingOperation in self.pendingOperations) {
            MKNetworkOperation *operation = [pendingOperation getDupOperationWithNetworkManager:self];
            if (operation) {
                [self enqueueOperation:operation];
            }
        }
        
        [self.pendingOperations removeAllObjects];
    }
}

- (MKNetworkOperation *)executeNetworkOperation:(MKNetworkOperation *) operationToExecute
                                    forceReload:(BOOL) forceReload
                                   onCompletion:(ResponseDataBlock) completionBlock
                                        onError:(ErrorBlock)errorBlock
                                onProgressBlock:(MKNKProgressBlock) progressBlock {
    if (progressBlock != nil) {
        [operationToExecute onUploadProgressChanged:progressBlock];
    }
    
	[operationToExecute addCompletionHandler:^(MKNetworkOperation *completedOperation) {
         NSDictionary *rootNode = completedOperation.responseJSON;
        
#if LOG_SERVER_RESPONSES
         NSLog(@"\nURL:%@ RESPONSE:\n%@", completedOperation.readonlyRequest.URL, rootNode);
#endif
         if (completionBlock) {
             completionBlock(rootNode);
         }
     }
                                errorHandler:^(MKNetworkOperation* completedOperation, NSError *error) {
                                    NSDictionary *rootNode = completedOperation.responseJSON;
#if LOG_SERVER_RESPONSES
                                    NSLog(@"\nURL:%@ ERROR:\n%@", completedOperation.readonlyRequest.URL, rootNode);
#endif
                                    int responseCode = [rootNode [@"code"] intValue];
                                    
                                    if (rootNode [@"code"] == nil) {
                                        responseCode = [rootNode [@"Code"] intValue];
                                    }
                                    
                                    if (rootNode && (rootNode [@"code"] || rootNode [@"Code"])) {
                                        if (errorBlock) {
                                            NSError *error = [NSError errorWithDomain:[rootNode objectForKey:@"message"]
                                                                                 code:responseCode
                                                                             userInfo:rootNode];
                                            errorBlock(error);
                                        }
                                    } else {
                                        // TODO: assert(false); // This should never during testing
                                        NSLog(@"\nUnexpected response:\n%@\n", completedOperation.responseString);
                                        
                                        if (errorBlock) {
                                            errorBlock(error);
                                        }
                                    }
                                }
     ];
    
    [self enqueueOperation:operationToExecute forceReload:forceReload];
    
    return operationToExecute;
}

- (MKNetworkOperation *)executeNetworkOperation:(NSString *)url
                                     httpMethod:(NSString *)httpMethod
                                     paramsDict:(NSDictionary *)paramsDict
                                    forceReload:(BOOL) forceReload
                                   onCompletion:(ResponseDataBlock) completionBlock
                                        onError:(ErrorBlock)errorBlock
                                onProgressBlock:(MKNKProgressBlock) progressBlock {
    
	MKNetworkOperation *operationToExecute = [self operationWithURLString:url
                                                                   params:[self updateParams:paramsDict]
                                                               httpMethod:httpMethod];
    
    if (forceReload) {
        operationToExecute.shouldNotCacheResponse = YES;
    }
    
    return [self executeNetworkOperation:operationToExecute
                             forceReload:forceReload
                            onCompletion:completionBlock
                                 onError:errorBlock
                         onProgressBlock:progressBlock];
}

- (void)forecastWithKey: (NSString *)apiKey
               latitude: (double)latitude
              longitude: (double)longitude
       withSuccessBlock: (WeatherDataSuccessBlock)successBlock
          andErrorBlock: (ErrorBlock)errorBlock {
    
    NSString *currentForecastUrl = [NSString stringWithFormat: @"https://api.forecast.io/forecast/%@/%.6f,%.6f", apiKey, latitude, longitude];
    
    [self executeNetworkOperation:currentForecastUrl httpMethod:HTTP_METHOD_GET paramsDict:@{} forceReload:YES onCompletion:^(NSDictionary *data) {
        
        successBlock(data[@"currently"], data[@"hourly"][@"data"], data[@"daily"][@"data"]);
        
    } onError:^(NSError *error) {
        errorBlock(error);
    } onProgressBlock:^(double progress) {
        
    }];
}

- (void)placesStartingWith: (NSString *)placePrefix
          withSuccessBlock: (ListSuccessBlock)successBlock
             andErrorBlock: (ErrorBlock)errorBlock {
    
    int zipCode = [placePrefix intValue];
    NSString *searchParameter = nil;
    
    if (zipCode > 0) {
        searchParameter = @"postalcode_startsWith";
    } else {
        searchParameter = @"placename_startsWith";
    }
    
    NSString *apiUrl = [NSString stringWithFormat: @"https://maps.googleapis.com/maps/api/place/autocomplete/json"];
    NSString *language = [[NSBundle mainBundle] preferredLocalizations].firstObject;
    
    if (language.length == 0) {
        language = @"en";
    }

    NSDictionary *params = @{@"input": placePrefix,
                             @"sensor": @"false",
                             @"key": @"AIzaSyB4XPPWf0OmSgR-6MyjzNLKxf2Rf7PfGMQ",
                             @"language": language,
                             @"types": @"(regions)"};
    
    [self executeNetworkOperation:apiUrl httpMethod:HTTP_METHOD_GET paramsDict:params forceReload:NO onCompletion:^(NSDictionary *data) {
        
        NSArray *itemsData = data[@"predictions"];
        NSMutableArray *items = [NSMutableArray new];
        
        for (NSDictionary *itemData in itemsData) {
            
            NSString *location = @"";//itemData[@"description"];
            NSString *title = @"";
            
            NSArray *placeData = itemData[@"terms"];
            
            for (NSDictionary *termData in placeData) {
                
                if (termData[@"value"] == nil) {
                    continue;
                }
                
                if (location.length == 0) {
                    title = termData[@"value"];
                    location = termData[@"value"];
                } else {
                    location = [location stringByAppendingString:[NSString stringWithFormat:@" %@", termData[@"value"]]];
                }
            }
            
            NSDictionary *item = @{kLocationFieldTitle: title,
                                   kLocationFieldLocation: location,
                                   kLocationFieldLatitude: @(0),
                                   kLocationFieldLongitude: @(0)};
            
            BOOL isLocationExists = NO;
            
            for (NSDictionary *existingLocation in items) {
                if ([existingLocation[kLocationFieldTitle] isEqualToString:item[kLocationFieldTitle]]) {
                    isLocationExists = YES;
                    break;
                }
            }
            
            if (isLocationExists == NO) {
                [items addObject:item];
            }
        }
        successBlock(items);
        
    } onError:^(NSError *error) {
        errorBlock(error);
    } onProgressBlock:^(double progress) {
        
    }];
}


//- (void)placesStartingWith: (NSString *)placePrefix
//           withSuccessBlock: (ListSuccessBlock)successBlock
//              andErrorBlock: (ErrorBlock)errorBlock {
//    
//    int zipCode = [placePrefix intValue];
//    NSString *searchParameter = nil;
//    
//    if (zipCode > 0) {
//        searchParameter = @"postalcode_startsWith";
//    } else {
//        searchParameter = @"placename_startsWith";
//    }
//    
//    NSString *apiUrl = [NSString stringWithFormat: @"http://api.geonames.org/postalCodeSearchJSON?username=%@&isReduced=false&maxRows=100&%@=%@", @"dklimkin", searchParameter, [placePrefix encodedURLParameterString]];
//    
//    [self executeNetworkOperation:apiUrl httpMethod:HTTP_METHOD_GET paramsDict:@{} forceReload:NO onCompletion:^(NSDictionary *data) {
//        
//        NSArray *itemsData = data[@"postalCodes"];
//        NSMutableArray *items = [NSMutableArray new];
//        
//        for (NSDictionary *itemData in itemsData) {
//            
//            NSString *adminCode1 = itemData[@"countryCode"];
//            
//            if (adminCode1.length == 0) {
//                adminCode1 = itemData[@"countryCode"];
//            }
//            
//            NSDictionary *item = @{kLocationFieldTitle: [NSString stringWithFormat:@"%@ %@", itemData[@"placeName"], adminCode1],
//                                   kLocationFieldLatitude: @([itemData[@"lat"] floatValue]),
//                                   kLocationFieldLongitude: @([itemData[@"lng"] floatValue])};
//            
//            BOOL isLocationExists = NO;
//            
//            for (NSDictionary *existingLocation in items) {
//                if ([existingLocation[kLocationFieldTitle] isEqualToString:item[kLocationFieldTitle]]) {
//                    isLocationExists = YES;
//                    break;
//                }
//            }
//            
//            if (isLocationExists == NO) {
//                [items addObject:item];
//            }
//        }
//        successBlock(items);
//        
//    } onError:^(NSError *error) {
//        errorBlock(error);
//    } onProgressBlock:^(double progress) {
//        
//    }];
//}

- (void)getDataForUrl:(NSString *)url
         onCompletion:(SuccessBlock)completionBlock
              onError:(ErrorBlock)errorBlock {

    [self executeNetworkOperation:url httpMethod:HTTP_METHOD_GET paramsDict:@{} forceReload:YES onCompletion:^(NSDictionary *data) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(data);
        });
        
    } onError:^(NSError *error) {
        errorBlock(error);
    } onProgressBlock:^(double progress) {
    }];
}

- (void)downloadFile:(NSString *)url
        onCompletion:(DownloadSuccessBlock)completionBlock
onDownloadProgressChanged:(MKNKProgressBlock)downloadProgressBlock
             onError:(ErrorBlock)errorBlock {
    
    NSDictionary *parameters = @{};
    
    MKNetworkOperation *operation = [self operationWithURLString:[url encodedURLString]
                                                          params:[self updateParams:parameters]
                                                      httpMethod:HTTP_METHOD_GET];
    
    operation.shouldCacheResponseEvenIfProtocolIsHTTPS = NO;
    operation.shouldNotCacheResponse = YES;
    
    [operation onUploadProgressChanged:downloadProgressBlock];
    
    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        completionBlock (completedOperation.responseData);
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        errorBlock (error);
    }];
    
    if (operation != nil) {
        [self enqueueOperation:operation forceReload: YES];
    } else {
        NSLog(@"Broken url: %@", url);
    }
}

@end
