//
//  DKStoreManager.h
//  FitA
//
//  Created by Dmitry Klimkin on 10/05/14.
//  Copyright 2014 Dmitry Klimkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#define kUnlockTimerProductNotification @"kUnlockTimerProductNotification"
#define kUnlockMealListProductNotification @"kUnlockMealListProductNotification"
#define kUnlockNoAdvProductNotification @"kUnlockNoAdvProductNotification"
#define kSupportProductNotification @"kSupportProductNotification"

@interface DKStoreManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

typedef void (^PurchaseResponse)(BOOL wasSuccess, SKPaymentTransaction *transaction);

+ (DKStoreManager *)sharedInstance;

- (void)fetchProductList;
- (void)purchaseNonconsumable:(SKProduct*)product response:(PurchaseResponse)response;
- (void)restorePreviousPurchasesForProduct:(SKProduct *)product response:(PurchaseResponse)response;
- (void)checkForPendingTransactions;

- (SKProduct*)getProductThemesUnlock;
- (SKProduct*)getProductTimerUnlock;
- (SKProduct*)getProductMealListUnlock;
- (SKProduct*)getProductNoAdvUnlock;
- (SKProduct*)getProductCumulativeUnlock;
- (SKProduct*)getProductSupportLevel1;
- (SKProduct*)getProductSupportLevel2;
- (SKProduct*)getProductSupportLevel3;

@end
