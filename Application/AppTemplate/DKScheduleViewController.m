//
//  DKScheduleViewController.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 6/5/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKScheduleViewController.h"
#import "DKTableViewCell.h"
#import "DKSettingsViewController.h"
#import "Workout.h"
#import "DKWorkoutCell.h"

#import "NIKFontAwesomeIconFactory.h"
#import "NIKFontAwesomeIconFactory+iOS.h"
#import "Flurry.h"
#import "FXBlurView.h"
#import "MOOPullGestureRecognizer.h"
#import "MOOCreateView.h"
#import <MessageUI/MessageUI.h>
#import "UIColor+MLPFlatColors.h"

#define DKScheduleViewControllerCellHeight 60
#define DKScheduleViewControllerCellId @"DKScheduleViewControllerCellId"

@interface DKScheduleViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate,
                                        DKWorkoutCellDelegate, UIActionSheetDelegate, UITextViewDelegate> {
    CGRect keyboardRect;
    CGRect cellRect;
}

@property (nonatomic, strong) NSMutableArray *workouts;
@property (nonatomic, weak) Workout *selectedWorkout;
@property (nonatomic, strong) MOOCreateView *createView;
@property (nonatomic, strong) MOOPullGestureRecognizer *recognizer;
@property (nonatomic, strong) UITextView *textView;

@end

@implementation DKScheduleViewController

@synthesize createView = _createView;
@synthesize recognizer = _recognizer;
@synthesize workouts = _workouts;
@synthesize selectedWorkout = _selectedWorkout;
@synthesize textView = _textView;

- (id)initWithWorkouts: (NSArray *)workouts {
    self = [super init];
    
    if (self) {
        _workouts = [workouts mutableCopy];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [this reloadAllWorkouts];
        
        this.recognizer = [[MOOPullGestureRecognizer alloc] initWithTarget:this action:@selector(handleGesture:)];
        
        // Create cell
        UITableViewCell *newCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        
        newCell.backgroundColor = [UIColor clearColor];// self.tableView.backgroundColor;
        newCell.contentView.backgroundColor = this.tableView.backgroundColor;
        newCell.textLabel.font = [UIFont fontWithName:ApplicationLightFont size:20];
        newCell.textLabel.textColor = [UIColor whiteColor];
        newCell.textLabel.textAlignment = NSTextAlignmentLeft;
        
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
                    cell.textLabel.text = NSLocalizedString(@"Release to add...", nil);
                    break;
                case MOOPullIdle:
                    cell.textLabel.text = NSLocalizedString(@"Pull to add...", nil);
                    break;
            }
        };
        
        this.recognizer.triggerView = this.createView;
        
        [this.tableView addGestureRecognizer:this.recognizer];
    });    
}

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
        if ([gestureRecognizer conformsToProtocol:@protocol(MOOPullGestureRecognizer)])
            [self _pulledToCreate:(UIGestureRecognizer<MOOPullGestureRecognizer> *)gestureRecognizer];
    }
}

- (void)_pulledToCreate:(UIGestureRecognizer<MOOPullGestureRecognizer> *)pullGestureRecognizer {
    
    Workout *newWorkout = [Workout MR_createEntity];
    
    newWorkout.date = [NSDate date];
    
    [self.workouts insertObject:newWorkout atIndex:0];
    
    CGPoint contentOffset = self.tableView.contentOffset;
    contentOffset.y -= CGRectGetMinY(pullGestureRecognizer.triggerView.frame);
    
    [self.tableView reloadData];
    self.tableView.contentOffset = contentOffset;
    
    [self startEditWorkoutAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    __weak typeof(self) this = self;
    
//    [self saveChangesAsyncWithBlock:^(BOOL isFailedToSave) {
//        
//        [Flurry logEvent:@"Added workout"];
//        [this reloadAllWorkouts];
//        
//        int64_t delayInSeconds = 0.8;
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//            
//            [this.tableView.pullGestureRecognizer resetPullState];
//            
//        });
//    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    if (self.workouts.count == 1) {
//        [self startShowItemOptionsTutorial];
//    }
}

- (NSMutableArray *)reloadAllWorkouts {
    
    self.workouts = [[Workout MR_findAllSortedBy:@"date" ascending:NO] mutableCopy];
    __weak typeof(self) this = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (this.workouts.count == 0) {
            [this startCreateNewItemTutorialWithInfo: NSLocalizedString(@"Pull down to add new workout", nil)];
        }
    });
    
    return self.workouts;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.workouts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DKWorkoutCell *cell = [self.tableView dequeueReusableCellWithIdentifier:DKScheduleViewControllerCellId];
    
    if (cell == nil) {
        cell = [[DKWorkoutCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DKScheduleViewControllerCellId];
        
        cell.userInteractionEnabled = YES;
        cell.selectedBackgroundView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont fontWithName:ApplicationFont size:18];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        
        cell.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.textLabel.backgroundColor = [UIColor clearColor];
    }
    
    Workout *workout = self.workouts[indexPath.row];
    
    cell.workout = workout;
    cell.delegate = self;
        
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Workout *workout = self.workouts[indexPath.row];
    
//    DKDaysViewController *daysController = [[DKDaysViewController alloc] initWithWeek:week];
//    
//    daysController.title = [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"Week", nil), [week.seqNumber intValue] + self.weekShift];
//    
//    [self.navigationController pushViewController:daysController animated:YES];
    
    [Flurry logEvent:@"Selected workout"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return DKScheduleViewControllerCellHeight;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Workout *workout = self.workouts[indexPath.row];
        
        [self.tableView beginUpdates];
        
        [self.workouts removeObject: workout];
        
        [workout MR_deleteEntity];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
        
        __weak typeof(self) this = self;
        
//        [self saveChangesAsyncWithBlock:^(BOOL isFailedToSave) {
//            [this reloadAllWorkouts];
//        }];
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

- (void)startEditWorkoutAtIndexPath: (NSIndexPath *)indexPath {
    
    self.selectedWorkout = self.workouts[indexPath.row];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectZero];
    
    self.textView.textColor = [UIColor whiteColor];
    self.textView.backgroundColor = ApplicationMainColor;
    self.textView.font = [UIFont fontWithName:ApplicationFont size:18];
    self.textView.tintColor = [UIColor whiteColor];
    self.textView.center = CGPointMake(ScreenWidth / 2, ScreenHeight + DKScheduleViewControllerCellHeight);
    self.textView.delegate = self;
    self.textView.returnKeyType = UIReturnKeyDone;
    self.textView.keyboardType = UIKeyboardTypeDefault;
    self.textView.text = self.selectedWorkout.title;
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    if (cell) {
        cellRect = [self.tableView convertRect:cell.frame toView:self.view];
    } else {
        cellRect = CGRectMake(0, ScreenHeight, ScreenWidth, DKScheduleViewControllerCellHeight);
    }
    
    self.textView.frame = CGRectMake(cellRect.origin.x, cellRect.origin.y, cellRect.size.width,
                                     ScreenHeight - ApplicationNavigationAndStatusBarHeight);
    
    [self.view addSubview:self.textView];
    [self.textView becomeFirstResponder];
}

- (void)endEditWorkout {
    
    self.selectedWorkout.title = self.textView.text;
    
    [self.textView resignFirstResponder];
    
    __weak typeof(self) this = self;
    
//    [self saveChangesAsyncWithBlock:^(BOOL isFailedToSave) {
//        [this.tableView reloadData];
//    }];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    BOOL retVal = YES;
    
    if ([text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound) {
        retVal = NO;
        
        [self endEditWorkout];
    }
    
	return retVal;
}

- (void)keyboardWillShow:(NSNotification *)aNotification {
    keyboardRect = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    __weak typeof(self)this = self;
    
    if (self.textView != nil) {
        float animationDuration = [[[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        UIViewAnimationCurve animationCurve = [[[aNotification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
        UIViewAnimationOptions animationOptions = (UIViewAnimationOptions)(animationCurve << 16);
        
        [UIView animateWithDuration:animationDuration delay:0.0 options:animationOptions animations:^{
            
            this.textView.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight - ApplicationNavigationAndStatusBarHeight - keyboardRect.size.height);
            
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
    keyboardRect = CGRectZero;
    
    __weak typeof(self)this = self;
    
    if (self.textView != nil) {
        float animationDuration = [[[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        UIViewAnimationCurve animationCurve = [[[aNotification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
        UIViewAnimationOptions animationOptions = (UIViewAnimationOptions)(animationCurve << 16);
        
        [UIView animateWithDuration:animationDuration delay:0.0 options:animationOptions animations:^{
            
            this.textView.frame = CGRectMake(cellRect.origin.x, cellRect.origin.y - 6, cellRect.size.width, cellRect.size.height);
            
        } completion:^(BOOL finished) {
            
            [this.textView removeFromSuperview];
            
            this.textView = nil;
        }];
    }
}

@end
