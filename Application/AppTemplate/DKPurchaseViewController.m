//
//  PurchaseViewController.m
//  beanstalk
//
//  Created by dima on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DKPurchaseViewController.h"
#import "DKStoreManager.h"
#import "DKSettingsManager.h"
#import "UIColor+Colours.h"
#import "UIColor+MLPFlatColors.h"
#import "NIKFontAwesomeIconFactory.h"
#import "NIKFontAwesomeIconFactory+iOS.h"

// Default cell button size
#define BUTTON_SIZE 250

@interface DKPurchaseViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *menuItems;
@property (strong, nonatomic) NSMutableDictionary *purchaseResults;

@end

@implementation DKPurchaseViewController

@synthesize tableView = _tableView;
@synthesize menuItems = _menuItems;
@synthesize purchaseResults = _purchaseResults;

- (NSArray*)menuItems {
    if (_menuItems == nil) {
        SKProduct *timerUnlock = [[DKStoreManager sharedInstance] getProductTimerUnlock];
        SKProduct *mealListUnlock = [[DKStoreManager sharedInstance] getProductMealListUnlock];
        SKProduct *noAdvUnlock = [[DKStoreManager sharedInstance] getProductNoAdvUnlock];
        SKProduct *cumulativeUnlock = [[DKStoreManager sharedInstance] getProductCumulativeUnlock];
        SKProduct *supportLevel1 = [[DKStoreManager sharedInstance] getProductSupportLevel1];
        SKProduct *supportLevel2 = [[DKStoreManager sharedInstance] getProductSupportLevel2];
        SKProduct *supportLevel3 = [[DKStoreManager sharedInstance] getProductSupportLevel3];
        SKProduct *themesUnlock = [[DKStoreManager sharedInstance] getProductThemesUnlock];

        NSString *localizedTimerPrice = [self priceAsString:timerUnlock.priceLocale Price:timerUnlock.price];
        NSString *localizedMealListPrice = [self priceAsString:mealListUnlock.priceLocale Price:mealListUnlock.price];
        NSString *localizedNoAdvPrice = [self priceAsString:noAdvUnlock.priceLocale Price:noAdvUnlock.price];
        NSString *localizedCumulativePrice = [self priceAsString:cumulativeUnlock.priceLocale Price:cumulativeUnlock.price];
        NSString *localizedLevel1Price = [self priceAsString:supportLevel1.priceLocale Price:supportLevel1.price];
        NSString *localizedLevel2Price = [self priceAsString:supportLevel2.priceLocale Price:supportLevel2.price];
        NSString *localizedLevel3Price = [self priceAsString:supportLevel3.priceLocale Price:supportLevel3.price];
        NSString *localizedThemesPrice = [self priceAsString:themesUnlock.priceLocale Price:themesUnlock.price];

        if (localizedThemesPrice == nil) {
            localizedThemesPrice = @"$0.99";
        }

        if (localizedTimerPrice == nil) {
            localizedTimerPrice = @"$0.99";
        }
        
        if (localizedMealListPrice == nil) {
            localizedMealListPrice = @"$0.99";
        }
        
        if (localizedNoAdvPrice == nil) {
            localizedNoAdvPrice = @"$0.99";
        }
        
        if (localizedCumulativePrice == nil) {
            localizedCumulativePrice = @"$1.99";
        }

        if (localizedLevel1Price == nil) {
            localizedLevel1Price = @"$0.99";
        }

        if (localizedLevel2Price == nil) {
            localizedLevel2Price = @"$2.99";
        }

        if (localizedLevel3Price == nil) {
            localizedLevel3Price = @"$4.99";
        }

//        _menuItems = @[[NSString stringWithFormat: @"%@ %@", NSLocalizedString(@"Extended timer", nil), localizedTimerPrice],
//                       [NSString stringWithFormat: @"%@ %@", NSLocalizedString(@"Unlimited meal list", nil), localizedMealListPrice],
//                       [NSString stringWithFormat: @"%@ %@", NSLocalizedString(@"No more Ad", nil), localizedNoAdvPrice],
//                       [NSString stringWithFormat: @"%@ %@", NSLocalizedString(@"All in one", nil), localizedCumulativePrice],
//                       [NSString stringWithFormat: @"%@ %@", NSLocalizedString(@"Donate FitA", nil), localizedLevel1Price],
//                       [NSString stringWithFormat: @"%@ %@", NSLocalizedString(@"Donate FitA", nil), localizedLevel2Price],
//                       [NSString stringWithFormat: @"%@ %@", NSLocalizedString(@"Donate FitA", nil), localizedLevel3Price],
//                       NSLocalizedString(@"Restore", nil)];
        
        _menuItems = @[[NSString stringWithFormat: @"%@ %@", NSLocalizedString(@"Extended timer", nil), localizedTimerPrice],
                       [NSString stringWithFormat: @"%@ %@", NSLocalizedString(@"App themes", nil), localizedThemesPrice],
                       [NSString stringWithFormat: @"%@ %@", NSLocalizedString(@"No more Ad", nil), localizedNoAdvPrice],
                       [NSString stringWithFormat: @"%@ %@", NSLocalizedString(@"Full app unlock", nil), localizedCumulativePrice],
                       [NSString stringWithFormat: @"%@ %@", NSLocalizedString(@"Donate FitA", nil), localizedLevel1Price],
                       [NSString stringWithFormat: @"%@ %@", NSLocalizedString(@"Donate FitA", nil), localizedLevel2Price],
                       [NSString stringWithFormat: @"%@ %@", NSLocalizedString(@"Donate FitA", nil), localizedLevel3Price],
                       NSLocalizedString(@"Restore", nil)];
    }
    return  _menuItems;
}

- (void)viewDidLoad {

    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 30)];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0,
                                                                   self.view.frame.size.width,
                                                                   self.view.frame.size.height - self.navigationController.navigationBar.frame.size.height)
                                                  style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = footerView;
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = ApplicationMainColor;
    self.tableView.separatorColor = [UIColor clearColor];
    
    [self.view addSubview:self.tableView];
    
    self.title = NSLocalizedString(@"Purchases", nil);

    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.menuItems.count;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kCellID = @"PurchaseCellID";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];

	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID];
        
        cell.accessoryType = UITableViewCellAccessoryNone;        
        cell.textLabel.highlightedTextColor = [UIColor grayColor];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.userInteractionEnabled = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.textLabel.font = [UIFont fontWithName:ApplicationFont size:20.0f];
	}
    
//    switch (indexPath.row) {
//        case 0:
//        case 1:
//        case 2:
//        case 4:
//        case 5:
//        case 6:
//            cell.textLabel.font = [UIFont fontWithName:ApplicationFont size:20.0f];
//            break;
//            
//        case 3:
//        case 7:
//            cell.textLabel.font = [UIFont fontWithName:ApplicationFont size:26.0f];
//            break;
//            
//        default:
//            break;
//    }
    
    cell.textLabel.text = self.menuItems[indexPath.row];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    
    paragraphStyle.alignment = NSTextAlignmentLeft;
    
    NSDictionary *attrsDictionary = @{ NSFontAttributeName: [UIFont fontWithName:ApplicationFont size:22],
                                       NSParagraphStyleAttributeName: paragraphStyle,
                                       NSForegroundColorAttributeName: [UIColor whiteColor],
                                       NSUnderlineStyleAttributeName: @(0)
                                       };

    cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:self.menuItems[indexPath.row] attributes:attrsDictionary];
    
    NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory generalFactory];
    
    factory.colors = @[[UIColor whiteColor]];
    factory.size = 30;
    
    UIImage *menuImage = nil;
    
    switch (indexPath.row) {
        case 0:
            menuImage = [factory createImageForIcon:NIKFontAwesomeIconTime];
            break;
        case 1:
            menuImage = [factory createImageForIcon:NIKFontAwesomeIconMagic];
            break;
//        case 1:
//            menuImage = [factory createImageForIcon:NIKFontAwesomeIconCoffee];
//            break;
        case 2:
            menuImage = [factory createImageForIcon:NIKFontAwesomeIconOkCircle];
            break;
        case 3:
            menuImage = [factory createImageForIcon:NIKFontAwesomeIconGift];
            break;
        case 4:
            menuImage = [factory createImageForIcon:NIKFontAwesomeIconThumbsUp];
            break;
        case 5:
            menuImage = [factory createImageForIcon:NIKFontAwesomeIconHeartEmpty];
            break;
        case 6:
            menuImage = [factory createImageForIcon:NIKFontAwesomeIconMoney];
            break;
        case 7:
            menuImage = [factory createImageForIcon:NIKFontAwesomeIconCloudDownload];
            break;
            
        default:
            break;
    }
    
    cell.imageView.image = menuImage;

	return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0:
            [self purchaseTimerItem];
            break;
            
        case 1:
            [self purchaseThemesItem];
            break;
            
        case 2:
            [self purchaseNoAdvItem];
            break;
            
        case 3:
            [self purchaseCumulativeItem];
            break;
            
        case 4:
            [self purchaseSupportLevel1Item];
            break;

        case 5:
            [self purchaseSupportLevel2Item];
            break;

        case 6:
            [self purchaseSupportLevel3Item];
            break;

        case 7:
            [self restoreItems];
            break;
            
        default:
            break;
    }
}

- (void)checkPurchaseResults {    
    BOOL allRequestFailed = YES;
    
    for (NSString *key in self.purchaseResults.keyEnumerator) {
        if ([self.purchaseResults [key] integerValue] == 0) {
            return;
        }
        
        if ([self.purchaseResults [key] integerValue] == 1) {
            allRequestFailed = NO;
        }
    }
    
    [self hideIndicator];

    if (allRequestFailed == NO) {
        [self showCompleteIndicatorWithTitle:NSLocalizedString(@"Success!", nil)];

        __weak typeof(self) this = self;
        
        int64_t delayInSeconds = 1.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            [this.navigationController popViewControllerAnimated:YES];
        });

    } else {
        [self showErrorIndicatorWithTitle:NSLocalizedString(@"Operation failed!", nil)];
    }
}

- (void)restoreItems {
    [Flurry logEvent:@"TapOnRestoreUnlock"];

    SKProduct *themesUnlock = [[DKStoreManager sharedInstance] getProductThemesUnlock];
    SKProduct *timerUnlock = [[DKStoreManager sharedInstance] getProductTimerUnlock];
//    SKProduct *mealListUnlock = [[DKStoreManager sharedInstance] getProductMealListUnlock];
    SKProduct *noAdvUnlock = [[DKStoreManager sharedInstance] getProductNoAdvUnlock];
    SKProduct *cumulativeUnlock = [[DKStoreManager sharedInstance] getProductCumulativeUnlock];
    
    if ((timerUnlock == nil) || (noAdvUnlock == nil) ||
        (cumulativeUnlock == nil) || (themesUnlock == nil)) {
        
        [self showErrorIndicatorWithTitle:NSLocalizedString(@"Operation failed!", nil)];
        return;
    }

//    if ((noAdvUnlock == nil) || (themesUnlock == nil)) {
//        
//        [self showErrorIndicatorWithTitle:NSLocalizedString(@"Operation failed!", nil)];
//        return;
//    }

    [self showBigBusyIndicatorWithTitle:NSLocalizedString(@"Loading...", nil)];

//    _purchaseResults = [@{noAdvUnlock.productIdentifier : @(0),
//                          themesUnlock.productIdentifier : @(0)} mutableCopy];

    _purchaseResults = [@{timerUnlock.productIdentifier : @(0),
                          noAdvUnlock.productIdentifier : @(0),
                          themesUnlock.productIdentifier : @(0),
                          cumulativeUnlock.productIdentifier : @(0)} mutableCopy];

    __weak typeof(self) this = self;

    [[DKStoreManager sharedInstance] restorePreviousPurchasesForProduct:themesUnlock
                                                               response:^(BOOL wasSuccess, SKPaymentTransaction *transaction) {
                                                                   @synchronized (this) {
                                                                       this.purchaseResults [themesUnlock.productIdentifier] = @(wasSuccess ? 1 : 2);
                                                                       [this checkPurchaseResults];
                                                                   }
                                                               }];

    [[DKStoreManager sharedInstance] restorePreviousPurchasesForProduct:timerUnlock
                                                               response:^(BOOL wasSuccess, SKPaymentTransaction *transaction) {
                                                                   @synchronized (this) {
                                                                       this.purchaseResults [timerUnlock.productIdentifier] = @(wasSuccess ? 1 : 2);
                                                                       [this checkPurchaseResults];
                                                                   }
                                                               }];
//
//    [[DKStoreManager sharedInstance] restorePreviousPurchasesForProduct:timerUnlock
//                                                               response:^(BOOL wasSuccess, SKPaymentTransaction *transaction) {
//                                                                   @synchronized (this) {
//                                                                       this.purchaseResults [timerUnlock.productIdentifier] = @(wasSuccess ? 1 : 2);
//                                                                       [this checkPurchaseResults];
//                                                                   }
//                                                               }];
//    
//    [[DKStoreManager sharedInstance] restorePreviousPurchasesForProduct:mealListUnlock
//                                                                   response:^(BOOL wasSuccess, SKPaymentTransaction *transaction) {
//                                                                       @synchronized (this) {
//                                                                           this.purchaseResults [mealListUnlock.productIdentifier] = @(wasSuccess ? 1 : 2);
//                                                                           [this checkPurchaseResults];
//                                                                       }
//                                                                   }];
    
    [[DKStoreManager sharedInstance] restorePreviousPurchasesForProduct:noAdvUnlock
                                                                   response:^(BOOL wasSuccess, SKPaymentTransaction *transaction) {
                                                                       @synchronized (this) {
                                                                           this.purchaseResults [noAdvUnlock.productIdentifier] = @(wasSuccess ? 1 : 2);
                                                                           [this checkPurchaseResults];
                                                                       }
                                                                   }];
    
    [[DKStoreManager sharedInstance] restorePreviousPurchasesForProduct:cumulativeUnlock
                                                                   response:^(BOOL wasSuccess, SKPaymentTransaction *transaction) {
                                                                       @synchronized (this) {
                                                                           this.purchaseResults [cumulativeUnlock.productIdentifier] = @(wasSuccess ? 1 : 2);
                                                                           [this checkPurchaseResults];
                                                                       }
                                                                   }];
}

- (void)purchaseTimerItem {
    
    [Flurry logEvent:@"TapOnPurchaseTimerUnlock"];

    SKProduct *timerUnlock = [[DKStoreManager sharedInstance] getProductTimerUnlock];

    [self purchaseItem:timerUnlock];
}

- (void)purchaseMealListItem {
    
    [Flurry logEvent:@"TapOnPurchaseMealListUnlock"];

    SKProduct *listUnlock = [[DKStoreManager sharedInstance] getProductMealListUnlock];
    
    [self purchaseItem:listUnlock];
}

- (void)purchaseNoAdvItem {
    
    [Flurry logEvent:@"TapOnPurchaseNoAdvUnlock"];

    SKProduct *noAdvUnlock = [[DKStoreManager sharedInstance] getProductNoAdvUnlock];
    
    [self purchaseItem:noAdvUnlock];
}

- (void)purchaseThemesItem {
    
    [Flurry logEvent:@"TapOnPurchaseThemes"];
    
    SKProduct *themesUnlock = [[DKStoreManager sharedInstance] getProductThemesUnlock];
    
    [self purchaseItem:themesUnlock];
}

- (void)purchaseCumulativeItem {

    [Flurry logEvent:@"TapOnPurchaseCumulativeUnlock"];

    SKProduct *cumulativeUnlock = [[DKStoreManager sharedInstance] getProductCumulativeUnlock];
    
    [self purchaseItem:cumulativeUnlock];
}

- (void)purchaseSupportLevel1Item {
    
    [Flurry logEvent:@"TapOnPurchaseSupportLevel1"];
    
    SKProduct *supportLevel = [[DKStoreManager sharedInstance] getProductSupportLevel1];
    
    [self purchaseItem:supportLevel];
}

- (void)purchaseSupportLevel2Item {
    
    [Flurry logEvent:@"TapOnPurchaseSupportLevel2"];
    
    SKProduct *supportLevel = [[DKStoreManager sharedInstance] getProductSupportLevel2];
    
    [self purchaseItem:supportLevel];
}

- (void)purchaseSupportLevel3Item {
    
    [Flurry logEvent:@"TapOnPurchaseSupportLevel3"];
    
    SKProduct *supportLevel = [[DKStoreManager sharedInstance] getProductSupportLevel3];
    
    [self purchaseItem:supportLevel];
}

- (void)purchaseItem: (SKProduct *)itemToPurchase {
        
    if (itemToPurchase == nil) {
        [self showErrorIndicatorWithTitle:NSLocalizedString(@"Operation failed!", nil)];
        return;
    }
    
    [self showBigBusyIndicatorWithTitle:NSLocalizedString(@"Loading...", nil)];

    __weak typeof(self) this = self;

    [[DKStoreManager sharedInstance] purchaseNonconsumable:itemToPurchase
                                                      response:^(BOOL wasSuccess, SKPaymentTransaction *transaction) {

                                                          if (wasSuccess) {
                                                              [self showCompleteIndicatorWithTitle:NSLocalizedString(@"Thank you!", nil)];
                                                              
                                                              int64_t delayInSeconds = 1.5;
                                                              dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                                                              dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                                                                  [this.navigationController popViewControllerAnimated:YES];
                                                              });
                                                          } else {
                                                              [this showErrorIndicatorWithTitle:NSLocalizedString(@"Operation failed!", nil)];
                                                          }
                                                      }];
}

- (NSString *) priceAsString:(NSLocale *)localprice Price:(NSDecimalNumber *)price{
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:localprice];
    
    NSString *str = [formatter stringFromNumber:price];
    return str;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70.0;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
    [super viewWillAppear:animated];
}

#ifdef FREE

- (void)updateAdBannerPosition {
    self.tableView.tableFooterView = [UIView new];
    [self.adBanner removeFromSuperview];
}

#endif

@end

