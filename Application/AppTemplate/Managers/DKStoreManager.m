//
//  DKStoreManager.m
//  FitA
//
//  Created by Dmitry Klimkin on 10/05/14.
//  Copyright 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKStoreManager.h"
#import "NSData+MKBase64.h"
#import "MKNetworkKit.h"
#import "Flurry.h"
#import "DKSettingsManager.h"

#define kProductThemesUnlock @"com.fitafree.themesunlock"
#define kProductTimerUnlock @"com.fitafree.timerunlock"
#define kProductMealListUnlock @"com.fitafree.meallistunlock"
#define kProductNoAdvUnlock @"com.fitafree.noadvunlock"
#define kProductCumulativeUnlock @"com.fitafree.cumulativeunlock"
#define kProductSupportLevel1 @"com.fitafree.supportlevel1"
#define kProductSupportLevel2 @"com.fitafree.supportlevel2"
#define kProductSupportLevel3 @"com.fitafree.supportlevel3"

#define kProductThemesItemID @"877567887"
#define kProductTimerItemID @""
#define kProductMealListItemID @""
#define kProductNoAdvItemID @"877567935"
#define kProductCumulativeItemID @""
#define kProductSupportLevel1ID @"877563688"
#define kProductSupportLevel2ID @"877563778"
#define kProductSupportLevel3ID @"877563828"

NSString *const kTransactionID	= @"Transaction ID";
NSString *const kTransactionReceipt = @"Transaction Receipt";

NSInteger CompareTransactionInfoInfo(SKPaymentTransaction *transaction1, SKPaymentTransaction *transaction2, void *context) {
	int *sortOrder = context;
	//List will be arranged in reverse order of dates
	if (*sortOrder == NSOrderedDescending) {
		return 	[transaction2.transactionDate compare:transaction1.transactionDate];
	} else {
		return 	[transaction1.transactionDate compare:transaction2.transactionDate];
	}
}

@interface DKStoreManager () {
    PurchaseResponse restorePurchaseResponse;
}

@property (nonatomic, strong) NSMutableDictionary *productById;
@property (nonatomic, strong) NSMutableDictionary *responseByProductId;
@property (nonatomic, strong) MKNetworkEngine *networkManager;

@end

@implementation DKStoreManager

@synthesize networkManager = _networkManager;
@synthesize productById = _productById;
@synthesize responseByProductId = _responseByProductId;

- (id)init {
	self = [super init];

	if (self != nil) {
        _networkManager = [[MKNetworkEngine alloc] initWithHostName:@"www.google.com"];
        [self fetchProductList];
	}
	return self;
}

+ (instancetype)sharedInstance {
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)fetchProductList {
    
    if ((self.productById == nil) || ([[self.productById allKeys] count] == 0)) {

        self.responseByProductId = [[NSMutableDictionary alloc] init];
        
        NSSet *set = [NSSet setWithObjects: kProductTimerUnlock, kProductMealListUnlock, kProductNoAdvUnlock,
                                            kProductCumulativeUnlock, kProductSupportLevel1, kProductSupportLevel2,
                                            kProductSupportLevel3, kProductThemesUnlock, nil];
        
        SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:set];
        
        request.delegate = self;
        
        [request start];
        
        __weak DKStoreManager *weakSelf = self;
        
        self.networkManager.reachabilityChangedHandler = ^(NetworkStatus status) {
            if (status != NotReachable) {
                
                SKProductsRequest *rerequest = [[SKProductsRequest alloc] initWithProductIdentifiers:set];
                
                rerequest.delegate = weakSelf;
                
                [rerequest start];
            }
        };
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
}

- (void)purchaseNonconsumable:(SKProduct*)product response:(PurchaseResponse)response {
    [self purchase:product response:^(BOOL wasSuccess, SKPaymentTransaction *transaction) {
        if (wasSuccess) {
            wasSuccess = [self verifyReceipt:transaction.transactionReceipt];
            
            if (wasSuccess) {
                [Flurry logEvent:@"SuccessValidPurchase"];
                
                NSLog(@"Successfully purchased full app unlock");
                
                if ([product.productIdentifier isEqualToString:kProductThemesUnlock] || [product.productIdentifier isEqualToString:kProductCumulativeUnlock]) {
                    [DKSettingsManager sharedInstance][kSettingThemes] = @(YES);
                }
                
                if ([product.productIdentifier isEqualToString:kProductTimerUnlock] || [product.productIdentifier isEqualToString:kProductCumulativeUnlock]) {
                    
                    [DKSettingsManager sharedInstance][kSettingExtendedTimer] = @(YES);
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName: kUnlockTimerProductNotification object: self];
                }
                
                if ([product.productIdentifier isEqualToString:kProductMealListUnlock] || [product.productIdentifier isEqualToString:kProductCumulativeUnlock]) {
                    
                    [DKSettingsManager sharedInstance][kSettingExtendedMealList] = @(YES);
                    [[NSNotificationCenter defaultCenter] postNotificationName: kUnlockMealListProductNotification object: self];
                }
                
                if ([product.productIdentifier isEqualToString:kProductNoAdvUnlock] || [product.productIdentifier isEqualToString:kProductCumulativeUnlock]) {
                    [DKSettingsManager sharedInstance][kSettingNoAdvApp] = @(YES);
                    [[NSNotificationCenter defaultCenter] postNotificationName: kUnlockNoAdvProductNotification object: self];
                }
                
//                [self saveTransaction: transaction];
            } else {
                [Flurry logEvent:@"RejectedInvalidPurchase"];
                NSLog(@"Unsuccessfully purchased full app unlock");
            }
        }
        
        if (response) {
            response(wasSuccess, transaction);
        }
    }];
}

- (void) restorePreviousPurchasesForProduct:(SKProduct *)product response:(PurchaseResponse)response {
    [self restorePurchasedForProduct:product response:^(BOOL wasSuccess, SKPaymentTransaction *transaction) {
        if (wasSuccess) {
            wasSuccess = [self verifyReceipt:transaction.transactionReceipt];
            
            if (wasSuccess) {
                [Flurry logEvent:@"SuccessValidRestorePurchase"];
                
                NSLog(@"Successfully restored product");

                if ([product.productIdentifier isEqualToString:kProductThemesUnlock] || [product.productIdentifier isEqualToString:kProductCumulativeUnlock]) {
                    
                    [DKSettingsManager sharedInstance][kSettingThemes] = @(YES);
                }
                
                if ([product.productIdentifier isEqualToString:kProductTimerUnlock] || [product.productIdentifier isEqualToString:kProductCumulativeUnlock]) {
                    
                    [DKSettingsManager sharedInstance][kSettingExtendedTimer] = @(YES);
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName: kUnlockTimerProductNotification object: self];
                }
                
                if ([product.productIdentifier isEqualToString:kProductMealListUnlock] || [product.productIdentifier isEqualToString:kProductCumulativeUnlock]) {
                    
                    [DKSettingsManager sharedInstance][kSettingExtendedMealList] = @(YES);
                    [[NSNotificationCenter defaultCenter] postNotificationName: kUnlockMealListProductNotification object: self];
                }
                
                if ([product.productIdentifier isEqualToString:kProductNoAdvUnlock] || [product.productIdentifier isEqualToString:kProductCumulativeUnlock]) {
                    [DKSettingsManager sharedInstance][kSettingNoAdvApp] = @(YES);
                    [[NSNotificationCenter defaultCenter] postNotificationName: kUnlockNoAdvProductNotification object: self];
                }
                
//                [self saveTransaction: transaction];
            } else {
                [Flurry logEvent:@"RejectedInvalidRestorePurchase"];
                
                NSLog(@"Unsuccessfully restored full app unlock");
            }
        }
        
        if (response) {
            response(wasSuccess, transaction);
        }
    }];
}

- (void)restorePurchasedForProduct:(SKProduct *)product response:(PurchaseResponse)response {
    restorePurchaseResponse = response;
    [self.responseByProductId setObject:[response copy] forKey:product.productIdentifier];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)purchase:(SKProduct*)product response:(PurchaseResponse)response {
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [self.responseByProductId setObject:[response copy] forKey:product.productIdentifier];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (SKProduct*)getProductThemesUnlock {
    if (self.productById != nil) {
        return [self.productById objectForKey:kProductThemesUnlock];
    }
    return nil;
}

- (SKProduct*)getProductTimerUnlock {
    if (self.productById != nil) {
        return [self.productById objectForKey:kProductTimerUnlock];
    }
    return nil;
}

- (SKProduct*)getProductMealListUnlock {
    if (self.productById != nil) {
        return [self.productById objectForKey:kProductMealListUnlock];
    }
    return nil;
}

- (SKProduct*)getProductNoAdvUnlock {
    if (self.productById != nil) {
        return [self.productById objectForKey:kProductNoAdvUnlock];
    }
    return nil;
}

- (SKProduct*)getProductCumulativeUnlock {
    if (self.productById != nil) {
        return [self.productById objectForKey:kProductCumulativeUnlock];
    }
    return nil;
}

- (SKProduct*)getProductSupportLevel1 {
    if (self.productById != nil) {
        return [self.productById objectForKey:kProductSupportLevel1];
    }
    return nil;
}

- (SKProduct*)getProductSupportLevel2 {
    if (self.productById != nil) {
        return [self.productById objectForKey:kProductSupportLevel2];
    }
    return nil;
}

- (SKProduct*)getProductSupportLevel3 {
    if (self.productById != nil) {
        return [self.productById objectForKey:kProductSupportLevel3];
    }
    return nil;
}

- (void)checkForPendingTransactions {
}

+ (NSString *)documentsDirectory {
	static NSString *documentsDirectory= nil;
	if(! documentsDirectory) {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		documentsDirectory = [paths objectAtIndex:0];
	}
	return documentsDirectory;
}

+ (NSString *)inAppPurcahseTransactionFolder {
	return [NSString stringWithFormat:@"%@/%@", [[self class] documentsDirectory], @"Transaction"];
}

- (BOOL)saveTransaction:(SKPaymentTransaction *)transaction {
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                          [transaction.transactionReceipt base64EncodedString], kTransactionReceipt,
                          transaction.transactionIdentifier, kTransactionID,
                          transaction.payment.productIdentifier, @"product_id", nil];
    
    NSString *directory = [[[self class] inAppPurcahseTransactionFolder] stringByAppendingPathComponent:@"0"];
    BOOL isDir = YES;

    if ((NO == [[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDir]) || (NO == isDir)) {
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *filePath = [directory stringByAppendingPathComponent:[NSString stringWithFormat:@"receipt_%@.plist", transaction.transactionIdentifier]];
    
    return [data writeToFile:filePath atomically:NO];
}

- (BOOL)getTransaction: (NSString**)transactionId receipt:(NSString**)receipt productId:(NSString**)productId {
    NSString *directory = [[[self class] inAppPurcahseTransactionFolder] stringByAppendingPathComponent:@"0"];
	NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:nil];
    
    for (int i = 0; i < files.count; i++) {
        NSString *fileName = [files objectAtIndex:i];
        NSString *filePath = [directory stringByAppendingPathComponent:fileName];
        NSDictionary *data = [NSDictionary dictionaryWithContentsOfFile:filePath];
        
        if (data != nil) {
            *receipt = [data objectForKey:kTransactionReceipt];
            *productId = [data objectForKey:@"product_id"];
            *transactionId = [data objectForKey:kTransactionID];
            
            if (*receipt && *productId && *transactionId) {
                NSString *correctFileName = [NSString stringWithFormat:@"receipt_%@.plist", *transactionId];
            
                if ([fileName isEqualToString:correctFileName]) {
                    return YES;
                }
            }
        }
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    return NO;
}

- (void)removeTransaction:(NSString *)transactionId {
    NSString *directory = [[[self class] inAppPurcahseTransactionFolder] stringByAppendingPathComponent:@"0"];
    NSString *filePath = [directory stringByAppendingPathComponent:[NSString stringWithFormat:@"receipt_%@.plist", transactionId]];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
	for (SKPaymentTransaction *transaction in transactions) {
		switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                break;
                
			case SKPaymentTransactionStatePurchased: {
                PurchaseResponse response = [self.responseByProductId objectForKey:transaction.payment.productIdentifier];
                if (response) {
                    [self.responseByProductId removeObjectForKey:transaction.payment.productIdentifier];
                    response(YES, transaction);
                }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
                break;
				
            case SKPaymentTransactionStateFailed: {
                PurchaseResponse response = [self.responseByProductId objectForKey:transaction.payment.productIdentifier];
                if (response) {
                    [self.responseByProductId removeObjectForKey:transaction.payment.productIdentifier];
                    response(NO, transaction);
                }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
                break;
				
            case SKPaymentTransactionStateRestored: {
                PurchaseResponse response = [self.responseByProductId objectForKey:transaction.payment.productIdentifier];
                if (response) {
                    [self.responseByProductId removeObjectForKey:transaction.payment.productIdentifier];
                    response(YES, transaction);
                }
                
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
                break;
		}
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    NSLog(@"Error restored filters");
    
    if (restorePurchaseResponse) {
        restorePurchaseResponse(NO, nil);
    }
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    self.productById = [[NSMutableDictionary alloc] init];
    
    for (SKProduct *product in response.products) {
        [self.productById setObject:product forKey:product.productIdentifier];
    }
    
	NSLog(@"Invalid Products = %@", response.invalidProductIdentifiers);
}

- (BOOL)verifyReceipt:(NSData*)receiptData {

#ifdef TESTING
    NSURL *url = [NSURL URLWithString: @"https://sandbox.itunes.apple.com/verifyReceipt"];
#else
    NSURL *url = [NSURL URLWithString: @"https://buy.itunes.apple.com/verifyReceipt"];
#endif
    
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url];
    NSString *st =  [receiptData base64EncodedString];
    NSString *json = [NSString stringWithFormat:@"{\"receipt-data\":\"%@\"}", st];
    
    [theRequest setHTTPBody:[json dataUsingEncoding:NSUTF8StringEncoding]];
    [theRequest setHTTPMethod:@"POST"];
    [theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];    
    [theRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)json.length] forHTTPHeaderField:@"Content-Length"];
    
    NSHTTPURLResponse* urlResponse = nil;
    NSError *error = nil;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:theRequest
                                                 returningResponse:&urlResponse
                                                             error:&error];
    if(error != nil || responseData == nil) return NO;
    
    error = nil;
    
    id returnValue = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
    
    if(error){
        NSLog(@"JSON Parsing Error: %@", error);
        return NO;
    }
    
    NSDictionary *dic = returnValue;
    NSInteger status = [[dic objectForKey:@"status"] intValue];
    NSDictionary *receiptDic = [dic objectForKey:@"receipt"];
    BOOL retVal = NO;
   
    if (status == 0 && receiptDic != nil) {
        NSString *itemId = [receiptDic objectForKey:@"item_id"];
        NSString *productId = [receiptDic objectForKey:@"product_id"];
        
        if (productId && ([productId isEqualToString:kProductTimerUnlock] || [productId isEqualToString:kProductMealListUnlock] ||
                          [productId isEqualToString:kProductNoAdvUnlock] || [productId isEqualToString:kProductCumulativeUnlock] ||
                          [productId isEqualToString:kProductSupportLevel1] || [productId isEqualToString:kProductSupportLevel2] ||
                          [productId isEqualToString:kProductSupportLevel3] || [productId isEqualToString:kProductThemesUnlock])) {
            
            if (itemId && ([itemId isEqualToString:kProductTimerItemID] || [itemId isEqualToString:kProductMealListItemID] ||
                           [itemId isEqualToString:kProductNoAdvItemID] || [itemId isEqualToString:kProductCumulativeItemID] ||
                           [itemId isEqualToString:kProductSupportLevel1ID] || [itemId isEqualToString:kProductSupportLevel2ID] ||
                           [itemId isEqualToString:kProductSupportLevel3ID] || [itemId isEqualToString:kProductThemesItemID])) {
                retVal = YES;
            }
        }
    }
    return retVal;
}

@end
