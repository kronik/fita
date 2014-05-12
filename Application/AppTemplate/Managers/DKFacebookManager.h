//
//  DKFacebookManager.h
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 21/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

@import Foundation;

#import <FacebookSDK/FacebookSDK.h>

typedef void (^FacebookLoginBlock)(NSString *userName, NSString *email);
typedef void (^FacebookErrorBlock)(NSError *error);
typedef void (^FacebookOperationCompletionBlock)();

@interface DKFacebookManager : NSObject

+ (instancetype)sharedInstance;

- (void) connect: (FacebookLoginBlock)completionBlock
           error: (FacebookErrorBlock)errorBlock;

- (void) resumeSession;

@end
