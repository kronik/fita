//
//  Week+Extra.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 6/5/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "Week+Extra.h"
#import "DKSettingsViewController.h"
#import "Day+Extra.h"

@implementation Week (Extra)

- (NSString *)fullDescription {
    int weekShift = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kSettingsWeekKey];
    
    if (weekShift > 0) {
        weekShift --;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    
    NSPredicate *weekFilter = [NSPredicate predicateWithFormat:@"week = %@", self];
    NSArray *days = [Day MR_findAllSortedBy:@"seqNumber" ascending:NO withPredicate:weekFilter];
    NSString *textToShare = [NSString stringWithFormat:@"\n%@ %d\n", NSLocalizedString(@"Week", nil),
                             [self.seqNumber intValue] + weekShift];
    
    for (Day *day in days) {
        textToShare = [textToShare stringByAppendingString:[day shortDescription]];
    }
    
    return textToShare;
}

@end
