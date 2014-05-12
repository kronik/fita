//
//  DKWeeksViewController.h
//  FitAssist
//
//  Created by Dmitry Klimkin on 17/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKBaseViewController.h"
#import "Week.h"

@interface DKWeeksViewController : DKBaseViewController

- (id)initWithWeeks: (NSArray *)weeks;

+ (NSString *)exportTextForWeek: (Week *)week;
- (void)exportWeek:(Week *)week withAlertInView: (UIView *)view;

@end
