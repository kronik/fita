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
#import "DKSettingsManager.h"
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
#import <FacebookSDK/FacebookSDK.h>

#define DKAppDelegateDefaultAppNameKey @"DKAppDelegateDefaultAppNameKey"
#define DKAppDelegateDeviceTokenKey @"DeviceTokenKey"

#ifdef TESTING

#define DKAppDelegateFlurryAppKey @"V9Z5YTXVZH5F33GGMDVR"

#else

#define DKAppDelegateFlurryAppKey @"V9Z5YTXVZH5F33GGMDVR"

#endif

#define kStoreName @"DataModel.sqlite"

@interface DKAppDelegate ()

@property (nonatomic, strong) NSString *defaultAppName;
@property (nonatomic, strong) NSString *deviceToken;
@property (nonatomic, strong) ECSlidingViewController *slidingViewController;
@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic, strong) NSMutableDictionary *viewControllersCache;

@property (nonatomic, strong) NSArray *locations;

@end

@implementation DKAppDelegate

@synthesize defaultAppName = _defaultAppName;
@synthesize deviceToken = _deviceToken;
@synthesize slidingViewController = _slidingViewController;
@synthesize viewControllersCache = _viewControllersCache;
@synthesize pageViewController = _pageViewController;

#if 0
+ (void)initialize
{
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
    [FBLoginView class];
    [DKSettingsManager sharedInstance];

    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024 diskCapacity:20 * 1024 * 1024 diskPath:nil];

    [NSURLCache setSharedURLCache:URLCache];

    [application setMinimumBackgroundFetchInterval:60 * 60]; // 1 hour

    [self copyDefaultStoreIfNecessary];

    [MagicalRecord setShouldDeleteStoreOnModelMismatch: NO];
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:kStoreName];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    DKMenuViewController *menuViewController = [[DKMenuViewController alloc] init];
    
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
    
    //weird voodoo to remove navigation bar background
    [navigationController.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    [navigationController.navigationBar setShadowImage:[UIImage new]];
    
    navigationController.view.backgroundColor = ApplicationMainColor;
    navigationController.navigationBar.backgroundColor = ApplicationMainColor;
    navigationController.navigationBar.translucent = NO;
    
    self.window.rootViewController = navigationController;
    
    self.window.backgroundColor = ApplicationMainColor;
    [self.window makeKeyAndVisible];
    
#ifdef FREE
    [DKStoreManager sharedInstance];
#endif
    
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

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    BOOL handledByFacebook = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    BOOL handledByApp = ([self application: application handleOpenURL: url]);
    
    return handledByApp || handledByFacebook;
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
    
    // Clear badge and update installation, required for auto-incrementing badges.
    if (application.applicationIconBadgeNumber != 0) {
        application.applicationIconBadgeNumber = 0;
    }
    
    // Clears out all notifications from Notification Center.
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    application.applicationIconBadgeNumber = 1;
    application.applicationIconBadgeNumber = 0;
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
