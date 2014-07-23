//
//  DKBaseViewController.m
//  AppTemplate
//
//  Created by Dmitry Klimkin on 27/2/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKBaseViewController.h"
#import "DKCircleImageView.h"
#import "DKAppColorViewController.h"
#import "DKStoreManager.h"
#import "DKSettingsManager.h"

#import "MRProgress.h"

#define DURATION    0.65
#define MAX_DELAY   0.15

#ifdef FREE

@interface DKBaseViewController () <UISearchBarDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate, GADBannerViewDelegate>

#else

@interface DKBaseViewController () <UISearchBarDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate>

#endif

@property (nonatomic, strong) MRProgressOverlayView *progressView;
@property (nonatomic, strong) NSTimer *progresViewTimer;
@property (nonatomic) float elementsAnimationDelta;

@end

@implementation DKBaseViewController

@synthesize items = _items;
@synthesize searchBar = _searchBar;
@synthesize progressView = _progressView;
@synthesize progresViewTimer = _progresViewTimer;
@synthesize tableView = _tableView;
@synthesize elementsAnimationDelta = _elementsAnimationDelta;

#ifdef FREE

@synthesize adBanner = adBanner_;
@synthesize request = _request;

#endif

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self customInit];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        // Custom initialization
        [self customInit];
    }
    return self;
}

- (void)customInit {
    _elementsAnimationDelta = ScreenWidth;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.elementsAnimationDelta = ScreenWidth;

    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = ApplicationMainColor;

    [self setNeedsStatusBarAppearanceUpdate];
    [self.navigationController interactivePopGestureRecognizer];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onColorDidChange) name:kAppColorDidChangeNotification object:nil];
    
#ifdef FREE
    
    if ([[DKSettingsManager sharedInstance][kSettingNoAdvApp] boolValue] == NO) {
        self.adBanner = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
        
        // Disable wi-fi to test the ad
        
        self.adBanner.adUnitID = @"ca-app-pub-6418819291105012/8611587085";
        self.adBanner.delegate = self;
        self.adBanner.rootViewController = self;
        self.adBanner.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        
        [self.adBanner loadRequest:[this createRequest]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unlockNoAdvProduct:) name:kUnlockNoAdvProductNotification object:nil];
    }
#endif
    
    // Set realm notification block
    __weak typeof(self) this = self;
    self.notification = [RLMRealm.defaultRealm addNotificationBlock:^(NSString *note, RLMRealm *realm) {
        [this reloadData];
    }];
    [self reloadData];
}

- (void)reloadData {
    
}

- (void)onColorDidChange {
    self.view.backgroundColor = ApplicationMainColor;
    self.tableView.backgroundColor = ApplicationMainColor;
}

- (void)updateUI {
    [self hideIndicator];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    __weak typeof(self) this = self;
    
    [[self visibleCells] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UITableViewCell *obj, NSUInteger idx, BOOL *stop) {
        NSTimeInterval delay = ((float)idx / (float)[[this visibleCells] count]) * MAX_DELAY;
        [this hideView:obj withDelay:delay andDelta:-this.elementsAnimationDelta];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
   
    [[self visibleCells] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UITableViewCell *obj, NSUInteger idx, BOOL *stop) {
        obj.center = CGPointMake(ScreenWidth + self.elementsAnimationDelta / 2, obj.center.y);
        obj.alpha = 0;
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    __weak typeof(self) this = self;

    [[self visibleCells] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UITableViewCell *obj, NSUInteger idx, BOOL *stop) {
        NSTimeInterval delay = ((float)idx / (float)[[this visibleCells] count]) * MAX_DELAY;
        
        [this presentView:obj withDelay:delay andDelta:this.elementsAnimationDelta];
    }];
}

#pragma mark - Search Bar Delegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	if (self.searchBar.text.length > 0) {
		[self doSearch];
	} else {
	}
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	[self.searchBar resignFirstResponder];
	// Clear search bar text
	self.searchBar.text = @"";
	// Hide the cancel button
	self.searchBar.showsCancelButton = NO;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	self.searchBar.showsCancelButton = YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[self.searchBar resignFirstResponder];
	[self doSearch];
}

- (void)doSearch {
}

- (void)quickHideIndicator {
    if (self.progressView) {
        [self.progressView dismiss:NO];
    }

    [self.progresViewTimer invalidate];
    
    self.progresViewTimer = nil;
}

- (void)showCompleteIndicator {
    [self showCompleteIndicatorWithTitle:@""];
}

- (void)showCompleteIndicatorWithTitle: (NSString *)title {

    [self quickHideIndicator];
    
    self.progressView = [MRProgressOverlayView new];
    self.progressView.mode = MRProgressOverlayViewModeCheckmark;
    self.progressView.titleLabelText = title;
    
    [self showIndicator];
    
    self.progresViewTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(hideIndicator) userInfo:nil repeats:NO];
}

- (void)showErrorIndicator {
    [self showErrorIndicatorWithTitle:@""];
}

- (void)showErrorIndicatorWithTitle: (NSString *)title {
    
    [self quickHideIndicator];
    
    self.progressView = [MRProgressOverlayView new];
    self.progressView.mode = MRProgressOverlayViewModeCross;
    self.progressView.titleLabelText = title;
    
    [self showIndicator];
    
    self.progresViewTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(hideIndicator) userInfo:nil repeats:NO];
}

- (void)showBigBusyIndicator {
    [self showBigBusyIndicatorWithTitle:@""];
}

- (void)showBigBusyIndicatorWithTitle: (NSString *)title {
    
    [self quickHideIndicator];
    
    self.progressView = [MRProgressOverlayView new];
    self.progressView.mode = MRProgressOverlayViewModeIndeterminate;
    self.progressView.titleLabelText = title;
    
    [self showIndicator];
}

- (void)showSmallBusyIndicator {
    [self showSmallBusyIndicatorWithTitle:@""];
}

- (void)showSmallBusyIndicatorWithTitle: (NSString *)title {
    
    [self quickHideIndicator];
    
    self.progressView = [MRProgressOverlayView new];
    self.progressView.mode = MRProgressOverlayViewModeIndeterminateSmall;
    self.progressView.titleLabelText = title;
    
    [self showIndicator];
}

- (void)showIndicator {
    
    self.progressView.tintColor = ApplicationMainColor;
    
    [self.view addSubview:self.progressView];
    [self.progressView show:YES];
}

- (void)hideIndicator {
    
    [self.progresViewTimer invalidate];
    
    self.progresViewTimer = nil;
    
    __weak typeof(self) this = self;

    [self.progressView dismiss:YES completion:^{
        this.progressView = nil;
    }];
}

- (void)dealloc {
#ifdef FREE
    self.adBanner.delegate = nil;
    self.adBanner = nil;
    
#endif
    
    [RLMRealm.defaultRealm removeNotification:self.notification];

    [self.progresViewTimer invalidate];
    
    self.progresViewTimer = nil;
    
    [self.progressView dismiss:NO completion:nil];
    
    self.progressView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.navigationController.delegate = nil;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)startNavigationTutorial {
    
    [self startTutorialWithInfo: NSLocalizedString(@"Swipe Right to go back", nil)
                        atPoint:CGPointMake(ScreenWidth / 2, ScreenHeight / 2 + 80)
   withFingerprintStartingPoint:CGPointMake(30, ScreenHeight / 2)
                    andEndPoint:CGPointMake(ScreenWidth / 2, ScreenHeight / 2)
           shouldHideBackground:YES];
}

- (void)startShowItemOptionsTutorial {
    
    [self startTutorialWithInfo:NSLocalizedString(@"Swipe Left to reveal options", nil)
                        atPoint:CGPointMake(ScreenWidth / 2, 250)
   withFingerprintStartingPoint:CGPointMake(ScreenWidth - 60, 30)
                    andEndPoint:CGPointMake(ScreenWidth - 200, 30)
           shouldHideBackground:NO];
}

- (void)startCreateNewItemTutorialWithInfo: (NSString *)infoText {
    
    [self startTutorialWithInfo:infoText
                        atPoint:CGPointMake(ScreenWidth / 2, 350)
   withFingerprintStartingPoint:CGPointMake(ScreenWidth / 2, 150)
                    andEndPoint:CGPointMake(ScreenWidth / 2, 300)
           shouldHideBackground:YES];
}

- (void)startTutorialWithInfo: (NSString *)infoText
                      atPoint: (CGPoint)infoPoint
 withFingerprintStartingPoint: (CGPoint)startPoint
                  andEndPoint: (CGPoint)endPoint
         shouldHideBackground: (BOOL)hideBackground {
    
    NSString *tutorialKey = [NSString stringWithFormat:@"%@_%@_tutorial_%@", NSStringFromClass ([self class]), NSStringFromSelector(_cmd), infoText];
    
    BOOL wasShown = [[NSUserDefaults standardUserDefaults] boolForKey:tutorialKey];
    
    if (wasShown) {
        return;
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:tutorialKey];
    }
    
    UIView *tutorialView = [[UIView alloc] initWithFrame:self.view.bounds];
    
    tutorialView.backgroundColor = [ApplicationMainColor colorWithAlphaComponent:hideBackground ? 1.0 : 0.2];
    tutorialView.alpha = 0.0;
    
    [self.view addSubview: tutorialView];
    
    DKCircleImageView *touchView = [[DKCircleImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    
    touchView.center = startPoint;
    
    touchView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8];
    
    [tutorialView addSubview: touchView];
    
    UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, ScreenWidth - 40, ScreenHeight / 3)];
    
    infoLabel.font = [UIFont fontWithName:ApplicationFont size:30];
    infoLabel.textColor = [UIColor whiteColor];
    infoLabel.backgroundColor = [UIColor clearColor];
    infoLabel.numberOfLines = 0;
    infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.center = infoPoint;
    infoLabel.text = infoText;
    
    [tutorialView addSubview: infoLabel];
    
    self.view.userInteractionEnabled = NO;
    
    __weak typeof(self) this = self;
    
    [UIView animateWithDuration:0.5 animations:^{
        tutorialView.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1.5 animations:^{
            touchView.center = endPoint;
            touchView.alpha = 0.3;
        } completion:^(BOOL finished) {
            
            touchView.center = startPoint;
            touchView.alpha = 1.0;
            
            [UIView animateWithDuration:1.5 animations:^{
                touchView.center = endPoint;
                touchView.alpha = 0.3;
            } completion:^(BOOL finished) {
                
                touchView.center = startPoint;
                touchView.alpha = 1.0;
                
                [UIView animateWithDuration:1.5 animations:^{
                    touchView.center = endPoint;
                    touchView.alpha = 0.0;
                    infoLabel.alpha = 0.0;
                } completion:^(BOOL finished) {
                    
                    [UIView animateWithDuration:0.5 animations:^{
                        tutorialView.alpha = 0.0;
                    } completion:^(BOOL finished) {

                        [touchView removeFromSuperview];
                        [infoLabel removeFromSuperview];
                        [tutorialView removeFromSuperview];
                        
                        [this startNavigationTutorial];
                        
                        this.view.userInteractionEnabled = YES;
                    }];
                }];
            }];
        }];
    }];
}

- (void)hideView:(UIView *)view withDelay:(NSTimeInterval)delay andDelta:(float)delta {
    void (^animation)() = ^{
        view.center = CGPointMake(ScreenWidth + delta / 2, view.center.y);
        view.alpha = 0;
    };
    
    void (^completion)(BOOL) = ^(BOOL finished) {
        view.alpha = 0;
    };
    
    [UIView animateWithDuration:DURATION
                          delay:delay
         usingSpringWithDamping:0.75
          initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseIn
                     animations:animation
                     completion:completion];
}

- (void)presentView:(UIView *)view withDelay:(NSTimeInterval)delay andDelta:(float)delta {
    view.alpha = 0;
    view.center = CGPointMake(ScreenWidth + delta / 2, view.center.y);

    void (^animation)() = ^{
        view.center = CGPointMake(ScreenWidth / 2, view.center.y);
        view.alpha = 1;
    };
    
    [UIView animateWithDuration:DURATION
                          delay:delay
         usingSpringWithDamping:0.75
          initialSpringVelocity:1
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:animation
                     completion:nil];
}


#if 0

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController*)fromVC
                                                 toViewController:(UIViewController*)toVC {
    if (operation != UINavigationControllerOperationNone) {
        return [AMWaveTransition transitionWithOperation:operation];
    }
    return nil;
}

#endif

- (NSArray*)visibleCells {
    return [self.tableView visibleCells];
}

#ifdef FREE

- (void)updateAdBannerPosition {
    
    __weak typeof(self) this = self;
    
    [UIView animateWithDuration:0.5 animations:^{
        this.adBanner.alpha = 0.0;
    } completion:^(BOOL finished) {
        this.tableView.tableFooterView = this.adBanner;
        
        [UIView animateWithDuration:0.5 animations:^{
            this.adBanner.alpha = 1.0;
        }];
    }];
}

- (void)retryGetAd {
    [self.adBanner loadRequest: self.request];
}

- (void)unlockNoAdvProduct: (NSNotification *)notification {
    if (self.tableView.tableFooterView == self.adBanner) {
        self.tableView.tableFooterView = nil;
    } else if (self.tableView.tableHeaderView == self.adBanner) {
        self.tableView.tableHeaderView = nil;
    } else {
        [self.adBanner removeFromSuperview];
    }
    
    self.adBanner.delegate = nil;
    self.adBanner = nil;
}

- (GADRequest *)createRequest {
    self.request = [GADRequest request];
    
    // Make the request for a test ad. Put in an identifier for the simulator as
    // well as any devices you want to receive test ads.
//    self.request.testDevices = @[];
//    self.request.testDevices = @[@"e33f87077b26ca5a9c75f8446d160c2e"];
    return self.request;
}

// We've received an ad successfully.
- (void)adViewDidReceiveAd:(GADBannerView *)adView {
    NSLog(@"Received ad successfully");
    
    [self updateAdBannerPosition];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
    NSLog(@"Failed to receive ad with error: %@", [error localizedFailureReason]);
    
    __weak typeof(self) this = self;
    
    int64_t delayInSeconds = 3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [this retryGetAd];
    });
}

#endif

@end
