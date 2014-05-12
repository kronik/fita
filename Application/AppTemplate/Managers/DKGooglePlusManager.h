//
//  DKGooglePlusManager.h
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 22/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

@import Foundation;

#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GooglePlus/GooglePlus.h>

typedef void (^GPlusLoginBlock)(NSString *userName, NSString *email);
typedef void (^GPlusErrorBlock)(NSError *error);

@interface DKGooglePlusManager : NSObject

+ (instancetype)sharedInstance;

- (void) connect: (GPlusLoginBlock)completionBlock
           error: (GPlusErrorBlock)errorBlock;

- (void) disconnect;

@end
