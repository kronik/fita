//
//  DKGooglePlusManager.m
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 22/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKGooglePlusManager.h"
#import "DKSettingsManager.h"

#define kGooglePlusClientID @"122008007740-1huvq9svqqini98dd1rftcrd66p9pul1.apps.googleusercontent.com"
#define kGooglePlusClientSecret @"P2ULC8lRsR0SGiYe-qFvuEdx"
#define kGooglePlusServerSecret @"AIzaSyB4XPPWf0OmSgR-6MyjzNLKxf2Rf7PfGMQ"

#define kGooglePlusDefaultImageSize 640.0

@interface DKGooglePlusManager ()

@property (nonatomic, copy) GPlusLoginBlock loginBlock;
@property (nonatomic, copy) GPlusErrorBlock errorBlock;

@end

@implementation DKGooglePlusManager

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
        
        [GPPSignInButton class];
        
        GPPSignIn *signIn = [GPPSignIn sharedInstance];
        
        signIn.clientID = kGooglePlusClientID;
        signIn.scopes = @[kGTLAuthScopePlusLogin, kGTLAuthScopePlusMe];
        signIn.delegate = _sharedObject;
        signIn.shouldFetchGoogleUserEmail = YES;
        
        [signIn trySilentAuthentication];
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

- (void) connect: (GPlusLoginBlock)completionBlock
           error: (GPlusErrorBlock)errorBlock {
    
    self.loginBlock = completionBlock;
    self.errorBlock = errorBlock;
    
    if ([[GPPSignIn sharedInstance] authentication] == nil) {
        [[GPPSignIn sharedInstance] authenticate];
    } else {
        [self processGoogleAuth];
    }
}

- (void)didDisconnectWithError:(NSError *)error {
    
    if (error) {
        NSLog(@"Received error %@", error);
    } else {
        // The user is signed out and disconnected.
        // Clean up user data as specified by the Google+ terms.
    }
}

- (void)processGoogleAuth {
    
    if (self.loginBlock != nil) {
        [self finishedWithAuth:[GPPSignIn sharedInstance].authentication error:nil];
    }
}

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error {
    
    if (error == nil) {
        
        [DKSettingsManager sharedInstance][kSettingGoogleToken] = auth.accessToken;
        [DKSettingsManager sharedInstance][kSettingGoogleRefreshToken] = auth.refreshToken;
        [DKSettingsManager sharedInstance][kSettingGoogleEmail] = auth.userEmail;
        
        __weak typeof(self) this = self;

        [auth authorizeRequest:nil completionHandler:^(NSError *error) {
            if (error) {
                [[GPPSignIn sharedInstance] signOut];
                
                this.errorBlock(error);
                
                this.loginBlock = nil;
                this.errorBlock = nil;

                return;
            } else {
                [DKSettingsManager sharedInstance][kSettingGoogleToken] = auth.accessToken;
                [DKSettingsManager sharedInstance][kSettingGoogleRefreshToken] = auth.refreshToken;
                [DKSettingsManager sharedInstance][kSettingGoogleEmail] = auth.userEmail;
                [DKSettingsManager sharedInstance][kSettingGoogleAccount] = auth.userEmail;

                GTLServicePlus *plusService = [[GTLServicePlus alloc] init];
                
                plusService.retryEnabled = YES;
                plusService.authorizer = auth;
                
                GTLQueryPlus *query = [GTLQueryPlus queryForPeopleGetWithUserId:@"me"];
                
                [plusService executeQuery:query
                        completionHandler:^(GTLServiceTicket *ticket, GTLPlusPerson *person, NSError *error) {
                            if (error) {
                                if (this.errorBlock) {
                                    this.errorBlock (error);
                                    
                                    this.loginBlock = nil;
                                    this.errorBlock = nil;
                                }
                            } else {
                                
                                NSString *loggedInUser = [DKSettingsManager sharedInstance][kSettingLoggedInUser];

                                if (loggedInUser.length == 0) {
                                    [DKSettingsManager sharedInstance][kSettingLoggedInUser] = person.displayName;
                                }
                                
                                [DKSettingsManager sharedInstance][kSettingGoogleDisplayName] = person.displayName;
                                
                                if (person.image.url.length > 0) {
                                    int width = kGooglePlusDefaultImageSize;
                                    NSString *size = [NSString stringWithFormat:@"sz=%d", width];
                                    
                                    NSRegularExpression *regex =[NSRegularExpression
                                                                 regularExpressionWithPattern:@"\\?sz=\\d+"
                                                                 options:NSRegularExpressionCaseInsensitive
                                                                 error:&error];
                                    
                                    NSString *replaced = [regex stringByReplacingMatchesInString:person.image.url
                                                                                         options:0
                                                                                           range:NSMakeRange(0, person.image.url.length)
                                                                                    withTemplate:@""];
                                    NSString *resizeUrl = [NSString stringWithFormat:@"%@?%@", replaced, size];
                                    
                                    [DKSettingsManager sharedInstance][kSettingGoogleImageUrl] = resizeUrl;
                                }
                                
                                if (this.loginBlock != nil) {
                                    this.loginBlock (person.displayName, auth.userEmail);
                                    
                                    this.loginBlock = nil;
                                    this.errorBlock = nil;
                                }
                            }
                        }];
            }
        }];
    } else {
        [[GPPSignIn sharedInstance] signOut];
        
        if (self.errorBlock != nil) {
            self.errorBlock (error);
            
            self.loginBlock = nil;
            self.errorBlock = nil;
        }
    }
}

- (void) disconnect {
    [[GPPSignIn sharedInstance] disconnect];
}

@end
