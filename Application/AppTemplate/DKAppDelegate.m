//
//  DKAppDelegate.m
//  AppTemplate
//
//  Created by Dmitry Klimkin on 26/2/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKAppDelegate.h"
#import "DKBaseViewController.h"
#import "DKMenuViewController.h"
#import "DKNetworkManager.h"
#import "DKLoginViewController.h"
#import "DKSettingsManager.h"
#import "DKWeatherViewController.h"
#import "DKMenuViewController.h"
#import "DKMealViewController.h"
#import "DKAppColorViewController.h"
#import "DKStoreManager.h"

#import "Week.h"
#import "Day.h"

#import "ECSlidingViewController.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "NSString+MD5Addition.h"
#import "iRate.h"
#import "FRDLivelyButton.h"
#import "Flurry.h"
#import "UIColor+MLPFlatColors.h"

#import <Crashlytics/Crashlytics.h>
#import <GooglePlus/GooglePlus.h>
#import <FacebookSDK/FacebookSDK.h>

#define DKAppDelegateDefaultAppNameKey @"DKAppDelegateDefaultAppNameKey"
#define DKAppDelegateDeviceTokenKey @"DeviceTokenKey"

#ifdef TESTING

#define DKAppDelegateFlurryAppKey @"V9Z5YTXVZH5F33GGMDVR"

#else

#define DKAppDelegateFlurryAppKey @"V9Z5YTXVZH5F33GGMDVR"

#endif

#define kStoreName @"DataModel.sqlite"

@interface DKAppDelegate () <GPPDeepLinkDelegate>

@property (nonatomic, strong) NSString *defaultAppName;
@property (nonatomic, strong) NSString *deviceToken;
@property (nonatomic, strong) ECSlidingViewController *slidingViewController;
@property (nonatomic, strong) DKLoginViewController *loginViewController;
@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic, strong) NSMutableDictionary *viewControllersCache;

@property (nonatomic, strong) NSArray *locations;

@end

@implementation DKAppDelegate

@synthesize defaultAppName = _defaultAppName;
@synthesize deviceToken = _deviceToken;
@synthesize slidingViewController = _slidingViewController;
@synthesize loginViewController = _loginViewController;
@synthesize locations = _locations;
@synthesize viewControllersCache = _viewControllersCache;
@synthesize pageViewController = _pageViewController;

#if 0
+ (void)initialize
{
    //configure iRate
//    [iRate sharedInstance].appStoreID = APPSTOREID;// App Id
//    [iRate sharedInstance].applicationName = @"ThreadWeather";
//    [iRate sharedInstance].messageTitle = LIKE_THIS_APP;
//    [iRate sharedInstance].message = PLEASE_RATE_APP;
//    [iRate sharedInstance].rateButtonLabel = RATE_TXT;
//    [iRate sharedInstance].cancelButtonLabel = NO_LATER_TXT;
//    [iRate sharedInstance].remindButtonLabel = DO_LATER_TXT;
    [iRate sharedInstance].daysUntilPrompt = 1;
    [iRate sharedInstance].usesUntilPrompt = 3;
    [iRate sharedInstance].remindPeriod = 3;
}
#endif

- (NSString *)defaultAppName {
    if (_defaultAppName == nil) {
        _defaultAppName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(id)kCFBundleNameKey];

        if (_defaultAppName == nil) {
            
            _defaultAppName = [[NSUserDefaults standardUserDefaults] stringForKey:DKAppDelegateDefaultAppNameKey];
            
            if (_defaultAppName == nil) {
                self.defaultAppName = [NSString uniqueString];
            }
        }
    }
    
    return _defaultAppName;
}

- (void)setDefaultAppName:(NSString *)defaultAppName {
    _defaultAppName = defaultAppName;
    
    if (defaultAppName) {
        [[NSUserDefaults standardUserDefaults] setObject:defaultAppName forKey:DKAppDelegateDefaultAppNameKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DKAppDelegateDefaultAppNameKey];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)deviceToken {
    if (_deviceToken == nil) {
        NSString *tokenKey = [NSString stringWithFormat:@"%@%@", self.defaultAppName, DKAppDelegateDeviceTokenKey];
        
        _deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:tokenKey];
    }
    
    return _deviceToken;
}

- (void)setDeviceToken:(NSString *)deviceToken {
    _deviceToken = deviceToken;
    
    if (deviceToken) {
        [DKSettingsManager sharedInstance][kSettingsAPNSToken] = deviceToken;
    } else {
        [[DKSettingsManager sharedInstance] removeObjectForKey:kSettingsAPNSToken];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //[self initParseWithOptions:launchOptions andApp: application];
    
    if ([DKSettingsManager sharedInstance][kSettingApplicationColor] == nil) {
        [DKSettingsManager sharedInstance][kSettingApplicationColor] = [[UIColor colorWithRed:0.29 green:0.59 blue:0.81 alpha:1] hexString];
    }
    
    if ([[[UIDevice currentDevice] name] isEqualToString:@"iPhone Simulator"] == NO) {
        [Flurry startSession:DKAppDelegateFlurryAppKey];
        [Flurry logPageView];
        [Flurry setSessionContinueSeconds:600];
        [Flurry setCrashReportingEnabled:YES];
        
        [Crashlytics startWithAPIKey:@"acae1e61f9e2e9800669e34d9a16778891aae7c0"];
    }
    
    //white status bar
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

#ifdef TESTING

#if 0
    
    [[DKSettingsManager sharedInstance] removeObjectForKey:kSettingLoggedInUser];
    [[DKSettingsManager sharedInstance] removeObjectForKey:kSettingLocations];
    [[DKSettingsManager sharedInstance] removeObjectForKey:kLocalSettingsWeatherCacheKey];

#endif
    
#endif
    [GPPDeepLink setDelegate:self];
    [GPPDeepLink readDeepLinkAfterInstall];
    [FBLoginView class];
    [DKSettingsManager sharedInstance];

    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024 diskCapacity:20 * 1024 * 1024 diskPath:nil];

    [NSURLCache setSharedURLCache:URLCache];

//    [AFNetworkActivityIndicatorManager sharedManager].enabled  = YES;

    [application setMinimumBackgroundFetchInterval:60 * 60]; // 1 hour

    [self copyDefaultStoreIfNecessary];

    [MagicalRecord setShouldDeleteStoreOnModelMismatch: NO];
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:kStoreName];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
//    DKHomeViewController *homeViewController = [[DKHomeViewController alloc] init];
//    
//    FRDLivelyButton *button = [[FRDLivelyButton alloc] initWithFrame:CGRectMake(0,0,25,25)];
//    [button setOptions:@{ kFRDLivelyButtonLineWidth: @(2.0f),
//                          kFRDLivelyButtonHighlightedColor: [UIColor colorWithRed:0.5 green:0.8 blue:1.0 alpha:1.0],
//                          kFRDLivelyButtonColor: [UIColor blueColor]
//                          }];
//    
//    [button setStyle:kFRDLivelyButtonStyleHamburger animated:NO];
//    [button addTarget:self action:@selector(onMenuButtonTap) forControlEvents:UIControlEventTouchUpInside];
//    
//    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
//    homeViewController.navigationItem.rightBarButtonItem = buttonItem;
//
//    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:homeViewController];
    
    
//    _viewControllers = [NSMutableArray new];
//    _viewControllersCache = [NSMutableDictionary new];
//    
//    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:0];
//    
////    [self.pageViewController setViewControllers:_viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
//    [self.pageViewController.view setBackgroundColor:ApplicationMainColor];
//    [self.pageViewController setDelegate:self];
//    [self.pageViewController setDataSource:self];
//    
//    // THIS IS A HACK INTO THE PAGEVIEWCONTROLLER
//    // PROCEED WITH CAUTION
//    // MAY CONTAIN BUG!! (I HAVENT RAN INTO ONE YET)
//    // looking for the subview that is a scrollview so we can attach a delegate onto the view to mornitor scrolling
//    for (UIView *subview in self.pageViewController.view.subviews) {
//        if ([subview isKindOfClass:[UIScrollView class]]) {
//            UIScrollView *scrollview = (UIScrollView *) subview;
//            [scrollview setDelegate:self];
//        }
//    }
    
    DKMenuViewController *menuViewController = [[DKMenuViewController alloc] init];
        
//    menuViewController.title = NSLocalizedString(@"Fit Assistent", nil);
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:menuViewController];
    
    [navigationController interactivePopGestureRecognizer];
    
    navigationController.navigationBar.tintColor = [UIColor whiteColor];
    navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor],
                                                               NSFontAttributeName: [UIFont fontWithName:ApplicationFont size:24.0]};
    
    CGRect rect = CGRectMake(0, 0, 1, 1);
    // Create a 1 by 1 pixel context
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    
    [ApplicationMainColor setFill];
    
    UIRectFill(rect);   // Fill it with your color
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
//    [[UINavigationBar appearance] setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];

    //weird voodoo to remove navigation bar background
    [navigationController.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    [navigationController.navigationBar setShadowImage:[UIImage new]];
    
    navigationController.view.backgroundColor = ApplicationMainColor;
    navigationController.navigationBar.backgroundColor = ApplicationMainColor;
    navigationController.navigationBar.translucent = NO;
    
//    [navigationController setNavigationBarHidden:YES animated:NO];
    
    // configure sliding view controller
//    self.slidingViewController = [ECSlidingViewController slidingWithTopViewController:self.pageViewController];
//    self.slidingViewController.underLeftViewController  = nil;
//    self.slidingViewController.underRightViewController = menuViewController;
    //
    //    // enable swiping on the top view
    //    [navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    //
    // configure anchored layout
//    self.slidingViewController.anchorRightPeekAmount  = 270.0;
//    self.slidingViewController.anchorLeftRevealAmount = 270.0;

//    self.window.rootViewController = self.slidingViewController;
    
//    navigationController.navigationBar.hidden = YES;
    self.window.rootViewController = navigationController;
    
    self.window.backgroundColor = ApplicationMainColor;
    [self.window makeKeyAndVisible];
    
#ifdef FREE
    [DKStoreManager sharedInstance];
#endif

//    NSString *loggedInUser = [DKSettingsManager sharedInstance][kSettingLoggedInUser];
//        
//    if (loggedInUser.length == 0) {
//        self.loginViewController = [[DKLoginViewController alloc] init];
//        
//        [self.window.rootViewController presentViewController:self.loginViewController animated:NO completion:nil];
//        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserDidLogin:) name:kSuccessLoginNotification object:nil];
//    } else {
//        // Load previously stored locations
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self updateCurrentLocation];
//        });
//    }
    
    NSLog(@"Launched in background %d", UIApplicationStateBackground == application.applicationState);
    
    if (UIApplicationStateBackground != application.applicationState) {
        UILocalNotification *locationNotification = launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];
        
        if (locationNotification) {
            // Set icon badge number to zero
            application.applicationIconBadgeNumber = 0;

            [self addNewMeal];
        }
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onColorDidChange) name:kAppColorDidChangeNotification object:nil];

    // Override point for customization after application launch.
    return YES;
}

- (void)onColorDidChange {
    
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    
    CGRect rect = CGRectMake(0, 0, 1, 1);
    // Create a 1 by 1 pixel context
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    
    [ApplicationMainColor setFill];
    
    UIRectFill(rect);   // Fill it with your color
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //    [[UINavigationBar appearance] setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    
    //weird voodoo to remove navigation bar background
    [navigationController.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    
    navigationController.view.backgroundColor = ApplicationMainColor;
    navigationController.navigationBar.backgroundColor = ApplicationMainColor;

    self.window.backgroundColor = ApplicationMainColor;
}

- (void) copyDefaultStoreIfNecessary {
	NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSURL *storeURL = [NSPersistentStore MR_urlForStoreName:kStoreName];
    
	// If the expected store doesn't exist, copy the default store.
	if (![fileManager fileExistsAtPath:[storeURL path]]) {
		NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:[kStoreName stringByDeletingPathExtension]
                                                                     ofType:[kStoreName pathExtension]];
        
		if (defaultStorePath) {
            NSError *error;
            
			BOOL success = [fileManager copyItemAtPath:defaultStorePath toPath:[storeURL path] error:&error];
            
            if (!success) {
                NSLog(@"Failed to install default store");
            }
		}
	}
}

- (void)addNewMeal {
    
    return;
    
    __weak typeof(self) this = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        
        NSArray *weeks = [Week MR_findAllSortedBy:@"seqNumber" ascending:NO];
        NSPredicate *weekFilter = [NSPredicate predicateWithFormat:@"week = %@", weeks.firstObject];
        NSArray *days = [Day MR_findAllSortedBy:@"seqNumber" ascending:NO withPredicate:weekFilter];

        dispatch_async(dispatch_get_main_queue(), ^{
            DKMealViewController *mealController = [[DKMealViewController alloc] initWithDay:days.firstObject canAddNewDay:YES];
            
            UINavigationController *rootNavigationController = (UINavigationController *)this.window.rootViewController;
            
            if ([this.window.rootViewController isKindOfClass:[UINavigationController class]]) {
                [rootNavigationController pushViewController:mealController animated:YES];
            }
        });
    });
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    // TODO: Open corresponding week->day->meals and trigger +
    
    // Set icon badge number to zero
    application.applicationIconBadgeNumber = 0;
    
    [self addNewMeal];
}

- (void)onMenuDidDeleteLocation: (NSNotification *)notification {
    
    NSDictionary *deletedLocation = notification.object;
    NSMutableArray *locations = [[DKSettingsManager sharedInstance][kSettingLocations] mutableCopy];
    
    if (locations == nil) {
        locations = [NSMutableArray new];
    }
    
    for (NSDictionary *existingLocation in locations) {
        if ([existingLocation[kLocationFieldTitle] isEqualToString:deletedLocation[kLocationFieldTitle]]) {

            [locations removeObject:existingLocation];
            
            if ([existingLocation[kLocationFieldTitle] isEqualToString:[DKSettingsManager sharedInstance][kSettingLastLocation]]) {
                [[DKSettingsManager sharedInstance] removeObjectForKey:kSettingLastLocation];
            }
            
            break;
        }
    }
    
    [DKSettingsManager sharedInstance][kSettingLocations] = locations;
    
    self.locations = locations;
}

- (void)updateCurrentLocation {
    
    return;
    
    __weak typeof(self) this = self;

    [[DKSettingsManager sharedInstance] detectCurrentLocation:^(CLPlacemark *placemark) {
        
        if (placemark == nil) {
            // TODO: Navigate user to the location picker menu. Block everything else.
            [this addNewLocation: nil];
            
        } else {
            CLLocationCoordinate2D coordinate = placemark.location.coordinate;
            
            //            NSString *addresstext = [NSString stringWithFormat:@"%@ %@ %@ %@ %@",
            //                                         placemark.thoroughfare,
            //                                         placemark.postalCode, placemark.locality,
            //                                         placemark.administrativeArea,
            //                                         placemark.country];
            
            NSString *adminCode1 = placemark.administrativeArea;
            
            if (adminCode1.length == 0) {
                adminCode1 = placemark.country;
            }
            
            NSString *addresstext = [NSString stringWithFormat:@"%@ %@", placemark.locality, adminCode1];
            
            NSDictionary *location = @{kLocationFieldTitle    : placemark.locality,
                                       kLocationFieldLocation : addresstext,
                                       kLocationFieldLatitude : @(coordinate.latitude),
                                       kLocationFieldLongitude: @(coordinate.longitude)};
            [this addNewLocation: location];

            [DKSettingsManager sharedInstance][kSettingLastLocation] = location[kLocationFieldTitle];
            [[NSNotificationCenter defaultCenter] postNotificationName:kSwitchLocation object:location];
        }
        
        [this.loginViewController dismissViewControllerAnimated:YES completion:^{
            this.loginViewController = nil;
            
            [this registerForRemoteNotificationsWithAPNS];
        }];
    }];
}

- (void)onUserDidLogin: (NSNotification *)notification {
    [self.loginViewController showBigBusyIndicatorWithTitle:NSLocalizedString(@"Discovering location...", nil)];
    [self updateCurrentLocation];
}

- (void)addNewLocation: (NSDictionary *)location {
    
    NSMutableArray *locations = [[DKSettingsManager sharedInstance][kSettingLocations] mutableCopy];

    if (locations == nil) {
        locations = [NSMutableArray new];
    }
    
    BOOL isLocationExists = NO;
    
    for (NSDictionary *existingLocation in locations) {
        if ([existingLocation[kLocationFieldTitle] isEqualToString:location[kLocationFieldTitle]]) {
            isLocationExists = YES;
            break;
        }
    }
    
    if (location && (isLocationExists == NO)) {
        [locations insertObject:location atIndex:0];
        
        [DKSettingsManager sharedInstance][kSettingLastLocation] = location[kLocationFieldTitle];
        
        [Flurry logEvent:@"Added new location"];

        [DKSettingsManager sharedInstance][kSettingLocations] = locations;
    }
    
    self.locations = locations;
}

- (void)setLocations:(NSArray *)locations {
    _locations = locations;    
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    BOOL handledByGooglePlus = ([GPPURLHandler handleURL:url sourceApplication:sourceApplication annotation:annotation]);
    BOOL handledByFacebook = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    BOOL handledByApp = ([self application: application handleOpenURL: url]);
    
    return handledByApp || handledByGooglePlus || handledByFacebook;
}

- (void)didReceiveDeepLink:(GPPDeepLink *)deepLink {
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return NO;
}
							
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//    [[NSNotificationCenter defaultCenter] postNotificationName:kNeedUpdateLocationAndWeather object:nil userInfo:nil];
//    [[DKFacebookManager sharedInstance] resumeSession];
    
    // Clear badge and update installation, required for auto-incrementing badges.
    if (application.applicationIconBadgeNumber != 0) {
        application.applicationIconBadgeNumber = 0;
    }
    
    // Clears out all notifications from Notification Center.
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    application.applicationIconBadgeNumber = 1;
    application.applicationIconBadgeNumber = 0;
    
    NSString *loggedInUser = [DKSettingsManager sharedInstance][kSettingLoggedInUser];
    
    if (loggedInUser.length > 0) {
        [self updateCurrentLocation];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void) unregisterFromNotifications {

    self.deviceToken = nil;
    
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void) registerForRemoteNotificationsWithAPNS {
    
    if ([[[UIDevice currentDevice] name] isEqualToString:@"iPhone Simulator"] == YES) {
        return;
    }
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:( UIRemoteNotificationTypeAlert|
                                                                            UIRemoteNotificationTypeBadge|
                                                                            UIRemoteNotificationTypeSound )];
}

- (void) unregisterForRemoteNotificationsFromAPNS {
    
    if ([[[UIDevice currentDevice] name] isEqualToString:@"iPhone Simulator"] == YES) {
        return;
    }
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
}

- (void)registerForRemoteNotifications:(BOOL)useCachedToken {
    
    if (useCachedToken && self.deviceToken) {
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert |
                                                                               UIRemoteNotificationTypeBadge |
                                                                               UIRemoteNotificationTypeSound)];
    }
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	
    NSString *notificationToken = [NSString stringWithFormat:@"%@", deviceToken];
    
    notificationToken = [notificationToken stringByReplacingOccurrencesOfString:@">" withString:@""];
    notificationToken = [notificationToken stringByReplacingOccurrencesOfString:@"<" withString:@""];
    notificationToken = [notificationToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (notificationToken.length > 0) {
        self.deviceToken = notificationToken;
    }    
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {

    [self updateCurrentLocation];

//    if (/** NEW DATA EXISTS AND WAS SUCCESSFULLY PROCESSED **/) {
//        completionHandler(UIBackgroundFetchResultNewData);
//    }
//    
//    if (/** NO NEW DATA EXISTS **/) {
//        completionHandler(UIBackgroundFetchResultNoData);
//    }
//    
//    if (/** ANY ERROR OCCURS **/) {
//        completionHandler(UIBackgroundFetchResultFailed);
//    }
    
//    [[DKFeedSyncManager sharedInstance] synchronize];
//    
//
//    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
//    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
//
//    NSURL *url = [[NSURL alloc] initWithString:@"http://yourserver.com/data.json"];
//    NSURLSessionDataTask *task = [session dataTaskWithURL:url
//                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//
//                                            if (error) {
//                                                completionHandler(UIBackgroundFetchResultFailed);
//                                                return;
//                                            }
//
//                                            // Разбор response/data и определить, было ли новое содержание доступно
//                                            BOOL hasNewData = ...
//                                            if (hasNewData) {
//                                                completionHandler(UIBackgroundFetchResultNewData);
//                                            } else {
//                                                completionHandler(UIBackgroundFetchResultNoData);
//                                            }
//                                        }];
//    
//    // Запустите задачу
//    [task resume];
}

@end
