//
//  DKDaysViewController.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 17/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKDaysViewController.h"
#import "DKTableViewCell.h"
#import "DKSettingsViewController.h"
#import "DKMealViewController.h"
#import "Week.h"
#import "DKDayCell.h"
#import "Meal.h"
#import "DKCircleImageView.h"
#import "DKWeeksViewController.h"
#import "DKCircleButton.h"
#import "DKCompareViewController.h"

#import "UIColor+MLPFlatColors.h"
#import "NIKFontAwesomeIconFactory.h"
#import "NIKFontAwesomeIconFactory+iOS.h"
#import "Flurry.h"
#import "FXBlurView.h"
#import "MOOPullGestureRecognizer.h"
#import "MOOCreateView.h"
#import "IDMPhotoBrowser.h"
#import "CLImageEditor.h"

#import <MessageUI/MessageUI.h>
#import <MobileCoreServices/MobileCoreServices.h>

#define DKDaysViewControllerCellId @"DKDaysViewControllerCellId"
#define DKDaysViewControllerExtraCellId @"DKDaysViewControllerExtraCellId"

#define EXTRA_IMAGE_EDIT_ENABLED 1

typedef enum DKDaysViewActionType {
    DKDaysViewActionTypeNone = 0,
    DKDaysViewActionTypeExport,
    DKDaysViewActionTypeFrontImage,
    DKDaysViewActionTypeSideImage
} DKDaysViewActionType;

@interface DKDaysViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate,
                                    SWTableViewCellDelegate, UIActionSheetDelegate, IDMPhotoBrowserDelegate,
                                    MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate,
                                    UIImagePickerControllerDelegate, UINavigationControllerDelegate,
                                    CLImageEditorDelegate, CLImageEditorTransitionDelegate, CLImageEditorThemeDelegate>

@property (nonatomic, strong) NSMutableArray *days;
@property (nonatomic, strong) MOOCreateView *createView;
@property (nonatomic, strong) MOOPullGestureRecognizer *recognizer;
@property (nonatomic, strong) UIViewController *messageViewController;
@property (nonatomic, strong) UIView *tableFooterView;
@property (nonatomic, strong) DKCircleButton *imageButton;
@property (nonatomic, strong) DKCircleButton *imageSideButton;
@property (nonatomic, strong) DKCircleButton *compareButton;
@property (nonatomic, strong) NSArray *buttons;
@property (nonatomic) DKDaysViewActionType actionType;
@property (nonatomic) int weekOffset;
@property (nonatomic, weak) Week *week;
@property (nonatomic, weak) Day *selectedDay;
@property (nonatomic) BOOL needButtonAnimation;
@property (nonatomic, strong) UIImagePickerController *imagePicker;

@end

@implementation DKDaysViewController

@synthesize days = _days;
@synthesize createView = _createView;
@synthesize recognizer = _recognizer;
@synthesize selectedDay = _selectedDay;
@synthesize messageViewController = _messageViewController;
@synthesize tableFooterView = _tableFooterView;
@synthesize imageButton = _imageButton;
@synthesize imageSideButton = _imageSideButton;
@synthesize compareButton = _compareButton;
@synthesize buttons = _buttons;
@synthesize needButtonAnimation = _needButtonAnimation;
@synthesize imagePicker = _imagePicker;

- (id)initWithWeek: (Week *)week {
    self = [super init];
    
    if (self) {
        _week = week;
        _needButtonAnimation = YES;
        
        _days = [[[week.days allObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
          
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
            
        }] mutableCopy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
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
    
    self.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 200)];
    
    self.tableFooterView.backgroundColor = ApplicationMainColor;
    self.tableFooterView.clipsToBounds = YES;
    
//    self.tableView.tableFooterView = self.tableFooterView;
    
    self.imageButton = [DKCircleButton buttonWithType:UIButtonTypeCustom];
    
    self.imageButton.frame = CGRectMake(0, 0, 90, 90);
    self.imageButton.backgroundColor = ApplicationMainColor;
    self.imageButton.clipsToBounds = YES;
    self.imageButton.titleLabel.font = [UIFont fontWithName:ApplicationFont size:20];
    self.imageButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.imageButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.imageButton.center = CGPointMake((self.tableFooterView.frame.size.width / 3) / 2, (self.tableFooterView.frame.size.height / 2) - 40);

    [self.imageButton addTarget:self action:@selector(tapOnImageButton) forControlEvents:UIControlEventTouchUpInside];
    
    [self.imageButton setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateNormal];
    [self.imageButton setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateSelected];
    [self.imageButton setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateHighlighted];

    [self.imageButton setTitle:NSLocalizedString(@"Front photo", nil) forState:UIControlStateNormal];
    [self.imageButton setTitle:NSLocalizedString(@"Front photo", nil) forState:UIControlStateSelected];
    [self.imageButton setTitle:NSLocalizedString(@"Front photo", nil) forState:UIControlStateHighlighted];

    [self.tableFooterView addSubview: self.imageButton];

    self.imageSideButton = [DKCircleButton buttonWithType:UIButtonTypeCustom];
    
    self.imageSideButton.frame = CGRectMake(0, 0, 90, 90);
    self.imageSideButton.backgroundColor = ApplicationMainColor;
    self.imageSideButton.clipsToBounds = YES;
    self.imageSideButton.titleLabel.font = [UIFont fontWithName:ApplicationFont size:20];
    self.imageSideButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.imageSideButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.imageSideButton.center = CGPointMake(self.tableFooterView.frame.size.width / 2, (self.tableFooterView.frame.size.height / 2) - 40);
    
    [self.imageSideButton addTarget:self action:@selector(tapOnImageSideButton) forControlEvents:UIControlEventTouchUpInside];
    
    [self.imageSideButton setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateNormal];
    [self.imageSideButton setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateSelected];
    [self.imageSideButton setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateHighlighted];
    
    [self.imageSideButton setTitle:NSLocalizedString(@"Side photo", nil) forState:UIControlStateNormal];
    [self.imageSideButton setTitle:NSLocalizedString(@"Side photo", nil) forState:UIControlStateSelected];
    [self.imageSideButton setTitle:NSLocalizedString(@"Side photo", nil) forState:UIControlStateHighlighted];
    
    [self.tableFooterView addSubview: self.imageSideButton];

    self.compareButton = [DKCircleButton buttonWithType:UIButtonTypeCustom];
    
    self.compareButton.frame = CGRectMake(0, 0, 90, 90);
    self.compareButton.backgroundColor = ApplicationMainColor;
    self.compareButton.clipsToBounds = YES;
    self.compareButton.titleLabel.font = [UIFont fontWithName:ApplicationFont size:16];
    self.compareButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.compareButton.titleLabel.lineBreakMode = NSLineBreakByCharWrapping;
    self.compareButton.center = CGPointMake((self.tableFooterView.frame.size.width * 2 / 3) + (self.tableFooterView.frame.size.width / 3) / 2,
                                            (self.tableFooterView.frame.size.height / 2) - 40);
    
    [self.compareButton addTarget:self action:@selector(tapOnCompareButton) forControlEvents:UIControlEventTouchUpInside];
    
    [self.compareButton setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateNormal];
    [self.compareButton setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateSelected];
    [self.compareButton setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateHighlighted];
    
    [self.compareButton setTitle:NSLocalizedString(@"Compare weeks", nil) forState:UIControlStateNormal];
    [self.compareButton setTitle:NSLocalizedString(@"Compare weeks", nil) forState:UIControlStateSelected];
    [self.compareButton setTitle:NSLocalizedString(@"Compare weeks", nil) forState:UIControlStateHighlighted];
    
    [self.tableFooterView addSubview: self.compareButton];

    self.buttons = @[self.imageButton, self.imageSideButton, self.compareButton];

    [self.tableView reloadData];
    
    dispatch_async(dispatch_get_main_queue(), ^{

        [this reloadAllDays];
        
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
            
            if ((![cell isKindOfClass:[UITableViewCell class]]) || (this.days.count == 7)) {
                return;
            }
            
            switch (state) {
                case MOOPullActive:
                case MOOPullTriggered:
                    //                cell.textLabel.text = NSLocalizedString(@"Release to add...", nil);
                    //                break;
                case MOOPullIdle: {
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    
                    [dateFormatter setDateFormat:@"EEEE"];
                    
                    Day *day = this.days.lastObject;
                    
                    NSDate *lastDate = day ? day.date : [NSDate date];
                    NSDate *nextDate = [lastDate dateByAddingTimeInterval:(60 * 60 * 24) * this.days.count];

                    cell.textLabel.text = [dateFormatter stringFromDate:nextDate];
                    //                cell.textLabel.text = NSLocalizedString(@"Pull to add...", nil);
                }
                    break;
                default:break;
            }
        };
        
        this.recognizer.triggerView = this.createView;
        
        [this.tableView addGestureRecognizer:this.recognizer];
        
        this.createView.alpha = [this canAddNewDay] ? 1.0 : 0.0;
    });    
}

- (void)didSelectActionForDay:(Day *)day {
    self.selectedDay = day;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"Message", nil),
                                  NSLocalizedString(@"Email", nil),
                                  NSLocalizedString(@"Copy", nil), nil];

    self.actionType = DKDaysViewActionTypeExport;

    [actionSheet showInView:self.view];
    
    [Flurry logEvent:@"Export day"];
}

- (NSString *)textToExport {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    
    int weekShift = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kSettingsWeekKey];
    
    if (weekShift > 0) {
        weekShift --;
    }
    
    NSString *textToShare = [NSString stringWithFormat:@"\n%@ %d %@\n", NSLocalizedString(@"Week", nil),
                             [self.selectedDay.week.seqNumber intValue] + weekShift, self.selectedDay.name];
    
    NSPredicate *dayFilter = [NSPredicate predicateWithFormat:@"day = %@", self.selectedDay];
    NSArray *mealEntries = [Meal MR_findAllSortedBy:@"time" ascending:YES withPredicate:dayFilter];
    
    for (Meal *meal in mealEntries) {
        if (meal.text.length == 0) {
            continue;
        }
        
        textToShare = [textToShare stringByAppendingString:[NSString stringWithFormat:@"%@: %@\n",
                                                            [dateFormatter stringFromDate: meal.time], meal.text]];
    }
    
    textToShare = [textToShare stringByAppendingString:@"\n"];

    return textToShare;
}

- (void)handleExportWithButtonIndex: (NSInteger)buttonIndex {
    NSString *textToShare = self.selectedDay ? [self textToExport] : [DKWeeksViewController exportTextForWeek:self.week];
    
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
            
            if (self.selectedDay) {
                controller.subject = [NSString stringWithFormat:@"\n%@ %d %@", NSLocalizedString(@"Week", nil),
                                      [self.selectedDay.week.seqNumber intValue], self.selectedDay.name];
            } else {
                int weekShift = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kSettingsWeekKey];
                
                if (weekShift > 0) {
                    weekShift --;
                }
                
                controller.subject = [NSString stringWithFormat:@"\n%@ %d\n", NSLocalizedString(@"Week", nil), [self.week.seqNumber intValue] + weekShift];
            }
            controller.mailComposeDelegate = self;
            controller.navigationBar.tintColor = [UIColor whiteColor];
            
            [controller setMessageBody:textToShare isHTML:NO];
            
            self.messageViewController = controller;
            
            [self presentViewController:controller animated:YES completion:nil];
        }
            break;
            
        case 2: {
            [UIPasteboard generalPasteboard].string = textToShare;
            
            if (self.selectedDay) {
                [self showCompleteIndicatorWithTitle:NSLocalizedString(@"You copied selected day", nil)];
            } else {
                [self showCompleteIndicatorWithTitle:NSLocalizedString(@"You copied selected week", nil)];
            }
        }
            break;
            
        default:
            break;
    }
    
    self.actionType = DKDaysViewActionTypeNone;
    self.selectedDay = nil;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        self.selectedDay = nil;
        self.actionType = DKDaysViewActionTypeNone;
        return;
    }
    
    switch (self.actionType) {
        case DKDaysViewActionTypeExport:
            [self handleExportWithButtonIndex:buttonIndex];
            break;
        case DKDaysViewActionTypeFrontImage:
        case DKDaysViewActionTypeSideImage: {
            NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];

            [self handleImageActionWithButtonTitle: buttonTitle];
        }
            break;
        default:
            break;
    }
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

- (NSString *)nameOfDay: (NSUInteger)day {
    switch (day) {
        case 0:
            return NSLocalizedString(@"Monday", nil);
        case 1:
            return NSLocalizedString(@"Tuesday", nil);
        case 2:
            return NSLocalizedString(@"Wednesday", nil);
        case 3:
            return NSLocalizedString(@"Thursday", nil);
        case 4:
            return NSLocalizedString(@"Friday", nil);
        case 5:
            return NSLocalizedString(@"Saturday", nil);
        case 6:
            return NSLocalizedString(@"Sunday", nil);
        default:
            return @"";
    }
}

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
        if ([gestureRecognizer conformsToProtocol:@protocol(MOOPullGestureRecognizer)])
            [self _pulledToCreate:(UIGestureRecognizer<MOOPullGestureRecognizer> *)gestureRecognizer];
    }
}

- (void)_pulledToCreate:(UIGestureRecognizer<MOOPullGestureRecognizer> *)pullGestureRecognizer {
    
    self.createView.alpha = [self canAddNewDay] ? 1.0 : 0.0;

    if ([self canAddNewDay] == NO) {
        return;
    }
    
    Day *newDay = [Day MR_createEntity];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"EEEE"];
    
    Day *day = self.days.lastObject;

    NSDate *lastDate = day ? day.date : [NSDate date];
    NSDate *nextDate = [lastDate dateByAddingTimeInterval:(60 * 60 * 24) * self.days.count];
    
    newDay.name = [dateFormatter stringFromDate:nextDate];

//    newDay.name = [self nameOfDay: self.days.count];
    newDay.week = self.week;
    newDay.date = nextDate;
    newDay.seqNumber = @(self.days.count);
    
    [self.week addDaysObject:newDay];
    
    [self.days insertObject:newDay atIndex:0];
    
    CGPoint contentOffset = self.tableView.contentOffset;
    contentOffset.y -= CGRectGetMinY(pullGestureRecognizer.triggerView.frame);

    [self.tableView reloadData];
    self.tableView.contentOffset = contentOffset;

    __weak typeof(self) this = self;

    [self saveChangesAsyncWithBlock:^(BOOL isFailedToSave) {
        
        [Flurry logEvent:@"Added day"];
        [this reloadAllDays];
        
        int64_t delayInSeconds = 0.8;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

            [this.tableView.pullGestureRecognizer resetPullState];

            DKMealViewController *mealController = [[DKMealViewController alloc] initWithDay:newDay canAddNewDay:NO];
            
            mealController.title = newDay.name;
            
            [this.navigationController pushViewController:mealController animated:YES];
        });
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.needButtonAnimation == NO) {
        return;
    }

    [self.buttons enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        view.layer.transform = CATransform3DMakeScale(0.3, 0.3, 1);
        view.alpha = 0;
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    if (self.days.count == 1) {
//        [self startShowItemOptionsTutorial];
//    }
    
    [self updateUI];
    
    CGFloat initDelay = 0.1f;
    
    if (self.needButtonAnimation == NO) {
        return;
    }

    [self.buttons enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        view.layer.transform = CATransform3DMakeScale(0.3, 0.3, 1);
        view.alpha = 0;
        
        [self animateSpringWithView:view idx:idx initDelay:initDelay];
    }];
}

- (void)animateSpringWithView:(UIView *)view idx:(NSUInteger)idx initDelay:(CGFloat)initDelay {
    [UIView animateWithDuration:0.5
                          delay:(initDelay + idx*0.1f)
         usingSpringWithDamping:10
          initialSpringVelocity:50
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         view.layer.transform = CATransform3DIdentity;
                         view.alpha = 1;
                     }
                     completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (BOOL)canAddNewDay {
    Day *day = self.days.firstObject;
    
    if (day == nil) {
        return YES;
    } else {
        return (self.days.count < 7);
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger comps = (NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit);
    
    NSDateComponents *date1Components = [calendar components:comps fromDate: [NSDate date]];
    NSDateComponents *date2Components = [calendar components:comps fromDate: day.date];
    
    NSDate *date1 = [calendar dateFromComponents:date1Components];
    NSDate *date2 = [calendar dateFromComponents:date2Components];
    
    NSComparisonResult result = [date1 compare:date2];
    
    return (result == NSOrderedDescending) && (self.days.count < 7);
}

- (NSMutableArray *)reloadAllDays {
    
    NSPredicate *weekFilter = [NSPredicate predicateWithFormat:@"week = %@", self.week];

    self.days = [[Day MR_findAllSortedBy:@"seqNumber" ascending:NO withPredicate:weekFilter] mutableCopy];
    
    self.createView.alpha = [self canAddNewDay] ? 1.0 : 0.0;
    
    if (self.days.count == 0) {
        [self startCreateNewItemTutorialWithInfo: NSLocalizedString(@"Pull down to add new day", nil)];
        
        self.navigationItem.rightBarButtonItem = nil;
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                               target:self
                                                                                               action:@selector(exportWeek)];
    }

    return self.days;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.days.count;
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        DKDayCell *cell = [self.tableView dequeueReusableCellWithIdentifier:DKDaysViewControllerCellId];
        
        if (cell == nil) {
            cell = [[DKDayCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DKDaysViewControllerCellId];
            
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
        
        Day *day = self.days[indexPath.row];
        
        cell.textLabel.text = day.name;
        cell.day = day;
        
//        cell.leftUtilityButtons = @[];
//        cell.rightUtilityButtons = [self rightButtons];

        return cell;
    } else {
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:DKDaysViewControllerExtraCellId];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DKDaysViewControllerExtraCellId];
            
            cell.backgroundColor = [UIColor clearColor];
            cell.contentView.backgroundColor = [UIColor clearColor];
            cell.textLabel.backgroundColor = [UIColor clearColor];
            
            [cell.contentView addSubview:self.tableFooterView];
        }
        
        return cell;
    }
}

- (NSArray *)rightButtons {
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    
    [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor flatDarkBlackColor]
                                                title: NSLocalizedString(@"Export", nil)];
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
            Day *day = self.days[indexPath.row];
            
            [self didSelectActionForDay: day];
        }
            break;
        default: break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section > 0) {
        return;
    }

    Day *day = self.days[indexPath.row];

    DKMealViewController *mealController = [[DKMealViewController alloc] initWithDay:day canAddNewDay:NO];
    
    mealController.title = day.name;
    
    [self.navigationController pushViewController:mealController animated:YES];
    
    [Flurry logEvent:@"Selected day"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 50;
    } else {
        return self.tableFooterView.frame.size.height;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Day *day = self.days[indexPath.row];

        [self.tableView beginUpdates];
        
        [self.days removeObject: day];
        
        [day MR_deleteEntity];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
        
        __weak typeof(self) this = self;
        
        [self saveChangesAsyncWithBlock:^(BOOL isFailedToSave) {
            [this reloadAllDays];
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

- (void)exportWeek {
    
    self.selectedDay = nil;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"Message", nil),
                                  NSLocalizedString(@"Email", nil),
                                  NSLocalizedString(@"Copy", nil), nil];

    self.actionType = DKDaysViewActionTypeExport;

    [actionSheet showInView:self.view];
    
    [Flurry logEvent:@"Export week"];
}

- (void)tapOnImageButton {
    
    [self didTapItem: self.imageButton];

    UIActionSheet *actionSheet = nil;
    
    NSString *openPhotoTitle = self.week.image ? NSLocalizedString(@"Open", nil) : nil;
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                    destructiveButtonTitle:nil
                                         otherButtonTitles: NSLocalizedString(@"Choose existing photo", nil), openPhotoTitle, nil];
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                    destructiveButtonTitle:NSLocalizedString(@"Take a photo", nil)
                                         otherButtonTitles:NSLocalizedString(@"Choose existing photo", nil), openPhotoTitle, nil];
    }
    
    self.actionType = DKDaysViewActionTypeFrontImage;
    
    [actionSheet showInView:self.view];
}

- (void)tapOnImageSideButton {

    [self didTapItem: self.imageSideButton];

    UIActionSheet *actionSheet = nil;
    
    NSString *openPhotoTitle = self.week.imageSide ? NSLocalizedString(@"Open", nil) : nil;

    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                    destructiveButtonTitle:nil
                                         otherButtonTitles: NSLocalizedString(@"Choose existing photo", nil), openPhotoTitle, nil];
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                    destructiveButtonTitle:NSLocalizedString(@"Take a photo", nil)
                                         otherButtonTitles:NSLocalizedString(@"Choose existing photo", nil), openPhotoTitle, nil];
    }
    
    self.actionType = DKDaysViewActionTypeSideImage;
    
    [actionSheet showInView:self.view];
}

- (void)tapOnCompareButton {
    [self didTapItem: self.compareButton];
    
    __weak typeof(self) this = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *weeks = [Week MR_findAllSortedBy:@"seqNumber" ascending:NO];
        
        if (weeks.lastObject == this.week) {
            return;
        }
        
        DKCompareViewController *viewController = [[DKCompareViewController alloc] initWithFirstWeek:weeks.lastObject andSecondWeek:this.week];
        
        [this.navigationController pushViewController:viewController animated:YES];
    });
}

- (void)handleImageActionWithButtonTitle: (NSString *)buttonTitle {
    
    self.imagePicker = [[UIImagePickerController alloc] init];
    
    if ([buttonTitle isEqualToString:NSLocalizedString(@"Choose existing photo", nil)]) {
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"Take a photo", nil)]) {
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Open", nil)]) {
        
        NSData *imageData = self.actionType == DKDaysViewActionTypeFrontImage ? self.week.image : self.week.imageSide;
        UIView *view = self.actionType == DKDaysViewActionTypeFrontImage ? self.imageButton : self.imageSideButton;
        
        IDMPhoto *photo = [IDMPhoto photoWithImage:[UIImage imageWithData:imageData]];
        IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:@[photo] animatedFromView:view];
        
        browser.delegate = self;
        browser.displayActionButton = YES;
        browser.displayArrowButton = NO;
        browser.displayCounterLabel = NO;
        browser.view.tintColor = [UIColor whiteColor];
        
        [self presentViewController:browser animated:YES completion:nil];
        
        self.actionType = DKDaysViewActionTypeNone;
        self.needButtonAnimation = NO;
        return;
    }
    
    self.imagePicker.mediaTypes = @[(NSString *) kUTTypeImage];
    self.imagePicker.delegate = self;
    
#if EXTRA_IMAGE_EDIT_ENABLED
    self.imagePicker.allowsEditing = NO;
#else
    self.imagePicker.allowsEditing = YES;
#endif
    self.imagePicker.navigationBar.tintColor = ApplicationMainColor;
    self.imagePicker.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor blackColor],
                                                           NSFontAttributeName: [UIFont fontWithName:ApplicationFont size:20.0]};
    
    [self presentViewController:self.imagePicker animated:YES completion: nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image= [info valueForKey:UIImagePickerControllerOriginalImage];
    
    if (image == nil) {
        return;
    }
    
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }

#if EXTRA_IMAGE_EDIT_ENABLED
    CLImageEditor *editor = [[CLImageEditor alloc] initWithImage:image];
    
    editor.delegate = self;
    editor.theme.backgroundColor = [UIColor whiteColor];
    editor.theme.toolbarColor = [UIColor whiteColor];
    editor.theme.toolbarTextColor = ApplicationMainColor;
    editor.theme.toolbarSelectedButtonColor = [ApplicationMainColor colorWithAlphaComponent:0.2];

    [picker pushViewController:editor animated:YES];
//    [picker presentViewController:editor animated:YES completion:nil];
#else
    [self finishEditImage:image];
    [picker dismissViewControllerAnimated:YES completion:^(void){[self.view setNeedsLayout];}];
    
    self.imagePicker = nil;
#endif
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    self.actionType = DKDaysViewActionTypeNone;
    [picker dismissViewControllerAnimated:YES completion:^(void){[self.view setNeedsLayout];}];
    
    self.imagePicker = nil;
}

- (void)finishEditImage: (UIImage *)image {
    if (self.actionType == DKDaysViewActionTypeFrontImage) {
        self.week.image = UIImageJPEGRepresentation(image, 1.0);
        
        [self.imageButton setImage:image forState:UIControlStateNormal];
    } else {
        self.week.imageSide = UIImageJPEGRepresentation(image, 1.0);
        [self.imageSideButton setImage:image forState:UIControlStateNormal];
    }
    
    __weak typeof(self) this = self;
    
    [self saveChangesAsyncWithBlock:^(BOOL isFailedToSave) {
        [this reloadAllDays];
        [this updateUI];
    }];
    
    self.actionType = DKDaysViewActionTypeNone;
}

- (void)imageEditor:(CLImageEditor *)editor didFinishEdittingWithImage:(UIImage *)image {
    if (image) {
        [self finishEditImage:image];
    }
    
    [editor dismissViewControllerAnimated:YES completion:nil];
    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
    
    self.imagePicker = nil;
}

- (void)imageEditor:(CLImageEditor *)editor willDismissWithImageView:(UIImageView *)imageView canceled:(BOOL)canceled {
    self.actionType = DKDaysViewActionTypeNone;
}

- (void)updateUI {
    [self.imageButton setImage:[UIImage imageWithData:self.week.image] forState:UIControlStateNormal];
    [self.imageSideButton setImage:[UIImage imageWithData:self.week.imageSide] forState:UIControlStateNormal];
}

- (void)didTapItem:(UIView *)view {
    
    CGRect pathFrame = CGRectMake(-CGRectGetMidX(view.bounds), -CGRectGetMidY(view.bounds), view.bounds.size.width, view.bounds.size.height);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:pathFrame cornerRadius:view.layer.cornerRadius];
    
    // accounts for left/right offset and contentOffset of scroll view
    CGPoint shapePosition = [self.view convertPoint:view.center fromView:self.tableFooterView];
    
    CAShapeLayer *circleShape = [CAShapeLayer layer];
    circleShape.path = path.CGPath;
    circleShape.position = shapePosition;
    circleShape.fillColor = [UIColor clearColor].CGColor;
    circleShape.opacity = 0;
    circleShape.strokeColor = [UIColor whiteColor].CGColor;
    circleShape.lineWidth = 2.0;
    
    [self.view.layer addSublayer:circleShape];
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(2.5, 2.5, 1)];
    
    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.fromValue = @1;
    alphaAnimation.toValue = @0;
    
    CAAnimationGroup *animation = [CAAnimationGroup animation];
    animation.animations = @[scaleAnimation, alphaAnimation];
    animation.duration = 0.5f;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [circleShape addAnimation:animation forKey:nil];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)index {
    self.needButtonAnimation = YES;
}

@end
