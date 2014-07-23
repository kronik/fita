//
//  DKTimerViewController.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 25/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKTimerViewController.h"
#import "DKTimerSettingsView.h"
#import "DKTableViewCell.h"
#import "DKCircleImageView.h"
#import "DKCircleButton.h"
#import "DKProgressView.h"
#import "DKPurchaseViewController.h"
#import "Timer.h"

#import "MZTimerLabel.h"
#import "UIView+Screenshot.h"
#import "MOOPullGestureRecognizer.h"
#import "MOOCreateView.h"
#import "NIKFontAwesomeIconFactory.h"
#import "NIKFontAwesomeIconFactory+iOS.h"
#import "Flurry.h"
#import "UIColor+MLPFlatColors.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#define DKTimerViewControllerDefaultTimerConfiguration @"00:10 00:00 01 10"
#define DKTimerViewControllerLastTimerConfiguration @"DKTimerViewControllerLastTimerConfiguration"

#define DKTimerViewControllerSection0CellId @"DKTimerViewControllerSection0CellId"
#define DKTimerViewControllerSection1CellId @"DKTimerViewControllerSection1CellId"

@interface DKTimerViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate,
                                     DKTimerSettingsViewDelegate, MZTimerLabelDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) DKTimerSettingsView *timePicker;
@property (nonatomic, strong) UIView *timerView;
@property (nonatomic, strong) MZTimerLabel *timerLabel;
@property (nonatomic, strong) UILabel *timerInternalLabel;
@property (nonatomic, strong) DKCircleButton *startStopButton;
@property (nonatomic, strong) DKCircleButton *resetButton;
@property (nonatomic, strong) UILabel *roundsLabel;
@property (nonatomic, strong) UILabel *excersizeLabel;
@property (nonatomic, strong) UIButton *setTimerButton;
@property (nonatomic, strong) NSString *currentTimerConfiguration;
@property (nonatomic, strong) DKProgressView *workProgressView;
@property (nonatomic, strong) UIImage *originalBackgroundImage;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) UIImage *imageToShare;

@property (nonatomic) int currentRound;
@property (nonatomic) int currentExercise;
@property (nonatomic) BOOL isWorkStage;
@property (nonatomic) BOOL isCounting;

@end

@implementation DKTimerViewController

@synthesize currentTimerConfiguration = _currentTimerConfiguration;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CGRect rect = CGRectMake(0, 0, 1, 1);
    // Create a 1 by 1 pixel context
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    
    [ApplicationMainColor setFill];
    
    UIRectFill(rect);   // Fill it with your color
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.originalBackgroundImage = image;
    
    self.navigationController.navigationBar.translucent = YES;
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.timerLabel reset];
    
    [self.view.layer removeAllAnimations];

    [[UIApplication sharedApplication] setIdleTimerDisabled: NO];
    
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController.navigationBar setBackgroundImage:self.originalBackgroundImage forBarMetrics:UIBarMetricsDefault];
}

- (void)dealloc {
    self.timerLabel = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.workProgressView = [[DKProgressView alloc] initWithFrame:self.view.bounds];
    self.workProgressView.progress = 0.0;
    
    [self.view addSubview:self.workProgressView];
    
    // Do any additional setup after loading the view.
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)
                                                  style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 1)];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle  = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.rowHeight = 50;
    self.tableView.showsVerticalScrollIndicator = NO;
    
    [self.view addSubview: self.tableView];
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.contentOffset = CGPointMake(0, 0);
    
    [self.tableView reloadData];
    
    self.timePicker = [[DKTimerSettingsView alloc] initWithFrame:CGRectMake(0, -ScreenHeight, ScreenWidth, ScreenHeight)];
    
    self.timePicker.delegate = self;
    self.timePicker.backgroundColor = ApplicationMainColor;
    
    [self.view addSubview: self.timePicker];
    
    float heightOffset = 50;
    
    if (ScreenHeight > 480) {
        heightOffset += 20;
    }
    
    self.timerView = [[UIView alloc] initWithFrame:CGRectMake(0, ApplicationNavigationAndStatusBarHeight, ScreenWidth, ScreenHeight)];
    
    self.timerView.backgroundColor = [UIColor clearColor];
    
    self.tableView.tableHeaderView = self.timerView;

    self.roundsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, heightOffset, ScreenWidth - 20, 50)];
    
    self.roundsLabel.font = [UIFont fontWithName:ApplicationUltraLightFont size:30];
    self.roundsLabel.textColor = [UIColor whiteColor];
    self.roundsLabel.textAlignment = NSTextAlignmentRight;
    self.roundsLabel.numberOfLines = 1;
    self.roundsLabel.backgroundColor = [UIColor clearColor];
    self.roundsLabel.text = @"Round 0 / 0";
    
    [self.timerView addSubview:self.roundsLabel];
    
    self.excersizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, heightOffset + 40, ScreenWidth - 20, 50)];
    
    self.excersizeLabel.font = [UIFont fontWithName:ApplicationUltraLightFont size:30];
    self.excersizeLabel.textColor = [UIColor whiteColor];
    self.excersizeLabel.textAlignment = NSTextAlignmentRight;
    self.excersizeLabel.numberOfLines = 1;
    self.excersizeLabel.backgroundColor = [UIColor clearColor];
    self.excersizeLabel.text = @"Exercise 0 / 0";
    
    [self.timerView addSubview:self.excersizeLabel];
    
    self.timerInternalLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 110 + heightOffset, ScreenWidth, 90)];
    
    self.timerInternalLabel.font = [UIFont fontWithName:ApplicationUltraLightFont size:80];
    self.timerInternalLabel.textColor = [UIColor whiteColor];
    self.timerInternalLabel.textAlignment = NSTextAlignmentCenter;
    self.timerInternalLabel.numberOfLines = 1;
    self.timerInternalLabel.backgroundColor = [UIColor clearColor];
    
    [self.timerView addSubview:self.timerInternalLabel];
    
    self.timerLabel = [[MZTimerLabel alloc] initWithLabel:self.timerInternalLabel andTimerType:MZTimerLabelTypeTimer];
    
    [self.timerLabel setCountDownTime:0];
    
    self.timerLabel.timeFormat = @"mm:ss SS";
    self.timerLabel.delegate = self;
    self.timerLabel.resetTimerAfterFinish = YES;

    self.startStopButton = [DKCircleButton buttonWithType:UIButtonTypeCustom];
    
    self.startStopButton.frame = CGRectMake(0, 0, 90, 90);
    self.startStopButton.backgroundColor = [UIColor clearColor];
    self.startStopButton.clipsToBounds = YES;
    self.startStopButton.titleLabel.font = [UIFont fontWithName:ApplicationFont size:20];
    
    self.startStopButton.center = CGPointMake((ScreenWidth / 3) - 15, 270 + heightOffset);
    self.startStopButton.layer.borderColor = [UIColor whiteColor].CGColor;
    
    [self.startStopButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.startStopButton setTitle:NSLocalizedString(@"Start", nil) forState:UIControlStateNormal];
    
    [self.startStopButton addTarget:self action:@selector(startStopButtonPressed) forControlEvents:UIControlEventTouchUpInside];

    [self.timerView addSubview:self.startStopButton];

    self.resetButton = [DKCircleButton buttonWithType:UIButtonTypeCustom];
    
    self.resetButton.frame = CGRectMake(0, 0, 90, 90);
    self.resetButton.backgroundColor = [UIColor clearColor];
    self.resetButton.clipsToBounds = YES;
    self.resetButton.titleLabel.font = [UIFont fontWithName:ApplicationFont size:20];

    self.resetButton.center = CGPointMake((ScreenWidth * 2 / 3) + 15, 270 + heightOffset);
    self.resetButton.layer.borderColor = [UIColor whiteColor].CGColor;
    
    [self.resetButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.resetButton setTitle:NSLocalizedString(@"Reset", nil) forState:UIControlStateNormal];
    
    [self.resetButton addTarget:self action:@selector(resetButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [self.timerView addSubview:self.resetButton];
    
    self.setTimerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    self.setTimerButton.backgroundColor = [UIColor clearColor];
    self.setTimerButton.frame = CGRectMake(0, 0, ScreenWidth, 170 + heightOffset * 2);
    self.setTimerButton.titleLabel.font = [UIFont fontWithName:ApplicationFont size:100];
    
    [self.setTimerButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    [self.setTimerButton addTarget:self action:@selector(setTimerButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [self.timerView addSubview:self.setTimerButton];
    
    [self resetUI];
}

- (NSString *)currentTimerConfiguration {
    if (_currentTimerConfiguration == nil) {
        _currentTimerConfiguration = [[NSUserDefaults standardUserDefaults] stringForKey:DKTimerViewControllerLastTimerConfiguration];
        
        if (_currentTimerConfiguration == nil) {
            _currentTimerConfiguration = DKTimerViewControllerDefaultTimerConfiguration;
        }
    }
    
    return _currentTimerConfiguration;
}

- (void)setCurrentTimerConfiguration:(NSString *)currentTimerConfiguration {
    _currentTimerConfiguration = currentTimerConfiguration;
    
    [[NSUserDefaults standardUserDefaults] setObject:currentTimerConfiguration forKey:DKTimerViewControllerLastTimerConfiguration];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.currentRound = 0;
    self.currentExercise = 0;
    
    NSArray *parts = [self.currentTimerConfiguration componentsSeparatedByString:DKTimerPickerPartsSeparator];

    if ([parts[2] isEqualToString:@"01"]) {
        [self.excersizeLabel removeFromSuperview];
    } else {
        [self.timerView addSubview:self.excersizeLabel];
    }

    if ([parts[3] isEqualToString:@"01"]) {
        [self.roundsLabel removeFromSuperview];
    } else {
        [self.timerView addSubview:self.roundsLabel];
    }

    [self.timerLabel setCountDownTime:[self workTimeFromConfiguration]];
}

- (void)setCurrentRound:(int)currentRound {
    
    _currentRound = currentRound;
    NSArray *parts = [self.currentTimerConfiguration componentsSeparatedByString:DKTimerPickerPartsSeparator];

    self.roundsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Round %02d / %@", nil), currentRound + 1, parts[3]];
}

- (void)setCurrentExercise:(int)currentExercise {
    
    _currentExercise = currentExercise;
    NSArray *parts = [self.currentTimerConfiguration componentsSeparatedByString:DKTimerPickerPartsSeparator];
    
    self.excersizeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Exercise %02d / %@", nil), currentExercise + 1, parts[2]];
}

- (void)resetUI {
    
    self.isWorkStage = YES;
    self.isCounting = NO;
    
    self.workProgressView.progress = 0.0;
    
    [self.startStopButton setTitle:NSLocalizedString(@"Start", nil) forState:UIControlStateNormal];

    if ([[NSUserDefaults standardUserDefaults] stringForKey:DKTimerViewControllerLastTimerConfiguration]) {
        self.currentTimerConfiguration = [[NSUserDefaults standardUserDefaults] stringForKey:DKTimerViewControllerLastTimerConfiguration];
    } else {
        self.currentTimerConfiguration = DKTimerViewControllerDefaultTimerConfiguration;
    }
}

- (NSTimeInterval)restTimeFromConfiguration {
    NSArray *parts = [self.currentTimerConfiguration componentsSeparatedByString:DKTimerPickerPartsSeparator];
    
    NSArray *timeParts = [parts[1] componentsSeparatedByString:@":"];
    
    int minutes = [timeParts[0] intValue];
    int seconds = [timeParts[1] intValue];
    
    return minutes * 60 + seconds;
}

- (NSTimeInterval)workTimeFromConfiguration {
    NSArray *parts = [self.currentTimerConfiguration componentsSeparatedByString:DKTimerPickerPartsSeparator];
    NSArray *timeParts = [parts[0] componentsSeparatedByString:@":"];
    
    int minutes = [timeParts[0] intValue];
    int seconds = [timeParts[1] intValue];
    
    return minutes * 60 + seconds;
}

- (void)reloadData {
    [self reloadAllTimers];
    [self.tableView reloadData];
}

- (void)reloadAllTimers {
    
#ifdef FREE
    if ([[DKSettingsManager sharedInstance][kSettingExtendedTimer] boolValue] == NO) {
        return [NSMutableArray new];
    }
#endif
    
    self.items = [DKModel loadAllTimers];
    __weak typeof(self) this = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (this.items.count == 1) {
            [this startCreateNewItemTutorialWithInfo: NSLocalizedString(@"Pull down to set new timer", nil)];
        } else if (this.items.count == 2) {
            [this startTutorialWithInfo:NSLocalizedString(@"Scroll up to see your previous timer settings", nil)
                                atPoint:CGPointMake(ScreenWidth / 2, 150)
           withFingerprintStartingPoint:CGPointMake(ScreenWidth / 2, ScreenHeight - 100)
                            andEndPoint:CGPointMake(ScreenWidth / 2, ScreenHeight - 250)
                   shouldHideBackground:YES];

        }
    });
}

- (BOOL)canSetTimer {
    return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    } else {
        return self.items.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellId = indexPath.section == 0 ? DKTimerViewControllerSection0CellId : DKTimerViewControllerSection1CellId;
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellId];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        
        cell.userInteractionEnabled = YES;
//        cell.selectedBackgroundView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.textLabel.font = [UIFont fontWithName:ApplicationLightFont size:35];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.numberOfLines = 1;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.textAlignment = NSTextAlignmentRight;
        
        cell.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.textLabel.backgroundColor = [UIColor clearColor];
    }
    
    if (indexPath.section == 0) {
        
//        [self.timePicker removeFromSuperview];
//        
//        if (self.timePicker) {
//            [cell.contentView addSubview: self.timePicker];
//        }
        
    } else {
        Timer *timer = self.items[indexPath.row];
        
        cell.textLabel.text = timer.value;
    }
    
    cell.clipsToBounds = YES;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    DKTimer *timer = self.items[indexPath.row];

    self.currentTimerConfiguration = timer.value;
    
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, ScreenWidth, ScreenHeight) animated:YES];
    
    DKTimer *newTimer = [DKTimer new];
    
    newTimer.value = self.currentTimerConfiguration;
    newTimer.creationDate = [NSDate date];

    [self.items removeObjectAtIndex:indexPath.row];
    
    [DKModel deleteObject:timer];
    [DKModel addObject:newTimer];

    [self.items insertObject:timer atIndex:0];
    
    [Flurry logEvent:@"Replaced timer"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 0;
    } else {
        return 80;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 1;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        DKTimer *timer = self.items[indexPath.row];
        
        [self.tableView beginUpdates];
        
        [self.items removeObjectAtIndex:indexPath.row];
        
        [DKModel deleteObject:timer];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)timePicker:(DKTimerSettingsView *)timePicker saveConfiguration:(NSString *)configuration {
    
    BOOL canAddNewTimer = YES;
    
    for (DKTimer *timer in self.items) {
        if ([timer.value isEqualToString:configuration]) {
            canAddNewTimer = NO;
            break;
        }
    }
    
    if (canAddNewTimer && ([configuration isEqualToString:@"00:00 00:00 00 00"] == NO)) {
        DKTimer *timer = [DKTimer new];
        
        timer.value = configuration;
        timer.creationDate = [NSDate date];
        
        [self.items insertObject:timer atIndex:0];

        [DKModel addObject:timer];
    }
    
    __weak typeof(self) this = self;
    
    [UIView animateWithDuration:0.3f delay:0.f options:UIViewAnimationOptionCurveEaseIn animations:^{
        this.tableView.center = CGPointMake(ScreenWidth / 2, ScreenHeight / 2);
        
        this.timePicker.frame = CGRectMake(0, -ScreenHeight, ScreenWidth, ScreenHeight);
        [this.view layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];

    self.currentTimerConfiguration = configuration;
    
    [Flurry logEvent:@"Added timer"];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
        
    if (scrollView.contentOffset.y < -40) {
        
        if ([self.timerLabel counting] == NO) {
            [self setTimerButtonPressed];
        }
    }
    
    if (scrollView.contentOffset.y > 0) {
        float offset = MIN(scrollView.contentOffset.y, 100);
        
        self.timerView.alpha = (1 - offset / 100);
    }
}

- (void)timerLabel:(MZTimerLabel*)timerLabel countingTo:(NSTimeInterval)time timertype:(MZTimerLabelType)timerType {
    
    float initialTime = 0;
    
    if (self.isWorkStage) {
        initialTime = [self workTimeFromConfiguration];
        
        self.workProgressView.progress = (1 - time / initialTime);
    } else {
        initialTime = [self restTimeFromConfiguration];
        
        self.workProgressView.progress = time / initialTime;
    }
}

- (void)timerLabel:(MZTimerLabel*)timerLabel finshedCountDownTimerWithTime:(NSTimeInterval)countTime {
    if (self.isWorkStage) {
        if ([self restTimeFromConfiguration] > 0.0) {
            [self startToRest];
        } else {
            self.workProgressView.progress = 0.0;
            
            [self startNextExercise];
        }
    } else {
        
        [self startNextExercise];
    }
}

- (void)rateApp {
    NSURL *appStoreUrl = [NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@", AppStoreApplicationId]];
    [[UIApplication sharedApplication] openURL:appStoreUrl];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    
    if (buttonIndex == 1) {
        NSTimeInterval workTime = [self workTimeFromConfiguration];
        NSTimeInterval restTime = [self restTimeFromConfiguration];
        
        NSArray *parts = [self.currentTimerConfiguration componentsSeparatedByString:DKTimerPickerPartsSeparator];
        
        if (restTime > 0.0) {
            workTime += restTime;
        }
        
        workTime *= [parts[2] integerValue] * [parts[3] integerValue];
        
        int minutes = workTime / 60;
        int seconds = workTime - (minutes * 60);
        
        NSURL *appStoreUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/app/id%@", AppStoreApplicationId]];
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"I've just completed workout (%02d:%02d) with #fita!\n\n%@", nil),
                             minutes, seconds, appStoreUrl];
        NSString *appIconName = @"BigAppImage";
        UIImage *appIcon = self.imageToShare ? [UIImage imageNamed:appIconName] : [UIImage imageNamed:appIconName];
        
        NSArray *activityItems = appIcon ? @[message, appIcon] : @[message];
        
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                                 applicationActivities:nil];
        
        activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePrint, UIActivityTypePostToWeibo,
                                             UIActivityTypeAddToReadingList, UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo];
        
        [activityVC setValue:[NSString stringWithFormat:NSLocalizedString(@"Total workout time: %02d:%02d", nil), minutes, seconds] forKey:@"subject"];

        [self presentViewController:activityVC animated:TRUE completion:nil];
    } else {
        [self rateApp];
    }
}

- (void)finishWorkout {
    NSTimeInterval workTime = [self workTimeFromConfiguration];
    NSTimeInterval restTime = [self restTimeFromConfiguration];

    NSArray *parts = [self.currentTimerConfiguration componentsSeparatedByString:DKTimerPickerPartsSeparator];
    
    if (restTime > 0.0) {
        workTime += restTime;
    }
    
    workTime *= [parts[2] integerValue] * [parts[3] integerValue];
    
    int minutes = workTime / 60;
    int seconds = workTime - (minutes * 60);
    
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Total workout time: %02d:%02d", nil), minutes, seconds];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Done!", nil) message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: NSLocalizedString(@"Share", nil), NSLocalizedString(@"Rate the app", nil), nil];
    
    alertView.delegate = self;
    
    [alertView show];
    
    [self playComplete];
    
    int64_t delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [self playComplete];
        
        [[UIApplication sharedApplication] setIdleTimerDisabled: NO];
    });
    
    [self resetUI];
    
    self.title = NSLocalizedString(@"Timer", nil);
}

- (void)startToRest {
    // Start rest stage
    self.isWorkStage = NO;
    
    __weak typeof(self) this = self;
    
    [self playFinishWork];
    
    int64_t delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [this.timerLabel reset];
        [this.timerLabel setCountDownTime:[this restTimeFromConfiguration]];
        [this.timerLabel start];
    });
}

- (void)startNextExercise {
    // Start rest stage
    self.isWorkStage = YES;
    
    self.currentExercise++;
    
    NSArray *parts = [self.currentTimerConfiguration componentsSeparatedByString:DKTimerPickerPartsSeparator];

    if (self.currentExercise < [parts[2] integerValue]) {
        __weak typeof(self) this = self;
        
        [self playDoubleBeep];
        
        int64_t delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [this.timerLabel reset];
            [this.timerLabel setCountDownTime:[this workTimeFromConfiguration]];
            [this.timerLabel start];
        });
    } else {
        [self startNextRound];
    }
}

- (void)startNextRound {
    self.currentExercise = 0;

    self.currentRound ++;
    
    NSArray *parts = [self.currentTimerConfiguration componentsSeparatedByString:DKTimerPickerPartsSeparator];
    
    if (self.currentRound < [parts[3] integerValue]) {
        __weak typeof(self) this = self;
        
        [self playBeep];
        
        int64_t delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            [this.timerLabel reset];
            [this.timerLabel setCountDownTime:[this workTimeFromConfiguration]];
            [this.timerLabel start];
        });
    } else {
        [self finishWorkout];
    }
}

- (void)startStopButtonPressed {
    [self didTapItem: self.startStopButton];
    
    if ([self.timerLabel counting]) {
        [self.timerLabel pause];
        [self.startStopButton setTitle:NSLocalizedString(@"Resume", nil) forState:UIControlStateNormal];
    } else {
        
        if (self.isCounting == NO) {
            [self.timerLabel reset];

            if (self.isWorkStage) {
                self.title = NSLocalizedString(@"Work", nil);
                
                [self.timerLabel setCountDownTime:[self workTimeFromConfiguration]];
            } else {
                [self.timerLabel setCountDownTime:[self restTimeFromConfiguration]];
            }
            
            __weak typeof(self) this = self;
            
            self.setTimerButton.backgroundColor = ApplicationMainColor;
            self.setTimerButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
            
            self.roundsLabel.alpha = 0.0;
            self.excersizeLabel.alpha = 0.0;
            self.timerInternalLabel.alpha = 0.0;
            self.startStopButton.alpha = 0.0;
            self.resetButton.alpha = 0.0;
            
            float scaleFactor = 3;
            
            self.navigationItem.backBarButtonItem.enabled = NO;
            
            [this.setTimerButton setTitle:@"3" forState:UIControlStateNormal];
            
            [self playBeep];
            
            [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                
                this.setTimerButton.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
                this.setTimerButton.alpha = 0.01;
                
            } completion:^(BOOL finished) {
                
                if (finished == NO) {
                    return;
                }
                
                this.setTimerButton.alpha = 0.0;
                this.setTimerButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
                this.setTimerButton.alpha = 1.0;
                
                [this.setTimerButton setTitle:@"2" forState:UIControlStateNormal];

                [this playBeep];

                [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{

                    this.setTimerButton.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
                    this.setTimerButton.alpha = 0.01;
                
                } completion:^(BOOL finished) {
                    
                    if (finished == NO) {
                        return;
                    }
                    
                    this.setTimerButton.alpha = 0.0;
                    this.setTimerButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
                    this.setTimerButton.alpha = 1.0;
                    
                    [this.setTimerButton setTitle:@"1" forState:UIControlStateNormal];
                    
                    [this playBeep];

                    [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                        
                        this.setTimerButton.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
                        this.setTimerButton.alpha = 0.01;
                        
                    } completion:^(BOOL finished) {
                        
                        if (finished == NO) {
                            return;
                        }
                        
                        [this.setTimerButton setTitle:@"" forState:UIControlStateNormal];

                        this.setTimerButton.alpha = 1.0;
                        this.setTimerButton.backgroundColor = [UIColor clearColor];
                        
                        [this playBeepStart];

                        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{

                            this.setTimerButton.transform = CGAffineTransformIdentity;

                            this.roundsLabel.alpha = 1.0;
                            this.excersizeLabel.alpha = 1.0;
                            this.timerInternalLabel.alpha = 1.0;
                            this.startStopButton.alpha = 1.0;
                            this.resetButton.alpha = 1.0;

                        } completion:^(BOOL finished) {
                            [this playStartWork];
                            
                            this.navigationItem.backBarButtonItem.enabled = YES;

                            int64_t delayInSeconds = 1.2;
                            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                                
                                [this.timerLabel reset];
                                
                                if (this.isWorkStage) {
                                    [this.timerLabel setCountDownTime:[this workTimeFromConfiguration]];
                                } else {
                                    [this.timerLabel setCountDownTime:[this restTimeFromConfiguration]];
                                }

                                [this.timerLabel start];
                                
                                int64_t delayInSeconds = 1;
                                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                                    UIView *viewToSnapshot = [UIApplication sharedApplication].keyWindow;

                                    this.imageToShare = [viewToSnapshot screenshotFast];
                                });
                            });
                        }];
                    }];
                }];
            }];
        } else {
            [self.timerLabel start];
        }
        
        [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
        [self.startStopButton setTitle:NSLocalizedString(@"Pause", nil) forState:UIControlStateNormal];
    }
    
    self.isCounting = YES;
}

- (void)resetButtonPressed {
    [self didTapItem: self.resetButton];
    
    if ([self.timerLabel counting]) {
        [self.timerLabel pause];
    }
    
    [self.timerLabel reset];
    [self resetUI];
    
    self.title = NSLocalizedString(@"Timer", nil);
}

- (void)setTimerButtonPressed {

    if ([self.timerLabel counting]) {
        return;
    }
    
    [self resetUI];
    
    self.title = NSLocalizedString(@"Timer", nil);
    
    self.timePicker.configuration = self.currentTimerConfiguration;
    
    __weak typeof(self) this = self;
    
    [UIView animateWithDuration:0.3f delay:0.f options:UIViewAnimationOptionCurveEaseIn animations:^{
        this.tableView.center = CGPointMake(ScreenWidth / 2, ScreenHeight + self.tableView.frame.size.height / 2);
        this.timePicker.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
        
        [this.view layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
}

- (void)didTapItem:(UIView *)view {
    
    CGRect pathFrame = CGRectMake(-CGRectGetMidX(view.bounds), -CGRectGetMidY(view.bounds), view.bounds.size.width, view.bounds.size.height);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:pathFrame cornerRadius:view.layer.cornerRadius];
    
    // accounts for left/right offset and contentOffset of scroll view
    CGPoint shapePosition = [self.view convertPoint:view.center fromView:self.timerView];
    
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

- (void)playStartWork {
//    [self playSound:@"/System/Library/Audio/UISounds/begin_record.caf" withVibro:YES]; // see list below
}

- (void)playFinishWork {
    [self playBeepEnd];
    
//    [self playSound:@"/System/Library/Audio/UISounds/begin_record.caf" withVibro:YES]; // see list below
}

- (void)playFinishRest {
    [self playBeep];
//    [self playSound:@"/System/Library/Audio/UISounds/Modern/sms_alert_complete.caf" withVibro:YES]; // see list below
}

- (void)playComplete {
    [self playAudio:@"/System/Library/Audio/UISounds/Modern/sms_alert_popcorn.caf" withVibro:YES];
}

- (void)playBeep {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"wav"];

    [self playAudio:path withVibro:NO];
}

- (void)playDoubleBeep {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"double_beep" ofType:@"wav"];
    
    [self playAudio:path withVibro:NO];
}

- (void)playBeepEnd {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"start_beep" ofType:@"wav"];
    
    [self playAudio:path withVibro:NO];
}

- (void)playBeepStart {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"start_beep" ofType:@"wav"];
    
    [self playAudio:path withVibro:NO];
}

- (void)playAudio:(NSString *)audioFile withVibro:(BOOL)vibro {
    
    if (self.player) {
        [self.player stop];
    }
    
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:audioFile] error:nil];
    
    [self.player play];
    
    if (vibro) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

- (void)playSound: (NSString *)soundAtFile withVibro:(BOOL)vibro {
    
    if (vibro) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
    NSURL *fileURL = [NSURL URLWithString:soundAtFile];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge_retained CFURLRef)fileURL, &soundID);
    AudioServicesPlaySystemSound(soundID);

    int64_t delayInSeconds = 0.7;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {

        if (vibro) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        }
//        SystemSoundID soundID;
//        AudioServicesCreateSystemSoundID((__bridge_retained CFURLRef)fileURL, &soundID);
//        AudioServicesPlaySystemSound(soundID);

    });
}

- (void)setIsCounting:(BOOL)isCounting {
    _isCounting = isCounting;
    
    self.tableView.scrollEnabled = !isCounting;
}

- (void)setIsWorkStage:(BOOL)isWorkStage {
    _isWorkStage = isWorkStage;
    
    if (isWorkStage) {
        self.title = NSLocalizedString(@"Work", nil);
    } else {
        self.title = NSLocalizedString(@"Rest", nil);
    }
}

#ifdef FREE

- (void)updateAdBannerPosition {
    
    self.tableView.tableFooterView = [UIView new];
    
    [self.adBanner removeFromSuperview];
    
    __weak typeof(self) this = self;
    
    [UIView animateWithDuration:0.5 animations:^{
        this.adBanner.alpha = 0.0;
    } completion:^(BOOL finished) {
        this.adBanner.center = CGPointMake(ScreenWidth / 2, this.timerView.frame.size.height - this.adBanner.frame.size.height / 2);
        [this.timerView addSubview:this.adBanner];
        
        [UIView animateWithDuration:0.5 animations:^{
            this.adBanner.alpha = 1.0;
        }];
    }];
}

- (void)openPurchases {
    DKPurchaseViewController *viewController = [[DKPurchaseViewController alloc] init];
    
    [self.navigationController pushViewController:viewController animated:YES];
}

#endif

@end
