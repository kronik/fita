//
//  DKMealViewController.h
//  FitAssist
//
//  Created by Dmitry Klimkin on 17/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKBaseViewController.h"
#import "DKModel.h"

#define kMealTypeWork     NSLocalizedString(@"Work", nil)
#define kMealTypeSnack    NSLocalizedString(@"Snack", nil)
#define kMealTypeRegular  NSLocalizedString(@"Meal", nil)
#define kMealTypeDrink    NSLocalizedString(@"Drink", nil)

@interface DKMealViewController : DKBaseViewController

- (id)initWithDay: (DKDay *)day canAddNewDay: (BOOL)canAddNewDay;

@end
