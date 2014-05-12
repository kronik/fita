//
//  DKGlassScrollViewController.m
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 26/2/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKWeatherViewController.h"
#import "DKWeatherCondition.h"
#import "DKSettingsManager.h"
#import "MRActivityIndicatorView.h"
#import "UITextView+DisableCopyPaste.h"
#import "APTimeZones.h"

@interface DKWeatherViewController ()

@property (nonatomic) float latitude;
@property (nonatomic) float longitude;

@property (nonatomic, strong) DKWeatherCondition *currentCondition;
@property (nonatomic, strong) NSArray *weatherConditions;
@property (nonatomic, strong) NSArray *weatherDailyConditions;
@property (nonatomic, strong) UIImageView *placeHolderView;
@property (nonatomic, strong) NSDictionary *conditionsToImageMap;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UILabel *degreesLabel;
@property (nonatomic, strong) UITextView *infoLabel;
@property (nonatomic, strong) MRActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) NSTimeZone *timeZone;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation DKWeatherViewController

@synthesize longitude = _longitude;
@synthesize latitude = _latitude;
@synthesize currentCondition = _currentCondition;
@synthesize weatherConditions = _weatherConditions;
@synthesize placeHolderView = _placeHolderView;
@synthesize conditionsToImageMap = _conditionsToImageMap;
@synthesize degreesLabel = _degreesLabel;
@synthesize refreshControl = _refreshControl;
@synthesize infoLabel = _infoLabel;
@synthesize activityIndicatorView = _activityIndicatorView;
@synthesize weatherDailyConditions = _weatherDailyConditions;
@synthesize timeZone = _timeZone;
@synthesize timer = _timer;

- (id)initWithLatitude: (double)latitude
          andLongitude: (double)longitude {
 
    self = [super init];
    
    if (self) {
        _latitude = latitude;
        _longitude = longitude;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //white status bar
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
//    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    [self setNeedsStatusBarAppearanceUpdate];

    //preventing weird inset
    [self setAutomaticallyAdjustsScrollViewInsets:NO];

    //background
    self.view.backgroundColor = ApplicationMainColor;
    
    self.activityIndicatorView = [MRActivityIndicatorView new];
    
    self.activityIndicatorView.frame = CGRectMake(0, 0, 25, 25);
    self.activityIndicatorView.tintColor = [UIColor whiteColor];
    
    [self buildWeatherUI];
    [self reBuildWeatherUI: NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMenuDidSelectLocation:) name:kMenuDidSelectLocation object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMenuDidDeleteLocation:) name:kMenuDidDeleteLocation object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMenuDidAddLocation:) name:kMenuDidAddLocation object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMenuDidSelectLocation:) name:kSwitchLocation object:nil];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
}

- (void)dealloc {
    [_timer invalidate];
    _timer = nil;
}

- (void)onMenuDidSelectLocation: (NSNotification *)notification {
    NSDictionary *location = notification.object;
    
    float newLatitude = [location[kLocationFieldLatitude] floatValue];
    float newLongitude = [location[kLocationFieldLongitude] floatValue];
    
    if ((newLatitude != _latitude) && (newLongitude != _longitude)) {
        _latitude = newLatitude;
        _longitude = newLongitude;
        
        self.title = location[kLocationFieldTitle];
        
        [self reBuildWeatherUI: NO];
    }
}

- (void)onMenuDidAddLocation: (NSNotification *)notification {
    NSDictionary *location = notification.object;
    
    _latitude = [location[kLocationFieldLatitude] floatValue];
    _longitude = [location[kLocationFieldLongitude] floatValue];
    
    self.title = location[kLocationFieldTitle];
    
    [self reBuildWeatherUI: NO];
}

- (void)onMenuDidDeleteLocation: (NSNotification *)notification {

}

- (BOOL)is24HoursFormat {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    NSRange amRange = [dateString rangeOfString:[formatter AMSymbol]];
    NSRange pmRange = [dateString rangeOfString:[formatter PMSymbol]];
    
    BOOL is24h = (amRange.location == NSNotFound && pmRange.location == NSNotFound);
    
    return is24h;
}

- (void)updateTime {
    if (_timeZone == nil) {
        _timeZone = [NSTimeZone localTimeZone];
    }
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    
//    NSLocale *indianEnglishLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_IN"];
//
//    [df setLocale:indianEnglishLocale];
    [df setLocale:[NSLocale currentLocale]];
    [df setTimeZone:self.timeZone];
    [df setDateStyle:NSDateFormatterNoStyle];
    [df setTimeStyle:NSDateFormatterShortStyle];
    
    if ([self is24HoursFormat]) {
        [df setDateFormat:@"HH:mm"];
    } else {
        [df setDateFormat:@"hh:mm a"];
    }
    
    NSDictionary *abbreviations = [NSTimeZone abbreviationDictionary];
    NSString *timeZoneName = @"";
    
    for (NSString *key in abbreviations) {
        if ([abbreviations[key] isEqualToString:self.timeZone.name]) {
            timeZoneName = key;
            break;
        }
    }
    
    if (timeZoneName.length == 0) {
        timeZoneName = self.timeZone.abbreviation;
    }
    
//    self.subtitle = [NSString stringWithFormat:@"%@ %@", [df stringFromDate:[NSDate date]], timeZoneName];
}

- (void)updateWeatherImages {
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:_latitude longitude:_longitude];
    
    self.timeZone = [[APTimeZones sharedInstance] timeZoneWithLocation:location];

    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    
    [df setTimeZone: self.timeZone];
    [df setDateFormat:@"HH"];
    
    NSString *date = [df stringFromDate:[NSDate date]];
    int hours = [date intValue];
    
    BOOL isDay = (hours > 7) && (hours < 19);
    
    [self updateTime];
    
    self.conditionsToImageMap = @{@"clear-day"  : @"01d",
                                  @"clear-night": @"01n",
                                  @"rain": isDay ? @"09d" : @"09n",
                                  @"snow": isDay ? @"13d" : @"13n",
                                  @"sleet": isDay ? @"sleet-d" : @"sleet-n",
                                  @"wind": isDay ? @"windd" : @"windn",
                                  @"fog": isDay ? @"fogd" : @"fogn",
                                  @"cloudy": isDay ? @"03d" : @"03n",
                                  @"partly-cloudy-day": @"04d",
                                  @"partly-cloudy-night": @"04n",
                                  @"hail": isDay ? @"hail-d" : @"hail-n",
                                  @"thunderstorm": isDay ? @"thunderstorm-d" : @"thunderstorm-n",
                                  @"tornado": isDay ? @"tornadod" : @"tornadon"};
}

- (UIRefreshControl *)refreshControl {
    if (_refreshControl == nil) {
        _refreshControl = [[UIRefreshControl alloc] init];
        
        _refreshControl.tintColor = [UIColor whiteColor];
        
        [_refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
        
        [_refreshControl endRefreshing];

    }
    
    return _refreshControl;
}

- (void)reBuildWeatherUI: (BOOL)forceReload  {
    
    [self updateWeatherImages];
    
    if (ABS(_longitude) > 0.0 || ABS(_latitude) > 0.0) {
        [self loadWeatherForecast: forceReload];
        [self loadFashionSuggestions];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIImage *)imageByCropping:(UIImage *)image {
    
    CGFloat multiplier = [[UIScreen mainScreen] scale];
    CGRect cropRect = CGRectMake(0, 0, ScreenWidth * multiplier, ScreenHeight * multiplier);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef scale:[[UIScreen mainScreen] scale] orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);
    
    return cropped;
}

- (void)buildWeatherUI {
    
    UIImage *image = self.placeHolderView.image;
    
    if (self.conditionsToImageMap[self.currentCondition.icon]) {
        image = [self imageByCropping:[UIImage imageNamed: self.conditionsToImageMap[self.currentCondition.icon]]];
    }
    
    if (image == nil) {
        NSString *launchImage = @"LaunchImage-700";
        
        if  ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) &&
             (ScreenHeight > 480.0f)) {
            launchImage = @"LaunchImage-700-568h";
        } else {
            launchImage = @"LaunchImage-700";
        }

        image = [UIImage imageNamed:launchImage];
    }
    
    if (_glassScrollView == nil) {
        _glassScrollView = [[BTGlassScrollView alloc] initWithFrame:self.view.bounds
                                                    BackgroundImage:image
                                                       blurredImage:nil
                                             viewDistanceFromBottom:120
                                                     foregroundView:[self customView]];
        [self.view addSubview:_glassScrollView];
        
        [_glassScrollView.foregroundScrollView addSubview:self.refreshControl];
    
        [self.placeHolderView removeFromSuperview];
        self.placeHolderView = nil;
    } else {
        [_glassScrollView setBackgroundImage:image overWriteBlur:YES animated:YES duration:0.5];
    }
    
    [self updateWeatherTemperature:self.currentCondition.temperature andDescription:[self.currentCondition description]];
}

- (void)handleRefresh:(UIRefreshControl *)refresh {

    if (ABS(_longitude) > 0.0 || ABS(_latitude) > 0.0) {
        
        [self loadWeatherForecast: YES];
        [self loadFashionSuggestions];
    }
}

- (void)handleEndRefresh {
    [self.refreshControl endRefreshing];
    [self.activityIndicatorView stopAnimating];

    self.navigationItem.leftBarButtonItem = nil;
}

- (void)loadFashionSuggestions {
    
}

- (void)loadWeatherForecast: (BOOL)forceReload {
    
    __weak typeof(self) this = self;
    
    if (forceReload == NO) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicatorView];
        [self.activityIndicatorView startAnimating];
    }
    
//    if (self.refreshControl.isRefreshing == NO) {
//        [self.refreshControl beginRefreshing];
//    }
    
    [[DKWeatherManager sharedInstance] currentForecastForLatitude:self.latitude andLongitude:self.longitude forceReload:forceReload
                                                 withSuccessBlock:^(DKWeatherCondition *currentWeather, NSArray *hourlyForecast,
                                                                    NSArray *dailyForecast, BOOL finished) {
                                                     
                                                     this.currentCondition = currentWeather;
                                                     this.weatherConditions = hourlyForecast;
                                                     this.weatherDailyConditions = dailyForecast;
                                                     
                                                     [this buildWeatherUI];
                                                     
                                                     if (finished) {
                                                         [this handleEndRefresh];
                                                     }

                                                 } andErrorBlock:^(NSError *error) {

                                                     [this handleEndRefresh];
                                                     
                                                     NSString *message = NSLocalizedString(@"Weather forecast is temporarily unavailable", nil);
                                                     UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"FitA"
                                                                                                         message:message
                                                                                                        delegate:nil
                                                                                               cancelButtonTitle:@"OK"
                                                                                               otherButtonTitles: nil];
                                                     [alertView show];
                                                     
                                                     NSLog(@"Weather fetch error: %@", error.description);
                                                 }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    [self.degreesLabel setStartNumber:0 endNumber:((int)self.currentCondition.temperature) countDownHandeler:^(CXCountDownLabel *label, NSInteger currentNumber, BOOL stopped) {
//    }];
//    
//    [self.degreesLabel start];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController.navigationBar setBarTintColor:[UIColor clearColor]];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    //reset offset when rotate
    [_glassScrollView scrollVerticallyToOffset:-_glassScrollView.foregroundScrollView.contentInset.top];

}

- (void)viewWillLayoutSubviews {
    [_glassScrollView setTopLayoutGuideLength:[self.topLayoutGuide length]];
}

- (UIView *)customView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 520)];
    
    self.degreesLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, ScreenWidth - 10, 120)];
    
    [self.degreesLabel setTextColor:[UIColor whiteColor]];
    [self.degreesLabel setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:120]];
    [self.degreesLabel setShadowColor:[UIColor blackColor]];
    [self.degreesLabel setAlpha:0];
    [self.degreesLabel setShadowOffset:CGSizeMake(0, 0)];
    [self.degreesLabel setText:[NSString stringWithFormat:@"%.0f%@", self.currentCondition.temperature, self.currentCondition.weatherSymbol]];
    
    [view addSubview:self.degreesLabel];
    
//    self.degreesLabel.countInterval = 1;
//    self.degreesLabel.numberFormatter.numberStyle = NSNumberFormatterNoStyle;
//    self.degreesLabel.countDownTimer.frameInterval = 10;
//    self.degreesLabel.startNumber = 0;
//
//    [self.degreesLabel.numberFormatter setPositiveSuffix:self.currentCondition.weatherSymbol];
//    [self.degreesLabel.numberFormatter setNegativeSuffix:self.currentCondition.weatherSymbol];
    
    UIView *box1 = [[UIView alloc] initWithFrame:CGRectMake(5, 140, ScreenWidth - 10, 380)];
    
    box1.layer.cornerRadius = 3;
    box1.backgroundColor = [UIColor colorWithWhite:0 alpha:.0];
    
    [view addSubview:box1];
    
    self.infoLabel = [[UITextView alloc] initWithFrame:CGRectMake(5, 5, box1.frame.size.width - 10, box1.frame.size.height - 10)];

    self.infoLabel.textColor = [UIColor whiteColor];
    self.infoLabel.font = [UIFont fontWithName:ApplicationFont size:20];
    self.infoLabel.backgroundColor = [UIColor clearColor];
    self.infoLabel.textAlignment = NSTextAlignmentLeft;
    self.infoLabel.editable = NO;
    self.infoLabel.scrollEnabled = NO;
    
    [box1 addSubview:self.infoLabel];
    
    UIButton *linkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    linkButton.titleLabel.font = [UIFont systemFontOfSize:10];
    linkButton.frame = CGRectMake(0, self.infoLabel.frame.origin.y + self.infoLabel.frame.size.height - 10, ScreenWidth, 10);
    
    [linkButton setTitle:@"Powered by Forecast" forState:UIControlStateNormal];
    [linkButton setTitle:@"Powered by Forecast" forState:UIControlStateSelected];
    [linkButton setTitle:@"Powered by Forecast" forState:UIControlStateHighlighted];
    
    [linkButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [linkButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [linkButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    
    [linkButton addTarget:self action:@selector(openForecastURL) forControlEvents:UIControlEventTouchUpInside];

    [box1 addSubview:linkButton];
    
    return view;
}

- (void)openForecastURL {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://forecast.io/"]];
}

- (void)updateWeatherTemperature: (float)temperature andDescription: (NSString *)description {
    
    self.infoLabel.text = description;
    [self.degreesLabel setText:[NSString stringWithFormat:@"%.0f%@", temperature, self.currentCondition.weatherSymbol ? : @""]];

//    [self.degreesLabel setText:[NSString stringWithFormat:@"0%@", self.currentCondition.weatherSymbol]];
//    
    __weak typeof(self) this = self;
    
    [UIView animateWithDuration:1 delay:0.5 options:UIViewAnimationOptionCurveLinear animations:^{
        this.degreesLabel.alpha = 1.0;
    } completion:^(BOOL finished) {
    }];
//        int degrees = ((int)temperature);
//        
//        if (degrees != this.degreesLabel.startNumber) {
//            [this.degreesLabel setStartNumber:this.degreesLabel.startNumber endNumber:degrees
//                            countDownHandeler:^(CXCountDownLabel *label, NSInteger currentNumber, BOOL stopped) {
//                            }];
//        }
//        
//        [this.degreesLabel start];
//    }];
}

@end
