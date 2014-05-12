//
//  DKTwitterManager.h
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 22/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

@import Foundation;

@import Accounts;
@import Twitter;

typedef void (^TwitterLoginBlock)(NSString *userName, NSString *email);
typedef void (^TwitterErrorBlock)(NSError *error);
typedef void (^TwitterProfilePicFetchBlock)(NSString *profileImageUrl);

@interface DKTwitterManager : NSObject

+ (instancetype)sharedInstance;

- (void) connect: (TwitterLoginBlock)completionBlock
           error: (TwitterErrorBlock)errorBlock;

- (void) fetchProfilePicOnCompletion:(TwitterProfilePicFetchBlock)completionBlock
                             onError:(TwitterErrorBlock)errorBlock;

@end
