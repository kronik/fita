//
//  DKLoginViewController.m
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 23/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKLoginViewController.h"
#import "DKSettingsManager.h"
#import "BButton.h"
#import "FBShimmeringView.h"

@import QuartzCore;

typedef void (^AfterAnimationBlock)();

@interface DKLoginViewController ()

@property (nonatomic, strong) UILabel *logoLabel1;
@property (nonatomic, strong) UILabel *logoLabel2;
@property (nonatomic, strong) BButton *facebookButton;
@property (nonatomic, strong) BButton *twitterButton;
@property (nonatomic, strong) BButton *googleButton;
@property (nonatomic, strong) NSArray *itemViews;
@property (nonatomic, strong) UIImageView *backgroundAnimationView;
@property (nonatomic, strong) FBShimmeringView *shimmeringView;

@end

@implementation DKLoginViewController

@synthesize facebookButton = _facebookButton;
@synthesize twitterButton = _twitterButton;
@synthesize googleButton = _googleButton;
@synthesize itemViews = _itemViews;
@synthesize logoLabel1 = _logoLabel1;
@synthesize logoLabel2 = _logoLabel2;
@synthesize shimmeringView = _shimmeringView;
@synthesize backgroundAnimationView = _backgroundAnimationView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    NSString *launchImage = @"LaunchImage-700";
    
    if  ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) &&
         (ScreenHeight > 480.0f)) {
        launchImage = @"LaunchImage-700-568h";
    } else {
        launchImage = @"LaunchImage-700";
    }
    
    self.backgroundAnimationView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.backgroundAnimationView.image = [UIImage imageNamed:launchImage];

    [self.view addSubview: self.backgroundAnimationView];
    
    self.view.backgroundColor = ApplicationMainColor;
    
    [self.view addSubview:imageView];
    
    CGRect shimmeringFrame = self.view.bounds;
    shimmeringFrame.origin.y = 200;
    shimmeringFrame.size.height = shimmeringFrame.size.height * 0.32;
    
    self.shimmeringView = [[FBShimmeringView alloc] initWithFrame:shimmeringFrame];
    
    self.shimmeringView.shimmering = NO;
    self.shimmeringView.shimmeringBeginFadeDuration = 0.3;
    self.shimmeringView.shimmeringOpacity = 0.3;
    self.shimmeringView.alpha = 0;
    
    [self.view addSubview:self.shimmeringView];

//    self.logoLabel1 = [[UILabel alloc] initWithFrame:CGRectMake(-5, 280, ScreenWidth / 2, 100)];
//    
//    self.logoLabel1.text = @"Thread";
//    self.logoLabel1.font = [UIFont fontWithName:ApplicationLightFont size:35.0];
//    self.logoLabel1.textColor = [UIColor blackColor];
//    self.logoLabel1.textAlignment = NSTextAlignmentRight;
//    
//    [self.view addSubview:self.logoLabel1];
//
//    self.logoLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(-5 + ScreenWidth / 2, 280, ScreenWidth / 2, 100)];
//    
//    self.logoLabel2.text = @"Weather";
//    self.logoLabel2.font = [UIFont fontWithName:ApplicationLightFont size:35.0];
//    self.logoLabel2.textColor = [UIColor whiteColor];
//    self.logoLabel2.textAlignment = NSTextAlignmentLeft;
//    
//    [self.view addSubview:self.logoLabel2];
    
    UILabel *joinLabel = [[UILabel alloc] initWithFrame:self.shimmeringView.bounds];
    
    joinLabel.text = NSLocalizedString(@"Join today", nil);
    joinLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:35.0];
    joinLabel.textColor = [UIColor whiteColor];
    joinLabel.textAlignment = NSTextAlignmentCenter;
    
    self.shimmeringView.contentView = joinLabel;

    self.facebookButton = [[BButton alloc] initWithFrame:CGRectMake(ScreenWidth * 2, 350, ScreenWidth - 100, 60) type:BButtonTypeFacebook style:BButtonStyleBootstrapV3];
    
    self.facebookButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.facebookButton.layer.borderWidth = 0.5;
    self.facebookButton.layer.cornerRadius = 2;
    self.facebookButton.titleLabel.font = [UIFont fontWithName:ApplicationFont size:25];

    [self.facebookButton setTitle:@"Facebook" forState:UIControlStateNormal];
    [self.facebookButton addAwesomeIcon:FAIconFacebook beforeTitle:YES];
    [self.facebookButton addTarget:self action:@selector(facebookButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.facebookButton];

    self.twitterButton = [[BButton alloc] initWithFrame:CGRectMake(-ScreenWidth, 440, ScreenWidth - 100, 60) type:BButtonTypeTwitter style:BButtonStyleBootstrapV3];
    
    self.twitterButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.twitterButton.layer.borderWidth = 0.5;
    self.twitterButton.layer.cornerRadius = 2;
    self.twitterButton.titleLabel.font = [UIFont fontWithName:ApplicationFont size:25];

    [self.twitterButton setTitle:@"Twitter" forState:UIControlStateNormal];
    [self.twitterButton addAwesomeIcon:FAIconTwitter beforeTitle:YES];
    [self.twitterButton addTarget:self action:@selector(twitterButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.twitterButton];

//    self.googleButton = [[BButton alloc] initWithFrame:CGRectMake(ScreenWidth * 2, 420, ScreenWidth - 160, 40) type:BButtonTypeGoogle style:BButtonStyleBootstrapV3];
//
//    self.googleButton.layer.borderColor = [UIColor whiteColor].CGColor;
//    self.googleButton.layer.borderWidth = 0.5;
//
//    [self.googleButton setTitle:@"Google" forState:UIControlStateNormal];
//    [self.googleButton addAwesomeIcon:FAIconGooglePlus beforeTitle:YES];
//    [self.googleButton addTarget:self action:@selector(googleButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
//    
//    [self.view addSubview:self.googleButton];
    
    self.itemViews = @[self.facebookButton, self.twitterButton];
}

- (void)dealloc {
    self.itemViews = nil;    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    __weak typeof(self) this = self;

    
    [UIView animateWithDuration:0.5 delay:0.5 options:UIViewAnimationOptionCurveEaseIn  animations:^{
        
        if (ScreenHeight > 480.0f) {
            self.backgroundAnimationView.center = CGPointMake(ScreenWidth / 2, (ScreenHeight / 2) - (ScreenHeight / 4));
        } else {
            self.backgroundAnimationView.center = CGPointMake(ScreenWidth / 2, (ScreenHeight / 2) - (ScreenHeight / 10));
        }
        
//        self.logoLabel1.frame = CGRectMake(-5, 100, ScreenWidth / 2, 100);
//        self.logoLabel2.frame = CGRectMake(-5 + ScreenWidth / 2, 100, ScreenWidth / 2, 100);
    } completion:^(BOOL finished) {
        [this showAllButtonsWithBlock:nil];

    }];
}

- (void)hideAllButtonsWithBock: (AfterAnimationBlock)afterAnimationBlock {
    
    CGFloat initDelay = 0.1f;
    SEL sdkSpringSelector = NSSelectorFromString(@"animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:");
    BOOL sdkHasSpringAnimation = [UIView respondsToSelector:sdkSpringSelector];

    __weak typeof(self) this = self;

    [self.itemViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        if (sdkHasSpringAnimation) {
            [this slideDownAnimationWithView:view idx:idx initDelay:initDelay andBock:afterAnimationBlock];
//            [this animateSpringWithView:view idx:idx initDelay:initDelay reversed:YES andBock:afterAnimationBlock];
        }
        else {
            [this animateFauxBounceWithView:view idx:idx initDelay:initDelay reversed:YES andBock:afterAnimationBlock];
        }
    }];
}

- (void)showAllButtonsWithBlock: (AfterAnimationBlock)afterAnimationBlock {
    
    CGFloat initDelay = 0.1f;
    SEL sdkSpringSelector = NSSelectorFromString(@"animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:");
    BOOL sdkHasSpringAnimation = [UIView respondsToSelector:sdkSpringSelector];
    
    __weak typeof(self) this = self;
    
    [self.itemViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {

//        view.layer.transform = CATransform3DMakeScale(0.3, 0.3, 1);
        view.alpha = 1;
        
        if (idx % 2 == 0) {
            view.center = CGPointMake(ScreenWidth * 2, 350 + (60 * idx));
        } else {
            view.center = CGPointMake(-ScreenWidth, 350 + (60 * idx));
        }

        if (sdkHasSpringAnimation) {
            [this animateSpringWithView:view idx:idx initDelay:initDelay reversed:NO andBock:afterAnimationBlock];
        }
        else {
            [this animateFauxBounceWithView:view idx:idx initDelay:initDelay reversed:NO andBock:afterAnimationBlock];
        }
    }];
}

- (void)slideDownAnimationWithView:(UIView *)view idx:(NSUInteger)idx
                         initDelay:(CGFloat)initDelay
                           andBock:(AfterAnimationBlock)afterAnimationBlock {

    __weak typeof(self) this = self;

    [UIView animateWithDuration:0.2 delay:(initDelay + idx*0.1f) options:UIViewAnimationOptionCurveEaseIn animations:^{
        view.center = CGPointMake(ScreenWidth / 2, ScreenHeight + 60);
    } completion:^(BOOL finished) {
        if (afterAnimationBlock && (idx == this.itemViews.count - 1)) {
            afterAnimationBlock ();
        }
    }];
}

- (void)animateSpringWithView:(UIView *)view idx:(NSUInteger)idx
                    initDelay:(CGFloat)initDelay
                     reversed:(BOOL)reversed
                      andBock:(AfterAnimationBlock)afterAnimationBlock {
    
    __weak typeof(self) this = self;

    self.shimmeringView.shimmering = NO;

    [UIView animateWithDuration:0.5
                          delay:(initDelay + idx*0.1f)
//         usingSpringWithDamping:1
//          initialSpringVelocity:5
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                         self.shimmeringView.alpha = 1;
                         
                         if (reversed) {
                             view.center = CGPointMake(ScreenWidth / 2, ScreenHeight + 60);
//                             view.alpha = 0.1;
                         } else {
//                             view.layer.transform = CATransform3DIdentity;
                             view.alpha = 1;
                             view.frame = CGRectMake(50, 350 + (80 * idx), ScreenWidth - 100, 60);
                         }
                     }
                     completion:^(BOOL finished) {
                         if (afterAnimationBlock && (idx == this.itemViews.count - 1)) {
                             afterAnimationBlock ();
                         }
                     }];
}

- (void)animateFauxBounceWithView:(UIView *)view
                              idx:(NSUInteger)idx
                        initDelay:(CGFloat)initDelay
                         reversed:(BOOL)reversed
                          andBock:(AfterAnimationBlock)afterAnimationBlock {

    __weak typeof(self) this = self;

    [UIView animateWithDuration:0.2
                          delay:(initDelay + idx*0.1f)
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveEaseInOut
                     animations:^{
                         if (reversed) {
                             view.layer.transform = CATransform3DMakeScale(0.3, 0.3, 1);
                             view.center = CGPointMake(ScreenWidth / 2, ScreenHeight + 60);
                         } else {
                             view.layer.transform = CATransform3DMakeScale(1.1, 1.1, 1);
                             view.alpha = 1;
                             view.frame = CGRectMake(80, 300 + (60 * idx), ScreenWidth - 160, 40);
                         }
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.1 animations:^{
                             view.layer.transform = CATransform3DIdentity;
                         } completion:^(BOOL finished) {
                             if (afterAnimationBlock && (idx == this.itemViews.count - 1)) {
                                 afterAnimationBlock ();
                             }
                         }];
                     }];
}

- (void)facebookButtonPressed: (UIButton *)button {
//    __weak typeof(self) this = self;
//    
//    [Flurry logEvent:@"Login with Facebook"];
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [this hideAllButtonsWithBock:^{
//            [this showBigBusyIndicatorWithTitle:NSLocalizedString(@"Loading...", nil)];
//            
//            [[DKSocialManager sharedInstance] connect:^(NSString *userName) {
//                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [this hideIndicator];
//                    
//                    [UIView animateWithDuration:0.3 animations:^{
//                        this.backgroundAnimationView.alpha = 0;
//                    } completion:^(BOOL finished) {
//                        [this showCompleteIndicatorWithTitle:userName];
//                        [[NSNotificationCenter defaultCenter] postNotificationName:kSuccessLoginNotification object:nil];
//                    }];
//                });
//
//            } toSocialType:kSocialConnectionTypeFacebook error:^(NSError *error) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [this showErrorIndicatorWithTitle:NSLocalizedString(@"Failed to connect", nil)];
//                    [this showAllButtonsWithBlock:nil];
//                });
//            }];
//        }];
//    });
}

- (void)twitterButtonPressed: (UIButton *)button {
//    __weak typeof(self) this = self;
//    
//    [Flurry logEvent:@"Login with Twitter"];
//
//    [self hideAllButtonsWithBock:^{
//        [this showBigBusyIndicatorWithTitle:NSLocalizedString(@"Loading...", nil)];
//        
//        [[DKSocialManager sharedInstance] connect:^(NSString *userName) {
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [this hideIndicator];
//                
//                [UIView animateWithDuration:0.3 animations:^{
//                    this.backgroundAnimationView.alpha = 0;
//                } completion:^(BOOL finished) {
//                    [this showCompleteIndicatorWithTitle:userName];
//                    [[NSNotificationCenter defaultCenter] postNotificationName:kSuccessLoginNotification object:nil];
//                }];
//            });
//            
//        } toSocialType:kSocialConnectionTypeTwitter error:^(NSError *error) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [this showErrorIndicatorWithTitle:NSLocalizedString(@"Failed to connect", nil)];
//                [this showAllButtonsWithBlock:nil];
//            });
//        }];
//    }];
}

- (void)googleButtonPressed: (UIButton *)button {
    
//    __weak typeof(self) this = self;
//    
//    [Flurry logEvent:@"Login login Google+"];
//
//    [self hideAllButtonsWithBock:^{
//        [this showBigBusyIndicatorWithTitle:NSLocalizedString(@"Loading...", nil)];
//        
//        [[DKGooglePlusManager sharedInstance] connect:^(NSString *userName, NSString *email) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [this hideIndicator];
//                
//                [UIView animateWithDuration:0.3 animations:^{
//                    self.backgroundAnimationView.alpha = 0;
//                    //                        self.backgroundAnimationView.center = CGPointMake(ScreenWidth / 2, ScreenHeight / 2);
//                } completion:^(BOOL finished) {
//                    [this showCompleteIndicatorWithTitle:userName];
//                    [[NSNotificationCenter defaultCenter] postNotificationName:kSuccessLoginNotification object:nil];
//                }];
//            });
//        } error:^(NSError *error) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [this showErrorIndicatorWithTitle:NSLocalizedString(@"Failed to connect", nil)];
//                [this showAllButtonsWithBlock:nil];
//            });
//        }];
//    }];
}

@end
