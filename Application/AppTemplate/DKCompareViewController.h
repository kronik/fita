//
//  DKCompareViewController.h
//  FitAssist
//
//  Created by Dmitry Klimkin on 29/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKBaseViewController.h"
#import "Week.h"

@interface DKCompareViewController : DKBaseViewController

- (instancetype)initWithFirstWeek: (Week *)firstWeek andSecondWeek: (Week *)secondWeek;

@end
