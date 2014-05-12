//
//  DKWeeksViewController.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 17/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKWeeksViewController.h"
#import "DKTableViewCell.h"
#import "DKSettingsViewController.h"
#import "DKDaysViewController.h"
#import "Day.h"
#import "Meal.h"
#import "DKCircleImageView.h"
#import "Week+Extra.h"
#import "DKWeekCell.h"

#import "NIKFontAwesomeIconFactory.h"
#import "NIKFontAwesomeIconFactory+iOS.h"
#import "Flurry.h"
#import "FXBlurView.h"
#import "MOOPullGestureRecognizer.h"
#import "MOOCreateView.h"
#import <MessageUI/MessageUI.h>
#import "UIColor+MLPFlatColors.h"
#import "IDMPhotoBrowser.h"

#define DKWeeksViewControllerCellId @"DKWeeksViewControllerCellId"

@interface DKWeeksViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate,
                                     DKWeekCellDelegate, UIActionSheetDelegate, IDMPhotoBrowserDelegate,
                                     MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NSMutableArray *weeks;
@property (nonatomic, weak) Week *selectedWeek;
@property (nonatomic, strong) UIViewController *messageViewController;
@property (nonatomic, strong) MOOCreateView *createView;
@property (nonatomic, strong) MOOPullGestureRecognizer *recognizer;
@property (nonatomic) int weekShift;

@end

@implementation DKWeeksViewController

@synthesize weeks = _weeks;
@synthesize selectedWeek = _selectedWeek;
@synthesize messageViewController = _messageViewController;
@synthesize createView = _createView;
@synthesize recognizer = _recognizer;
@synthesize weekShift = _weekShift;

- (id)initWithWeeks: (NSArray *)weeks {
    self = [super init];
    
    if (self) {
        _weeks = [weeks mutableCopy];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Weeks", nil);
    
    self.weekShift = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kSettingsWeekKey];
    
    if (self.weekShift > 0) {
        self.weekShift --;
    }
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 1)];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = ApplicationMainColor;
    self.tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = 50;
    self.tableView.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight - ApplicationNavigationAndStatusBarHeight);
    
    [self.view addSubview: self.tableView];

    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.contentOffset = CGPointMake(0, 0);

    __weak typeof(self) this = self;

    [self.tableView reloadData];

    dispatch_async(dispatch_get_main_queue(), ^{

        [this reloadAllWeeks];

        this.recognizer = [[MOOPullGestureRecognizer alloc] initWithTarget:this action:@selector(handleGesture:)];
        
//        NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory barButtonItemIconFactory];
//        
//        factory.colors = @[[UIColor whiteColor]];
//        factory.size = 30;
//
//        UIImage *menuImage = [factory createImageForIcon:NIKFontAwesomeIconCalendar];
        
        // Create cell
        UITableViewCell *newCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        
        newCell.backgroundColor = [UIColor clearColor];// self.tableView.backgroundColor;
        newCell.contentView.backgroundColor = this.tableView.backgroundColor;
//        newCell.imageView.image = menuImage;
        newCell.textLabel.font = [UIFont fontWithName:ApplicationLightFont size:30];
        newCell.textLabel.textColor = [UIColor whiteColor];
        newCell.textLabel.textAlignment = NSTextAlignmentRight;
        
        // Create create view
        this.createView = [[MOOCreateView alloc] initWithCell:newCell];
        
        this.createView.backgroundColor = ApplicationMainColor;
        
        this.createView.configurationBlock = ^(MOOCreateView *view, UITableViewCell *cell, MOOPullState state) {
            
            if (![cell isKindOfClass:[UITableViewCell class]]) {
                return;
            }
            
            switch (state) {
                case MOOPullActive:
                case MOOPullTriggered:
                    //                cell.textLabel.text = NSLocalizedString(@"Release to add...", nil);
                    //                break;
                case MOOPullIdle: {
                    Week *maxWeek = this.weeks.firstObject;
                    
                    cell.textLabel.text = [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"Week", nil),
                                           ([maxWeek.seqNumber intValue]  + this.weekShift + 1)];
                    //                cell.textLabel.text = NSLocalizedString(@"Pull to add...", nil);
                }
                    break;
                    
            }
        };
        
        this.recognizer.triggerView = this.createView;
        
        [this.tableView addGestureRecognizer:this.recognizer];

        this.createView.alpha = [this canAddNewWeek] ? 1.0 : 0.0;
    });
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onWeekExport:) name:kExportWeekNotification object:nil];
}

- (void)onWeekExport: (NSNotification *)notification {
    Week *weekToExport = (Week *)notification.object;
    UIView *view = (UIView *)notification.userInfo[@"view"];
    
    if ((weekToExport == nil) || (view == nil)) {
        return;
    }
    
    [self exportWeek:weekToExport withAlertInView:view];
}

- (void)exportWeek:(Week *)week withAlertInView: (UIView *)view {
    self.selectedWeek = week;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"Message", nil),
                                                                      NSLocalizedString(@"Email", nil),
                                                                      NSLocalizedString(@"Copy", nil), nil];
    [actionSheet showInView:view];
    
    [Flurry logEvent:@"Export week"];
}

+ (NSString *)exportTextForWeek: (Week *)week {
    return [week fullDescription];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        self.selectedWeek = nil;
        return;
    }
    
    NSString *textToShare = [DKWeeksViewController exportTextForWeek:self.selectedWeek];
    
    switch (buttonIndex) {
        case 0: {
            MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
            
            if ([MFMessageComposeViewController canSendText]) {
                controller.body = textToShare;
				controller.messageComposeDelegate = self;
                controller.navigationBar.tintColor = [UIColor whiteColor];

                self.messageViewController = controller;

                [self presentViewController:controller animated:YES completion:nil];
            }
        }
            break;
        
        case 1: {
            MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
            
            int weekShift = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kSettingsWeekKey];
            
            if (weekShift > 0) {
                weekShift --;
            }

            controller.subject = [NSString stringWithFormat:@"\n%@ %d\n", NSLocalizedString(@"Week", nil), [self.selectedWeek.seqNumber intValue] + weekShift];
            controller.mailComposeDelegate = self;
            controller.navigationBar.tintColor = [UIColor whiteColor];

            [controller setMessageBody:textToShare isHTML:NO];
            
            self.messageViewController = controller;
            
            [self presentViewController:controller animated:YES completion:nil];
        }
            break;
            
        case 2: {
            [UIPasteboard generalPasteboard].string = textToShare;
            [self showCompleteIndicatorWithTitle:NSLocalizedString(@"You copied selected week", nil)];
        }
            break;
            
        default:
            break;
    }
    
    self.selectedWeek = nil;
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result {
    [self.messageViewController dismissViewControllerAnimated:YES completion:NULL];
    
    self.messageViewController = nil;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self.messageViewController dismissViewControllerAnimated:YES completion:NULL];
    
    self.messageViewController = nil;
}

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
        if ([gestureRecognizer conformsToProtocol:@protocol(MOOPullGestureRecognizer)])
            [self _pulledToCreate:(UIGestureRecognizer<MOOPullGestureRecognizer> *)gestureRecognizer];
    }
}

- (void)_pulledToCreate:(UIGestureRecognizer<MOOPullGestureRecognizer> *)pullGestureRecognizer {
    
    self.createView.alpha = [self canAddNewWeek] ? 1.0 : 0.0;

    if ([self canAddNewWeek] == NO) {
        return;
    }
    
    Week *newWeek = [Week MR_createEntity];
    
    Week *maxWeek = self.weeks.firstObject;
    
    newWeek.seqNumber = @([maxWeek.seqNumber intValue] + 1);
    newWeek.startDate = [NSDate date];
    
    [self.weeks insertObject:newWeek atIndex:0];
    
    CGPoint contentOffset = self.tableView.contentOffset;
    contentOffset.y -= CGRectGetMinY(pullGestureRecognizer.triggerView.frame);

    [self.tableView reloadData];
    self.tableView.contentOffset = contentOffset;

    __weak typeof(self) this = self;

    [self saveChangesAsyncWithBlock:^(BOOL isFailedToSave) {
        
        [Flurry logEvent:@"Added week"];
        [this reloadAllWeeks];
        
        int64_t delayInSeconds = 0.8;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

            [this.tableView.pullGestureRecognizer resetPullState];

            DKDaysViewController *daysController = [[DKDaysViewController alloc] initWithWeek:newWeek];

            daysController.title = [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"Week", nil),
                                    [newWeek.seqNumber intValue] + this.weekShift];
            
            [this.navigationController pushViewController:daysController animated:YES];
        });
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.weeks.count == 1) {
        [self startShowItemOptionsTutorial];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (NSMutableArray *)reloadAllWeeks {
    
    self.weeks = [[Week MR_findAllSortedBy:@"seqNumber" ascending:NO] mutableCopy];
    self.weekShift = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kSettingsWeekKey];

    if (self.weekShift > 0) {
        self.weekShift --;
    }
    __weak typeof(self) this = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (this.weeks.count == 0) {
            [this startCreateNewItemTutorialWithInfo: NSLocalizedString(@"Pull down to add new week", nil)];
        }
        
        this.createView.alpha = [this canAddNewWeek] ? 1.0 : 0.0;
    });

    return self.weeks;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.weeks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DKWeekCell *cell = [self.tableView dequeueReusableCellWithIdentifier:DKWeeksViewControllerCellId];
    
    if (cell == nil) {
        cell = [[DKWeekCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DKWeeksViewControllerCellId];
        
        cell.userInteractionEnabled = YES;
        cell.selectedBackgroundView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont fontWithName:ApplicationLightFont size:30];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.numberOfLines = 1;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.textAlignment = NSTextAlignmentRight;
    
        cell.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.textLabel.backgroundColor = [UIColor clearColor];
    }
    
//    NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory barButtonItemIconFactory];
//    
//    factory.colors = @[[UIColor whiteColor]];
//    factory.size = 30;
//    
//    UIImage *menuImage = [factory createImageForIcon:NIKFontAwesomeIconCalendar];
    Week *week = self.weeks[indexPath.row];
    
//    cell.imageView.image = menuImage;
    
    [cell setWeek:week withShift:self.weekShift];
    
    cell.delegate = self;
    
//    cell.leftUtilityButtons = nil;
//    cell.rightUtilityButtons = [self rightButtons];
    
    return cell;
}

- (NSArray *)rightButtons {
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    
    [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor flatDarkBlackColor]
                                                title: NSLocalizedString(@"Export", nil)];
    [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title: NSLocalizedString(@"Delete", nil)];
    
    return rightUtilityButtons;
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell {
    return YES;
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    [cell hideUtilityButtonsAnimated:YES];
    
    switch (index) {
        case 0: {
            Week *week = self.weeks[indexPath.row];
            
            [self exportWeek: week withAlertInView:self.view];
        }
            break;
        case 1: {
            Week *week = self.weeks[indexPath.row];
            
            [self.tableView beginUpdates];
            
            [self.weeks removeObject: week];
            
            [week MR_deleteEntity];
            
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            [self.tableView endUpdates];
            
            __weak typeof(self) this = self;
            
            [self saveChangesAsyncWithBlock:^(BOOL isFailedToSave) {
                [Flurry logEvent:@"Deleted week"];
                [this reloadAllWeeks];
            }];
            
        }
            break;
        default: break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Week *week = self.weeks[indexPath.row];

    DKDaysViewController *daysController = [[DKDaysViewController alloc] initWithWeek:week];
    
    daysController.title = [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"Week", nil), [week.seqNumber intValue] + self.weekShift];
    
    [self.navigationController pushViewController:daysController animated:YES];
    
    [Flurry logEvent:@"Selected week"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Week *week = self.weeks[indexPath.row];

        [self.tableView beginUpdates];
        
        [self.weeks removeObject: week];
        
        [week MR_deleteEntity];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
        
        __weak typeof(self) this = self;
        
        [self saveChangesAsyncWithBlock:^(BOOL isFailedToSave) {
            [this reloadAllWeeks];
        }];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return UITableViewCellEditingStyleDelete;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.pullGestureRecognizer) {
        [scrollView.pullGestureRecognizer scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView.pullGestureRecognizer) {
        [scrollView.pullGestureRecognizer resetPullState];
    }
}

- (BOOL)canAddNewWeek {
    
    return YES;
    
    Week *week = self.weeks.firstObject;
    
    return (week == nil) || (week.days.count == 7);
}

- (void)didTapOnPhotoOfWeek: (Week *)week inView: (UIView *)view {
    
    if (week.image == nil) {
        return;
    }    
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
