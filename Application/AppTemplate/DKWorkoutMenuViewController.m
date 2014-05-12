//
//  DKWorkoutMenuViewController.m
//  AppTemplate
//
//  Created by Dmitry Klimkin on 26/2/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKWorkoutMenuViewController.h"
#import "DKSettingsManager.h"
#import "DKTableViewCell.h"
#import "DKSettingsViewController.h"
#import "DKWeeksViewController.h"
#import "DKMenuCell.h"
#import "DKTimerViewController.h"
#import "DKScheduleViewController.h"
#import "Workout.h"

#import "NIKFontAwesomeIconFactory.h"
#import "NIKFontAwesomeIconFactory+iOS.h"
#import "Flurry.h"
#import "FXBlurView.h"

#define DKWorkoutMenuViewControllerCellId @"DKWorkoutMenuViewControllerCellId"

@interface DKWorkoutMenuViewController () <UITableViewDataSource, UITableViewDelegate> {
    NSArray *menuItems;
}

@property (nonatomic, strong) NSArray *workouts;
@property (nonatomic, strong) DKScheduleViewController *workoutsController;

@end

@implementation DKWorkoutMenuViewController

@synthesize workouts = _workouts;
@synthesize workoutsController = _workoutsController;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Workouts", nil);
    
    menuItems = @[NSLocalizedString(@"Schedules", nil),
                  NSLocalizedString(@"Timer", nil),
                  NSLocalizedString(@"FitA test", nil)];
    
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
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.contentOffset = CGPointMake(0, 0);    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [self.tableView reloadData];

    __weak typeof(self) this = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        this.workouts = [[Workout MR_findAllSortedBy:@"date" ascending:NO] mutableCopy];
        
        this.workoutsController = [[DKScheduleViewController alloc] initWithWorkouts:this.workouts];
        
        this.workoutsController.title = NSLocalizedString(@"Schedules", nil);
    });
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DKMenuCell *cell = [self.tableView dequeueReusableCellWithIdentifier:DKWorkoutMenuViewControllerCellId];
    
    if (cell == nil) {
        cell = [[DKMenuCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DKWorkoutMenuViewControllerCellId];
        
        cell.userInteractionEnabled = YES;
        cell.selectedBackgroundView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont fontWithName:ApplicationLightFont size:40];
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
    factory.size = 35;
    
    UIImage *menuImage = nil;
    
    switch (indexPath.row) {
        case 0:
            menuImage = [factory createImageForIcon:NIKFontAwesomeIconListOl];
            break;
        case 1:
            menuImage = [factory createImageForIcon:NIKFontAwesomeIconTime];
            break;
        case 2:
            menuImage = [factory createImageForIcon:NIKFontAwesomeIconCalendar];
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
            [Flurry logEvent:@"Open schedule"];
            [self.navigationController pushViewController:self.workoutsController animated:YES];
        }
            break;
        case 1: {
            [Flurry logEvent:@"Open timer"];
            
            DKTimerViewController *viewController = [DKTimerViewController new];
            
            viewController.title = menuItems[indexPath.row];
            
            [self.navigationController pushViewController:viewController animated:YES];
        }
            break;
        case 2: {
            [Flurry logEvent:@"Open progress"];
        }
        default:
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
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
