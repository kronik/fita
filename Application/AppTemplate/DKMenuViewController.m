//
//  DKMenuViewController.m
//  AppTemplate
//
//  Created by Dmitry Klimkin on 26/2/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKMenuViewController.h"
#import "DKSettingsManager.h"
#import "DKTableViewCell.h"
#import "DKSettingsViewController.h"
#import "DKWeeksViewController.h"
#import "DKWorkoutMenuViewController.h"
#import "DKMenuCell.h"
#import "DKTimerViewController.h"
#import "Day.h"
#import "DKMealViewController.h"

#import "NIKFontAwesomeIconFactory.h"
#import "NIKFontAwesomeIconFactory+iOS.h"
#import "Flurry.h"
#import "FXBlurView.h"

#define DKMenuViewControllerCellId @"DKMenuViewControllerCellId"
#define DKApplicationName [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)@"CFBundleDisplayName"];

@interface DKMenuViewController () <UITableViewDataSource, UITableViewDelegate> {
    NSArray *menuItems;
}

@property (nonatomic, strong) NSMutableArray *weeks;
@property (nonatomic, strong) DKWeeksViewController *weeksController;
@property (nonatomic, strong) UIImageView *backgroundAnimationView;

@end

@implementation DKMenuViewController

@synthesize weeks = _weeks;
@synthesize weeksController = _weeksController;
@synthesize backgroundAnimationView = _backgroundAnimationView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    NSString *launchImage = @"LaunchImage-700";
//    
//    if  ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) &&
//         (ScreenHeight > 480.0f)) {
//        launchImage = @"LaunchImage-700-568h";
//    } else {
//        launchImage = @"LaunchImage-700";
//    }
//    
//    self.backgroundAnimationView = [[UIImageView alloc] initWithFrame:self.view.bounds];
//    self.backgroundAnimationView.image = [UIImage imageNamed:launchImage];
//    [self.view addSubview: self.backgroundAnimationView];    

    menuItems = @[NSLocalizedString(@"Diary", nil),
                  NSLocalizedString(@"Today", nil),
                  NSLocalizedString(@"Timer", nil),
//                  NSLocalizedString(@"Workouts", nil),
                  NSLocalizedString(@"Settings", nil)];
    
    float headerSize = (ScreenHeight - menuItems.count * 130) / 2;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, headerSize)];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = ApplicationMainColor;
    self.tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    
    [self.view addSubview: self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    self.title = @"";

    [self.tableView reloadData];
    
    __weak typeof(self) this = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        this.weeks = [[Week MR_findAllSortedBy:@"seqNumber" ascending:NO] mutableCopy];
        
        this.weeksController = [[DKWeeksViewController alloc] initWithWeeks:this.weeks];
    });
    
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:0.5 delay:0.5 options:UIViewAnimationOptionCurveEaseIn  animations:^{
        
        if (ScreenHeight > 480.0f) {
            self.backgroundAnimationView.center = CGPointMake(ScreenWidth / 2, (ScreenHeight / 2) - (ScreenHeight / 4));
        } else {
            self.backgroundAnimationView.center = CGPointMake(ScreenWidth / 2, (ScreenHeight / 2) - (ScreenHeight / 10));
        }
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.title = NSLocalizedString(@"FitA", nil);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DKMenuCell *cell = [self.tableView dequeueReusableCellWithIdentifier:DKMenuViewControllerCellId];
    
    if (cell == nil) {
        cell = [[DKMenuCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DKMenuViewControllerCellId];
        
        cell.userInteractionEnabled = YES;
        cell.selectedBackgroundView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont fontWithName:ApplicationUltraLightFont size:50];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.numberOfLines = 1;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.textAlignment = NSTextAlignmentRight;
        
        cell.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.textLabel.backgroundColor = [UIColor clearColor];
    }
    
    NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory generalFactory];
    
    factory.colors = @[[UIColor whiteColor]];
    factory.size = 40;
    
    UIImage *menuImage = nil;
    
    switch (indexPath.row) {
        case 0:
            menuImage = [factory createImageForIcon:NIKFontAwesomeIconPencil];
            break;
        case 1:
            menuImage = [factory createImageForIcon:NIKFontAwesomeIconCoffee];
            break;
        case 2:
            menuImage = [factory createImageForIcon:NIKFontAwesomeIconTime];
//            menuImage = [factory createImageForIcon:NIKFontAwesomeIconHeartEmpty];
            break;
        case 3:
            menuImage = [factory createImageForIcon:NIKFontAwesomeIconCogs];
            break;
            
        default:
            break;
    }
    
    cell.imageView.image = menuImage;
    cell.textLabel.text = menuItems[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0: {
            [Flurry logEvent:@"Open weeks"];
            [self.navigationController pushViewController:self.weeksController animated:YES];
        }
            break;
        case 1: {
            [Flurry logEvent:@"Open current day"];

            Day *day = nil;
            
            if (self.weeks.count == 0) {
                
                Week *newWeek = [Week MR_createEntity];
                
                newWeek.seqNumber = @(1);
                newWeek.startDate = [NSDate date];

                Day *newDay = [Day MR_createEntity];
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                
                [dateFormatter setDateFormat:@"EEEE"];
                
                NSDate *nextDate = [NSDate date];
                
                newDay.name = [dateFormatter stringFromDate:[NSDate date]];
                
                newDay.week = newWeek;
                newDay.date = nextDate;
                newDay.seqNumber = @(0);

                day = newDay;
                
                [newWeek addDaysObject:newDay];
                
                [self.weeks insertObject:newDay atIndex:0];
                
                [self saveChangesAsyncWithBlock:^(BOOL isFailedToSave) {
                }];
            } else {
                Week *currentWeek = self.weeks.firstObject;
                
                NSArray *days = [[currentWeek.days allObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    
                    Day *day1 = (Day *)obj1;
                    Day *day2 = (Day *)obj2;
                    
                    NSComparisonResult result = [day1.seqNumber compare:day2.seqNumber];
                    
                    if (result == NSOrderedAscending) {
                        return NSOrderedDescending;
                    } else if (result == NSOrderedDescending) {
                        return NSOrderedAscending;
                    } else {
                        return NSOrderedSame;
                    }
                }];
                
                day = days.firstObject;
                
                if (day == nil) {
                    Day *newDay = [Day MR_createEntity];
                    
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    
                    [dateFormatter setDateFormat:@"EEEE"];
                    
                    NSDate *nextDate = [NSDate date];
                    
                    newDay.name = [dateFormatter stringFromDate:[NSDate date]];
                    
                    newDay.week = currentWeek;
                    newDay.date = nextDate;
                    newDay.seqNumber = @(0);
                    
                    day = newDay;
                    
                    [currentWeek addDaysObject:newDay];
                }
            }
            
            DKMealViewController *mealController = [[DKMealViewController alloc] initWithDay:day canAddNewDay:YES];
            
            mealController.title = day.name;
            
            [self.navigationController pushViewController:mealController animated:YES];
        }
            break;
            
        case 2: {
            [Flurry logEvent:@"Open timer"];
            
            DKTimerViewController *viewController = [DKTimerViewController new];
            
            viewController.title = menuItems[indexPath.row];
            
            [self.navigationController pushViewController:viewController animated:YES];

//            [Flurry logEvent:@"Open workouts"];
//            [self.navigationController pushViewController:[DKWorkoutMenuViewController new] animated:YES];
        }
            break;
        case 3: {
            [self openSettings];
        }
        default:
            break;
    }
}

- (void)openTimer {
    
}

- (void)openSettings {
    DKSettingsViewController *settingsController = [[DKSettingsViewController alloc] init];
    
    [self.navigationController pushViewController:settingsController animated:YES];
    
    [Flurry logEvent:@"Open settings"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#ifdef FREE

- (void)updateAdBannerPosition {
    
    self.tableView.tableFooterView = [UIView new];
    
    [self.adBanner removeFromSuperview];
    
    __weak typeof(self) this = self;
    
    [UIView animateWithDuration:0.5 animations:^{
        this.adBanner.alpha = 0.0;
    } completion:^(BOOL finished) {
        this.adBanner.center = CGPointMake(ScreenWidth / 2, this.view.frame.size.height - this.adBanner.frame.size.height / 2);
        [this.view addSubview:this.adBanner];
        
        [UIView animateWithDuration:0.5 animations:^{
            this.adBanner.alpha = 1.0;
        }];
    }];
}
#endif

@end
