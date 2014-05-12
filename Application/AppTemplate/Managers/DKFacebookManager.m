//
//  DKFacebookManager.m
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 21/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKFacebookManager.h"
#import "DKSettingsManager.h"
#import "DKNetworkManager.h"

@import Accounts;
@import Social;

#define kFacebookAppId @"619570318128657"
#define kFacebookAppSecret @"a5ab9ce6600125b2aa4b966965cdd3a3"

typedef enum DKFacebookRequestType {
    
    kFacebookReqTypeNone = 0,
    kFacebookReqTypeSendAppRequest,
    kFacebookReqTypeReqFanPages,
    kFacebookReqTypeReauthorizePermissions,
    
} DKFacebookRequestType;

@interface DKFacebookManager () {
    FBSession *fbSession;
    
    FacebookLoginBlock loginCompletionBlock;
    FacebookErrorBlock loginErrorBlock;
    FacebookOperationCompletionBlock reauthorizeCompletionHandler;
    FacebookErrorBlock reauthorizeErrorBlock;
    FacebookOperationCompletionBlock sendAppReqCompletionBlock;
    FacebookErrorBlock sendAppReqErrorBlock;
    FacebookErrorBlock profilePicErrorBlock;
    
    FacebookErrorBlock openSessionErrorBlock;
    FacebookOperationCompletionBlock openSessionCompletionBlock;
}

@end

@implementation DKFacebookManager

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

- (id)init {
    self = [super init];
    
	if (self != nil) {
    }
    
    return self;
}

- (void)initFBSession {
    
    __weak typeof(self) this = self;

    [FBSession.activeSession setStateChangeHandler:^(FBSession *session, FBSessionState state, NSError *error) {
        [this sessionStateChanged:session state:state error:error];
    }];
    
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        // If there's one, just open the session silently, without showing the user the login UI
        [FBSession openActiveSessionWithReadPermissions:@[@"basic_info", @"email", @"user_likes"]
                                           allowLoginUI:NO
                                      completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                          // Handler for session state changes
                                          // This method will be called EACH time the session state changes,
                                          // also for intermediate states and NOT just when the session open
                                          [this sessionStateChanged:session state:state error:error];
                                      }];
    }
}

- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error {
    
    switch (state) {
            
        case FBSessionStateOpen: {
            
            if (!error) {
                // We have a valid session
                fbSession = [FBSession activeSession];
                
                [DKSettingsManager sharedInstance][kSettingFacebookToken] = fbSession.accessTokenData.accessToken;
                
                if (openSessionCompletionBlock) {
                    
                    openSessionCompletionBlock();
                    openSessionCompletionBlock = nil;
                }
                
            }
            else {
                
                if (openSessionErrorBlock) {
                    openSessionErrorBlock(error);
                    openSessionErrorBlock = nil;
                }
            }
            
        }
            break;
        case FBSessionStateClosed: {
            
            fbSession = nil;
            if (openSessionCompletionBlock) {
                
                openSessionCompletionBlock();
                openSessionCompletionBlock = nil;
                openSessionErrorBlock = nil;
            }
        }
            break;
        case FBSessionStateClosedLoginFailed: {
            
            fbSession = nil;

            if (openSessionErrorBlock) {
                openSessionErrorBlock(error);
                openSessionErrorBlock = nil;
                openSessionCompletionBlock = nil;
            }
            
        }
            break;
        default:
            break;
    }
}

- (BOOL) isSessionOpen {
    return FBSession.activeSession.isOpen;
}

- (void) connect: (FacebookLoginBlock)completionBlock
           error: (FacebookErrorBlock)errorBlock {
 
    __weak typeof(self) this = self;

    loginCompletionBlock = completionBlock;
    loginErrorBlock = errorBlock;
    
    if ([self isSessionOpen]) {
        [self loadProfile];
    } else {
        [self openSession:^(){
            [this loadProfile];
        }
        onError:^(NSError *error){
          
            if (loginErrorBlock) {
                loginErrorBlock(error);
                
                loginCompletionBlock = nil;
                loginErrorBlock = nil;
            }
        }];
    }
}

- (void)loadProfile {
    NSString *accessToken = FBSession.activeSession.accessTokenData.accessToken;
    NSString *urlString = [NSString stringWithFormat:@"https://graph.facebook.com/me?access_token=%@", [accessToken stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    [[DKNetworkManager sharedInstance] getDataForUrl:urlString onCompletion:^(NSDictionary *responseData) {
        
        NSString *fullName = responseData[@"name"];

        [DKSettingsManager sharedInstance][kSettingFacebookAccount] = fullName;
        [DKSettingsManager sharedInstance][kSettingFacebookDisplayName] = fullName;
        [DKSettingsManager sharedInstance][kSettingFacebookEmail] = responseData[@"email"];

        NSString *loggedInUser = [DKSettingsManager sharedInstance][kSettingLoggedInUser];
        
        if (loggedInUser.length == 0) {
            [DKSettingsManager sharedInstance][kSettingLoggedInUser] = fullName;
        }

        if (loginCompletionBlock) {

            loginCompletionBlock(fullName, FBSession.activeSession.accessTokenData.accessToken);
            
            loginCompletionBlock = nil;
            loginErrorBlock = nil;
        }

    } onError:^(NSError *error) {
        if (loginErrorBlock) {
            loginErrorBlock(error);
            
            loginCompletionBlock = nil;
            loginErrorBlock = nil;
        }
    }];
}

- (void) openSession:(FacebookOperationCompletionBlock) completionBlock onError:(FacebookErrorBlock)errorBlock {
    
    openSessionCompletionBlock = completionBlock;
    openSessionErrorBlock = errorBlock;
    
    __weak typeof(self) this = self;

    [self renewFBAccountCredentialsIfExist:^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([this openSessionWithAllowLoginUI: NO] == NO) {
                [this openSessionWithAllowLoginUI: YES];
            }
        });
    }];
}

- (BOOL) openSessionWithAllowLoginUI:(BOOL)allowLoginUI {
    
    __weak typeof(self) this = self;

    return [FBSession openActiveSessionWithReadPermissions:@[@"basic_info", @"email", @"user_likes"]
                                              allowLoginUI:allowLoginUI
                                         completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                             
                                             if (error) {
                                                 if (openSessionErrorBlock) {
                                                     openSessionErrorBlock(error);
                                                     openSessionErrorBlock = nil;
                                                     openSessionCompletionBlock = nil;
                                                     
                                                 }
                                                 [this handleRequestPermissionError:error];
                                             }
                                             else {
                                                 
                                                 [this sessionStateChanged:session state:state error:error];
                                             }
                                         }];
}

- (void) renewFBAccountCredentialsIfExist:(FacebookOperationCompletionBlock) completionBlock {
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountTypeFB = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    if (accountStore && accountTypeFB) {
        
        NSArray *fbAccounts = [accountStore accountsWithAccountType:accountTypeFB];
        
        id account = fbAccounts.firstObject;
        
        if (fbAccounts && account) {
            
            [accountStore renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
                //we don't actually need to inspect renewResult or error.
                
                if (completionBlock) {
                    completionBlock();
                }
            }];
        }
        else {
            if (completionBlock) {
                completionBlock();
            }
        }
    }
    else {
        if (completionBlock) {
            completionBlock();
        }
    }
}


//    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
//    ACAccountType *accountTypeFB = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
//    
//    if (accountStore && accountTypeFB) {
//        
//        NSArray *fbAccounts = [accountStore accountsWithAccountType:accountTypeFB];
//        ACAccount *account = fbAccounts.firstObject;
//        
//        if (fbAccounts.count > 0 && account){
//            
//            [accountStore renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
//                //we don't actually need to inspect renewResult or error.
//                
//                if (completionBlock) {
//                    completionBlock();
//                }
//            }];
//        }
//        else {
//            
//            NSDictionary *options = @{
//                                      ACFacebookAppIdKey:@"12345678987654",
//                                      ACFacebookPermissionsKey:@[@"email", @"basic_info"]
//                                      };
//            
//            ACAccountStoreRequestAccessCompletionHandler handler = ^(BOOL granted, NSError *error) {
//                NSLog(@"Error: %@", error);
//            };
//            
//            [accountStore requestAccessToAccountsWithType:accountTypeFB options:options completion:handler];
//
//            if (completionBlock) {
//                completionBlock();
//            }
//        }
//    }
//    else {
//        if (completionBlock) {
//            completionBlock();
//        }
//    }
//}

- (void)loadInfoForAccount: (ACAccount *)account {
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                            requestMethod:SLRequestMethodGET
                                                      URL:[NSURL URLWithString:@"https://graph.facebook.com/me"]
                                               parameters:nil];
    request.account = account; // This is the account from your code
    [request performRequestWithHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil && ((NSHTTPURLResponse *)response).statusCode == 200) {
            NSError *deserializationError;
            NSDictionary *userData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&deserializationError];
            
            if (userData != nil && deserializationError == nil) {
                NSString *fullName = userData[@"name"];
                NSLog(@"%@", fullName);
            }
        }
    }];
}

- (void)disconnect {
    if (FBSession.activeSession.state == FBSessionStateOpen
        || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        
        // Close the session and remove the access token from the cache
        // The session state handler (in the app delegate) will be called automatically
        [FBSession.activeSession closeAndClearTokenInformation];
    }
}

- (void) resumeSession {
    [FBAppCall handleDidBecomeActive];
}

- (void)handleRequestPermissionError:(NSError *)error {
    if (error.fberrorShouldNotifyUser) {
        // If the SDK has a message for the user, surface it.
        [[[UIAlertView alloc] initWithTitle:@"Whoops!"
                                    message:error.fberrorUserMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    } else {
        if (error.fberrorCategory == FBErrorCategoryUserCancelled){
            // The user has cancelled the request. You can inspect the value and
            // inner error for more context. Here we simply ignore it.
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error", nil)
                                        message:NSLocalizedString(@"The user has cancelled the request", nil)
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil] show];
        }
    }
}

//typedef void(^HandlerType)(ACAccount* account);
//
//- (void)performForFacebookAccount: (HandlerType) handler{
//    if (_accountFacebook) {
//        handler(_accountFacebook);
//        return;
//    }
//    
//    if (!_accountStoreFacebook) {
//        _accountStoreFacebook = ACAccountStore.new;
//    }
//    
//    ACAccountType *accountTypeFacebook = [self.accountStoreFacebook accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
//    NSDictionary *options = @{ACFacebookAppIdKey : @"xxxxxxxxx",
//                              ACFacebookAudienceKey : ACFacebookAudienceEveryone,
//                              ACFacebookPermissionsKey : @[@"user_about_me", @"publish_actions"]
//                              };
//    
//    [_accountStoreFacebook requestAccessToAccountsWithType:accountTypeFacebook options:options completion:^(BOOL granted, NSError *error) {
//        if (granted) {
//            NSLog(@"Facebook access granted");
//            _accountFacebook = _accountStoreFacebook.accounts.lastObject;
//            
//            handler(_accountFacebook);
//            
//        }else {
//            NSLog(@"Facebook access denied");
//            _accountFacebook = nil;}
//        if (error) {
//            NSLog(error.localizedDescription);
//        }
//    }];
//}

@end
