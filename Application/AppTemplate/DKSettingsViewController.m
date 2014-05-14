//
//  DKSettingsViewController.m
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 7/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKSettingsViewController.h"
#import "DKTableViewCell.h"
#import "DKFileCache.h"
#import "DKSettingsManager.h"
#import "Meal.h"
#import "Week.h"
#import "Day.h"
#import "DKSwitchMenuCell.h"
#import "DKStepMenuCell.h"
#import "DKBaseMenuCell.h"
#import "DKAppColorViewController.h"

#ifdef FREE
#import "DKPurchaseViewController.h"
#endif

#import "NIKFontAwesomeIconFactory.h"
#import "NIKFontAwesomeIconFactory+iOS.h"
#import "Flurry.h"
#import "FRDLivelyButton.h"
#import "PBWebViewController.h"
#import <MessageUI/MessageUI.h>

#define DKSettingsViewControllerIntCellId @"DKSettingsViewControllerIntCellId"
#define DKSettingsViewControllerBoolCellId @"DKSettingsViewControllerBoolCellId"
#define DKSettingsViewControllerCellId @"DKSettingsViewControllerCellId"
#define DKSettingsViewControllerColorCellId @"DKSettingsViewControllerColorCellId"
#define DKSettingsViewControllerPurchaseCellId @"DKSettingsViewControllerPurchaseCellId"

#define kSettingsWeekKeyType      DKSettingsViewControllerIntCellId
#define kSettingsRemindersKeyType DKSettingsViewControllerBoolCellId
#define kSettingsColorKeyType     DKSettingsViewControllerColorCellId

@interface DKSettingsViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate,
                                        UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NSArray *sectionOneItems;
@property (nonatomic, strong) NSArray *sectionTwoItems;
@property (nonatomic, strong) UIViewController *messageViewController;

@end

@implementation DKSettingsViewController

@synthesize sectionTwoItems = _sectionTwoItems;
@synthesize sectionOneItems = _sectionOneItems;
@synthesize messageViewController = _messageViewController;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = NSLocalizedString(@"Settings", nil);
    
    self.sectionOneItems = @[@{@"text": NSLocalizedString(@"Reminders", nil),
                               @"key": kSettingsRemindersKey,
                               @"type": kSettingsRemindersKeyType,
                               @"format": NSLocalizedString(@"Reminders", nil)},
                             
                             @{@"text": NSLocalizedString(@"Start from week %d", nil),
                               @"key": kSettingsWeekKey,
                               @"type": kSettingsWeekKeyType,
                               @"format": NSLocalizedString(@"Start from week %d", nil)},
                             
                             @{@"text": NSLocalizedString(@"Application color", nil),
                               @"key": kSettingApplicationColor,
                               @"type": kSettingsColorKeyType,
                               @"format": NSLocalizedString(@"Application color", nil)},
#ifdef FREE
                             @{@"text": NSLocalizedString(@"Purchases", nil),
                               @"key": @"",
                               @"type": @"",
                               @"format": NSLocalizedString(@"Purchases", nil)},
#endif
                             ];

    
    self.sectionTwoItems = @[NSLocalizedString(@"Reset all data", nil),
                             NSLocalizedString(@"Rate the app", nil),
                             NSLocalizedString(@"Share", nil),
                             NSLocalizedString(@"Send feedback", nil)];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0,
                                                                   ScreenWidth,
                                                                   ScreenHeight - ApplicationNavigationAndStatusBarHeight)
                                                  style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = ApplicationMainColor;
    
    [self.view addSubview: self.tableView];
        
//    FRDLivelyButton *button = [[FRDLivelyButton alloc] initWithFrame:CGRectMake(0,0,20,20)];
//    
//    [button setOptions:@{ kFRDLivelyButtonLineWidth: @(2.0f),
//                          kFRDLivelyButtonHighlightedColor: [UIColor whiteColor],
//                          kFRDLivelyButtonColor: [UIColor whiteColor] }];
//    
//    [button setStyle:kFRDLivelyButtonStyleClose animated:NO];
//    [button addTarget:self action:@selector(onCloseButtonTap) forControlEvents:UIControlEventTouchUpInside];
//    
//    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
//    self.navigationItem.rightBarButtonItem = buttonItem;
}

- (void)onCloseButtonTap {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
    [super viewWillAppear:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? self.sectionOneItems.count : self.sectionTwoItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        
        NSString *cellId = self.sectionOneItems[indexPath.row][@"type"];
        DKBaseMenuCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellId];
        
        if (cell == nil) {
            if ([cellId isEqualToString:DKSettingsViewControllerBoolCellId]) {
                cell = [[DKSwitchMenuCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
            } else if ([cellId isEqualToString:DKSettingsViewControllerIntCellId]) {
                cell = [[DKStepMenuCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
            } else if ([cellId isEqualToString:DKSettingsViewControllerColorCellId]) {
                cell = [[DKBaseMenuCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
                
                FRDLivelyButton *button = [[FRDLivelyButton alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
                
                [button setOptions:@{ kFRDLivelyButtonLineWidth: @(2.0f),
                                      kFRDLivelyButtonHighlightedColor: [UIColor colorWithRed:0.5 green:0.8 blue:1.0 alpha:1.0],
                                      kFRDLivelyButtonColor: [UIColor whiteColor]
                                      }];

                [button setStyle:kFRDLivelyButtonStyleCaretRight animated:YES];
                
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.accessoryView = button;
            } else {
                cell = [[DKBaseMenuCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
                
                FRDLivelyButton *button = [[FRDLivelyButton alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
                
                [button setOptions:@{ kFRDLivelyButtonLineWidth: @(2.0f),
                                      kFRDLivelyButtonHighlightedColor: [UIColor colorWithRed:0.5 green:0.8 blue:1.0 alpha:1.0],
                                      kFRDLivelyButtonColor: [UIColor whiteColor]
                                      }];
                
                [button setStyle:kFRDLivelyButtonStyleCaretRight animated:YES];
                
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.accessoryView = button;
            }
        }
        
        cell.imageView.image = nil;
        cell.textLabel.text = self.sectionOneItems[indexPath.row][@"text"];
        cell.valueFormat = self.sectionOneItems[indexPath.row][@"format"];
        cell.settingKey = self.sectionOneItems[indexPath.row][@"key"];
        cell.backgroundColor = ApplicationMainColor;

        return cell;

    } else {
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:DKSettingsViewControllerCellId];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DKSettingsViewControllerCellId];
            
            cell.userInteractionEnabled = YES;
            cell.selectedBackgroundView = nil;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.textLabel.font = [UIFont fontWithName:ApplicationFont size:20];
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.textLabel.numberOfLines = 1;
            cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
            
            cell.backgroundColor = [UIColor clearColor];
            cell.contentView.backgroundColor = [UIColor clearColor];
            cell.textLabel.backgroundColor = [UIColor clearColor];
        }
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory barButtonItemIconFactory];
        
        factory.colors = @[[UIColor whiteColor]];
        
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.imageView.image = nil;
        cell.textLabel.text = self.sectionTwoItems[indexPath.row];
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
 
    if (indexPath.section == 0) {
        if ([self.sectionOneItems[indexPath.row][@"text"] isEqualToString:NSLocalizedString(@"Application color", nil)]) {
            [self changeAppColor];
        } else if ([self.sectionOneItems[indexPath.row][@"text"] isEqualToString:NSLocalizedString(@"Purchases", nil)]) {
#ifdef FREE
            [self openPurchases];
#endif
        }
        
    } else {
        PBWebViewController *viewController = [[PBWebViewController alloc] init];

        viewController.title = self.sectionTwoItems[indexPath.row];

        switch (indexPath.row) {
            case 0:
                [self resetAllDataRequest];
                break;
            case 1:
                [self rateApp];
                break;
            case 2:
                [self share];
            case 3:
                [self sendFeedback];
            default:
                break;
        }
    }
}

#ifdef FREE

- (void) openPurchases {
    [Flurry logEvent:@"Open purchases"];

    DKPurchaseViewController *viewController = [[DKPurchaseViewController alloc] init];
    
    [self.navigationController pushViewController:viewController animated:YES];
}

#endif

- (void)changeAppColor {
    DKAppColorViewController *viewController = [[DKAppColorViewController alloc] init];
    
    viewController.title = NSLocalizedString(@"Application color", nil);
    
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)share {
    [Flurry logEvent:@"Share about"];
    
    NSURL *appStoreUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/app/id%@", AppStoreApplicationId]];
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Hi,\n\nCheck out FitA - my new personal fitness assistant app!\n\n%@", nil),
                         appStoreUrl];
    NSString *appIconName = @"BigAppImage";
    UIImage *appIcon = [UIImage imageNamed:appIconName];
    NSArray *activityItems = @[message, appIcon];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                             applicationActivities:nil];
    
    activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePrint,
                                         UIActivityTypePostToWeibo, UIActivityTypeCopyToPasteboard,
                                         UIActivityTypeAddToReadingList, UIActivityTypePostToVimeo,
                                         UIActivityTypePostToTencentWeibo, UIActivityTypeSaveToCameraRoll,
                                         UIActivityTypeAirDrop];
    
    [self presentViewController:activityVC animated:TRUE completion:nil];
}

- (void)sendFeedback {
    MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
    
    controller.subject = NSLocalizedString(@"App feedback", nil);
    controller.mailComposeDelegate = self;
    
    [controller setToRecipients:[NSArray arrayWithObject:@"dmitry.klimkin@gmail.com"]];
    
    [controller setMessageBody:@"" isHTML:NO];
    
    self.messageViewController = controller;
    
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self.messageViewController dismissViewControllerAnimated:YES completion:NULL];
    
    self.messageViewController = nil;
}

- (void)rateApp {
    NSURL *appStoreUrl = [NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@", AppStoreApplicationId]];
    [[UIApplication sharedApplication] openURL:appStoreUrl];
}

- (void)resetAllDataRequest {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"Do you really want to reset all data?", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"No", nil)
                                              otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    
    [self resetAllData];
}

- (void)resetAllData {

    [Week MR_truncateAll];
    [Day  MR_truncateAll];
    [Meal MR_truncateAll];
    
    [[DKFileCache sharedInstance] clear];
    
    [self showCompleteIndicatorWithTitle:NSLocalizedString(@"Done!", nil)];
    
    __weak typeof(self) this = self;
    
    int64_t delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [this.navigationController popViewControllerAnimated:YES];
    });
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];    
}

#ifdef FREE

- (void)updateAdBannerPosition {
    
    __weak typeof(self) this = self;
    
    [UIView animateWithDuration:0.5 animations:^{
        this.adBanner.alpha = 0.0;
    } completion:^(BOOL finished) {
        this.tableView.tableHeaderView = self.adBanner;
        
        [UIView animateWithDuration:0.5 animations:^{
            this.adBanner.alpha = 1.0;
        }];
    }];
}
#endif

@end
