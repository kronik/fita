//
//  DKTwitterManager.m
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 22/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKTwitterManager.h"
#import "OAuthCore.h"
#import "DKSettingsManager.h"

#define kOAuthConsumerKey    @"bvFgPvNhsYkl4lYHQjaQ"
#define kOAuthConsumerSecret @"v6NSz2WEyJMHKEqyK0sjvcBTdEgeobNU5xUhFgzwk"

@import Social;

#define TW_API_ROOT                  @"https://api.twitter.com"
#define TW_X_AUTH_MODE_KEY           @"x_auth_mode"
#define TW_X_AUTH_MODE_REVERSE_AUTH  @"reverse_auth"
#define TW_X_AUTH_MODE_CLIENT_AUTH   @"client_auth"
#define TW_X_AUTH_REVERSE_PARMS      @"x_reverse_auth_parameters"
#define TW_X_AUTH_REVERSE_TARGET     @"x_reverse_auth_target"
#define TW_OAUTH_URL_REQUEST_TOKEN   TW_API_ROOT "/oauth/request_token"
#define TW_OAUTH_URL_AUTH_TOKEN      TW_API_ROOT "/oauth/access_token"
#define TW_FETCH_PROFILE_IMAGE_URL   @"https://api.twitter.com/1.1/users/show.json"

#define TW_ERROR_PROCESSING_OAUTH_CODE 89 //Error processing your OAuth request: invalid signature or token

typedef enum TWSignedRequestMethod {
    TWSignedRequestMethodGET,
    TWSignedRequestMethodPOST,
    TWSignedRequestMethodDELETE
} TWSignedRequestMethod;

typedef void(^TWSignedRequestHandler)(NSData *data, NSURLResponse *response, NSError *error);

@interface TWSignedRequest : NSObject

@property (nonatomic, copy) NSString *authToken;
@property (nonatomic, copy) NSString *authTokenSecret;

- (id)initWithURL:(NSURL *)url parameters:(NSDictionary *)parameters requestMethod:(TWSignedRequestMethod)requestMethod;
- (void)performRequestWithHandler:(TWSignedRequestHandler)handler;

@end


@interface DKTwitterManager () <UIActionSheetDelegate> {
    NSArray *accounts;
    ACAccountStore *accountStore;
    
    NSString *twitterToken;
    NSString *twitterSecret;
    NSString *twitterScreenName;
    NSString *profileImageUrl;
}

@property (nonatomic, copy) TwitterLoginBlock loginBlock;
@property (nonatomic, copy) TwitterErrorBlock errorBlock;

@end

@implementation DKTwitterManager

@synthesize loginBlock = _loginBlock;
@synthesize errorBlock = _errorBlock;

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

- (void) connect: (TwitterLoginBlock)completionBlock
           error: (TwitterErrorBlock)errorBlock {
    
    accountStore = [[ACAccountStore alloc] init];
    
    ACAccountType *accountTypeTW = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    if (accountStore && accountTypeTW) {
        
        __weak typeof(self) this = self;
        
        [accountStore requestAccessToAccountsWithType:accountTypeTW options:nil completion:^(BOOL granted, NSError *error) {
            
            if (granted) {
                accounts = [accountStore accountsWithAccountType:accountTypeTW];
                
                if (accounts.count == 0) {
                    if (errorBlock) {
                        NSError *error = [[NSError alloc] initWithDomain:@"com.threadweather.twitter"
                                                                    code:kErrorNoTwitterAccountsConfigured
                                                                userInfo:nil];
                        errorBlock (error);
                    }
                } else if (accounts.count > 1) {
                    this.loginBlock = completionBlock;
                    this.errorBlock = errorBlock;
                    
                    [this selectTwitterAccount];
                } else {
                    
                    this.loginBlock = completionBlock;
                    this.errorBlock = errorBlock;

                    [this loginWithTwitterAccount:accounts.firstObject];
                }
                
            } else {
                if (errorBlock) {
                    NSError *error = [[NSError alloc] initWithDomain:@"com.threadweather.twitter"
                                                                code:kErrorTwitterAccountsAccessDenied
                                                            userInfo:nil];
                    errorBlock (error);
                }
            }
        }];
    } else {
        if (errorBlock) {
            NSError *error = [[NSError alloc] initWithDomain:@"com.threadweather.twitter"
                                                        code:kErrorSystemError
                                                    userInfo:nil];
            errorBlock (error);
        }
    }
}

- (void)loginWithTwitterAccount: (ACAccount *)account {
    
    if (account == nil) {
        if (self.errorBlock) {
            NSError *error = [[NSError alloc] initWithDomain:@"com.threadweather.twitter"
                                                        code:kErrorTwitterAccountSelectionCanceled
                                                    userInfo:nil];
            self.errorBlock (error);
        }
        
        self.loginBlock = nil;
        self.errorBlock = nil;
        
        return;
    }
    
    __weak typeof(self) this = self;

    NSURL *url = [NSURL URLWithString:TW_OAUTH_URL_REQUEST_TOKEN];
    NSDictionary *dict = @{TW_X_AUTH_MODE_KEY: TW_X_AUTH_MODE_REVERSE_AUTH};
    
    TWSignedRequest *step1Request = [[TWSignedRequest alloc] initWithURL:url parameters:dict requestMethod:TWSignedRequestMethodPOST];
   
    [step1Request performRequestWithHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (!data) {
            if (this.errorBlock != nil) {
                this.errorBlock(error);
            }
            
            this.loginBlock = nil;
            this.errorBlock = nil;

            return;
        }
        
        NSString *signedReverseAuthSignature = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        NSDictionary *step2Params = @{TW_X_AUTH_REVERSE_TARGET: kOAuthConsumerKey,
                                      TW_X_AUTH_REVERSE_PARMS: signedReverseAuthSignature};
        
        NSURL *authTokenURL = [NSURL URLWithString:TW_OAUTH_URL_AUTH_TOKEN];
        
        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                requestMethod:SLRequestMethodGET
                                                          URL:authTokenURL
                                                   parameters:step2Params];
        [request setAccount:account];
        
        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            
            if (!responseData) {
                if (this.errorBlock != nil) {
                    this.errorBlock(error);
                }
                return;
            }
            
            NSString *responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            
            for (NSString *part in [responseStr componentsSeparatedByString:@"&"]) {
                NSArray *pair = [part componentsSeparatedByString:@"="];
                
                if (pair.count == 2) {
                    
                    NSString *key = pair [0];
                    NSString *value = pair [1];
                    
                    if ([key isEqualToString:@"oauth_token"]) {
                        twitterToken = value;
                    } else if ([key isEqualToString:@"oauth_token_secret"]) {
                        twitterSecret = value;
                    }
                    else if ([key isEqualToString:@"screen_name"]) {
                        twitterScreenName = value;
                    }
                }
            }
            
            if (!twitterToken || !twitterSecret) {
                
                if (this.errorBlock != nil) {
                    this.errorBlock(error);
                }
                
                this.loginBlock = nil;
                this.errorBlock = nil;

                return;
            }
            
            [DKSettingsManager sharedInstance][kSettingTwitterAccount] = twitterScreenName;
            [DKSettingsManager sharedInstance][kSettingTwitterDisplayName] = twitterScreenName;
            [DKSettingsManager sharedInstance][kSettingTwitterToken] = twitterToken;
            [DKSettingsManager sharedInstance][kSettingTwitterSecret] = twitterSecret;

            NSString *loggedInUser = [DKSettingsManager sharedInstance][kSettingLoggedInUser];
            
            if (loggedInUser.length == 0) {
                [DKSettingsManager sharedInstance][kSettingLoggedInUser] = twitterScreenName;
            }

            if (this.loginBlock) {
                this.loginBlock(twitterScreenName, @"");
            }
            
            this.loginBlock = nil;
            this.errorBlock = nil;
        }];
    }];
}

- (void)selectTwitterAccount {
	UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Twitter account", nil)
                                                        delegate:self
                                               cancelButtonTitle:nil
										  destructiveButtonTitle:nil otherButtonTitles:nil];

	for (ACAccount *account in accounts) {
		[action addButtonWithTitle:account.username];
	}
	
    [action addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
	action.cancelButtonIndex = accounts.count;
    
    UIView *rootView = [UIApplication sharedApplication].keyWindow.rootViewController.view;

	[action showInView:rootView];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	
    if (buttonIndex != actionSheet.cancelButtonIndex) {
		[self loginWithTwitterAccount: accounts[buttonIndex]];
	} else {
        [self loginWithTwitterAccount: nil];
    }
}

- (void)parseTwitterInfoResponse: (NSData *)responseData
             withCompletionBlock: (TwitterProfilePicFetchBlock)completionBlock {
    
    NSDictionary * respDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
    
    profileImageUrl = [respDictionary [@"profile_image_url"] stringByReplacingOccurrencesOfString:@"_normal" withString:@""];
    
    if (completionBlock != nil) {
        completionBlock(profileImageUrl);
    }
}

- (void) fetchProfilePicOnCompletion:(TwitterProfilePicFetchBlock)completionBlock
                             onError:(TwitterErrorBlock)errorBlock {
    
    NSURL *url = [NSURL URLWithString:TW_FETCH_PROFILE_IMAGE_URL];
    
    NSDictionary *params = @{@"screen_name": twitterScreenName, @"size": @"original"};
    
    SLRequest *request  = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                             requestMethod:SLRequestMethodGET
                                                       URL:url
                                                parameters:params];
    if (twitterScreenName.length > 0) {
        
        for (ACAccount *account in accounts) {
            if ([account.username isEqualToString: twitterScreenName]) {
                [request setAccount:account];
                
                break;
            }
        }
        
        [request performRequestWithHandler: ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            
            if (responseData != nil && error == nil) {
                [self parseTwitterInfoResponse: responseData withCompletionBlock:completionBlock];
            }
            else {
                errorBlock(error);
            }
        }];
    }
    else {
        
        [self connect:^(NSString *token,NSString *secret){
            [request performRequestWithHandler: ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                
                if (responseData != nil && error == nil) {
                    [self parseTwitterInfoResponse: responseData withCompletionBlock:completionBlock];
                }
                else {
                    errorBlock(error);
                }
            }];
        } error:^(NSError *error){
            
        }];
    }
}

@end

#define TW_HTTP_METHOD_GET @"GET"
#define TW_HTTP_METHOD_POST @"POST"
#define TW_HTTP_METHOD_DELETE @"DELETE"
#define TW_HTTP_HEADER_AUTHORIZATION @"Authorization"

@interface TWSignedRequest()
{
    NSURL *_url;
    NSDictionary *_parameters;
    TWSignedRequestMethod _signedRequestMethod;
}

- (NSURLRequest *)_buildRequest;

@end

@implementation TWSignedRequest
@synthesize authToken = _authToken;
@synthesize authTokenSecret = _authTokenSecret;

- (id)initWithURL:(NSURL *)url
       parameters:(NSDictionary *)parameters
    requestMethod:(TWSignedRequestMethod)requestMethod;
{
    self = [super init];
    if (self) {
        _url = url;
        _parameters = parameters;
        _signedRequestMethod = requestMethod;
    }
    return self;
}

- (NSURLRequest *)_buildRequest
{
    NSString *method;
    
    switch (_signedRequestMethod) {
        case TWSignedRequestMethodPOST:
            method = TW_HTTP_METHOD_POST;
            break;
        case TWSignedRequestMethodDELETE:
            method = TW_HTTP_METHOD_DELETE;
            break;
        case TWSignedRequestMethodGET:
        default:
            method = TW_HTTP_METHOD_GET;
    }
    
    //  Build our parameter string
    NSMutableString *paramsAsString = [[NSMutableString alloc] init];
    [_parameters enumerateKeysAndObjectsUsingBlock:
     ^(id key, id obj, BOOL *stop) {
         [paramsAsString appendFormat:@"%@=%@&", key, obj];
     }];
    
    //  Create the authorization header and attach to our request
    NSData *bodyData = [paramsAsString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authorizationHeader = OAuthorizationHeader(_url,
                                                         method,
                                                         bodyData,
                                                         kOAuthConsumerKey,
                                                         kOAuthConsumerSecret,
                                                         _authToken,
                                                         _authTokenSecret);
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:_url];
    [request setHTTPMethod:method];
    [request setValue:authorizationHeader
   forHTTPHeaderField:TW_HTTP_HEADER_AUTHORIZATION];
    [request setHTTPBody:bodyData];
    
    return request;
}

- (void)performRequestWithHandler:(TWSignedRequestHandler)handler
{
    dispatch_async(dispatch_get_global_queue
                   (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                       NSURLResponse *response;
                       NSError *error;
                       NSData *data = [NSURLConnection
                                       sendSynchronousRequest:
                                       [self _buildRequest]
                                       returningResponse:&response
                                       error:&error];
                       handler(data, response, error);
                   });
}

@end
