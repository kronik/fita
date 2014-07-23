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
#import "DKCircleImageView.h"
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

@property (nonatomic, weak) DKWeek *selectedWeek;
@property (nonatomic, strong) UIViewController *messageViewController;
@property (nonatomic, strong) MOOCreateView *createView;
@property (nonatomic, strong) MOOPullGestureRecognizer *recognizer;
@property (nonatomic) int weekShift;

@end

@implementation DKWeeksViewController

- (id)initWithWeeks: (NSMutableArray *)weeks {
    self = [super init];
    
    if (self) {
        self.items = [weeks mutableCopy];
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
        
        // Create cell
        UITableViewCell *newCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        
        newCell.backgroundColor = [UIColor clearColor];// self.tableView.backgroundColor;
        newCell.contentView.backgroundColor = this.tableView.backgroundColor;
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
                    DKWeek *maxWeek = this.items.firstObject;
                    
                    cell.textLabel.text = [NSString stringWithFormat:@"%@ %ld", NSLocalizedString(@"Week", nil),
                                           (maxWeek.seqNumber  + this.weekShift + 1)];
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
    DKWeek *weekToExport = (DKWeek *)notification.object;
    UIView *view = (UIView *)notification.userInfo[@"view"];
    
    if ((weekToExport == nil) || (view == nil)) {
        return;
    }
    
    [self exportWeek:weekToExport withAlertInView:view];
}

- (void)exportWeek:(DKWeek *)week withAlertInView: (UIView *)view {
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

+ (NSString *)exportTextForWeek: (DKWeek *)week {
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

            controller.subject = [NSString stringWithFormat:@"\n%@ %ld\n", NSLocalizedString(@"Week", nil), self.selectedWeek.seqNumber + weekShift];
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

- (void)reloadData {
    [self reloadAllWeeks];
    [self.tableView reloadData];
}

- (void)_pulledToCreate:(UIGestureRecognizer<MOOPullGestureRecognizer> *)pullGestureRecognizer {
    
    self.createView.alpha = [self canAddNewWeek] ? 1.0 : 0.0;

    if ([self canAddNewWeek] == NO) {
        return;
    }
    
    DKWeek *newWeek = [DKWeek new];
    
    DKWeek *maxWeek = self.items.firstObject;
    
    newWeek.seqNumber = maxWeek.seqNumber + 1;
    newWeek.startDate = [NSDate date];
    
    [self.items insertObject:newWeek atIndex:0];
    
    CGPoint contentOffset = self.tableView.contentOffset;
    contentOffset.y -= CGRectGetMinY(pullGestureRecognizer.triggerView.frame);

    [self.tableView reloadData];
    self.tableView.contentOffset = contentOffset;
    
    [DKModel addObject:newWeek];

    [Flurry logEvent:@"Added week"];
    [self reloadAllWeeks];
    
    
    __weak typeof(self) this = self;
    
    int64_t delayInSeconds = 0.8;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

        [this.tableView.pullGestureRecognizer resetPullState];

        DKDaysViewController *daysController = [[DKDaysViewController alloc] initWithWeek:newWeek];

        daysController.title = [NSString stringWithFormat:@"%@ %ld", NSLocalizedString(@"Week", nil),
                                newWeek.seqNumber + this.weekShift];
        
        [this.navigationController pushViewController:daysController animated:YES];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.items.count == 1) {
        [self startShowItemOptionsTutorial];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)reloadAllWeeks {
    
    self.items = [DKModel loadAllWeeks];
    self.weekShift = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kSettingsWeekKey];

    if (self.weekShift > 0) {
        self.weekShift --;
    }
    __weak typeof(self) this = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (this.items.count == 0) {
            [this startCreateNewItemTutorialWithInfo: NSLocalizedString(@"Pull down to add new week", nil)];
        }
        
        this.createView.alpha = [this canAddNewWeek] ? 1.0 : 0.0;
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
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
    
    DKWeek *week = self.items[indexPath.row];
    
    [cell setWeek:week withShift:self.weekShift];
    
    cell.delegate = self;
    
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
            DKWeek *week = self.items[indexPath.row];
            
            [self exportWeek: week withAlertInView:self.view];
        }
            break;
        case 1: {
            DKWeek *week = self.items[indexPath.row];
            
            [self.tableView beginUpdates];
            
            [self.items removeObjectAtIndex:indexPath.row];

            [DKModel deleteObject:week];
            
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            [self.tableView endUpdates];
            
            [Flurry logEvent:@"Deleted week"];
        }
            break;
        default: break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    DKWeek *week = self.items[indexPath.row];

    DKDaysViewController *daysController = [[DKDaysViewController alloc] initWithWeek:week];
    
    daysController.title = [NSString stringWithFormat:@"%@ %ld", NSLocalizedString(@"Week", nil), week.seqNumber + self.weekShift];
    
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
        DKWeek *week = self.items[indexPath.row];

        [self.tableView beginUpdates];
        
        [self.items removeObjectAtIndex:indexPath.row];
        
        [DKModel deleteObject:week];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
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
