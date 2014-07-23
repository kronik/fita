//
//  DKWeeksViewController.h
//  FitAssist
//
//  Created by Dmitry Klimkin on 17/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKBaseViewController.h"

@interface DKWeeksViewController : DKBaseViewController

- (id)initWithWeeks: (NSMutableArray *)weeks;

+ (NSString *)exportTextForWeek: (DKWeek *)week;
- (void)exportWeek:(DKWeek *)week withAlertInView: (UIView *)view;

@end
