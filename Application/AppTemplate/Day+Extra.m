//
//  Day+Extra.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 6/5/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "Day+Extra.h"
#import "DKSettingsViewController.h"
#import "Meal.h"
#import "Week.h"

@implementation Day (Extra)

- (NSString *)fullDescription {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    
    int weekShift = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kSettingsWeekKey];
    
    if (weekShift > 0) {
        weekShift --;
    }
    
    NSString *textToShare = [NSString stringWithFormat:@"\n%@ %d %@\n", NSLocalizedString(@"Week", nil),
                             [self.week.seqNumber intValue] + weekShift, self.name];
    
    NSPredicate *dayFilter = [NSPredicate predicateWithFormat:@"day = %@", self];
    NSArray *mealEntries = [Meal MR_findAllSortedBy:@"time" ascending:YES withPredicate:dayFilter];
    
    for (Meal *meal in mealEntries) {
        if (meal.text.length == 0) {
            continue;
        }
        
        textToShare = [textToShare stringByAppendingString:[NSString stringWithFormat:@"%@: %@\n",
                                                            [dateFormatter stringFromDate: meal.time], meal.text]];
    }
    
    textToShare = [textToShare stringByAppendingString:[NSString stringWithFormat:@"\n%@\n", self.comment]];
    
    return textToShare;
}

- (NSString *)shortDescription {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];

    NSString *textToShare = @"";
    
    textToShare = [textToShare stringByAppendingString:[NSString stringWithFormat:@"\n%@:\n", self.name]];
    
    NSPredicate *dayFilter = [NSPredicate predicateWithFormat:@"day = %@", self];
    NSArray *mealEntries = [Meal MR_findAllSortedBy:@"time" ascending:YES withPredicate:dayFilter];
    
    for (Meal *meal in mealEntries) {
        if (meal.text.length == 0) {
            continue;
        }
        
        textToShare = [textToShare stringByAppendingString:[NSString stringWithFormat:@"%@: %@\n",
                                                            [dateFormatter stringFromDate: meal.time], meal.text]];
    }
    
    textToShare = [textToShare stringByAppendingString:[NSString stringWithFormat:@"\n%@\n", self.comment]];

    return textToShare;
}

@end
