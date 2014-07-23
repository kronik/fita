//
//  DKModel.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 23/7/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKModel.h"
#import "DKSettingsViewController.h"
#import "Timer.h"
#import "Week.h"
#import "Day.h"
#import "NSString+MKNetworkKitAdditions.h"
#import "DKEnvironment.h"

#define DKModelCoreDataMigrationKey @"DKModelCoreDataMigrationKey"
#define DKImageFilesFolder @"images"

@implementation DKTimer

@end

@implementation DKModel

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

- (id)init {
    self = [super init];
    
    if (self != nil) {
    }
    
    return self;
}

+ (UIImage *)imageFromLink:(NSString *)link {
    NSString *cachedFilePath = [NSString stringWithFormat:@"%@/%@/%@",
                                [DKEnvironment documentsDirectory],
                                DKImageFilesFolder, link];
    
    return [UIImage imageWithContentsOfFile:cachedFilePath];
}

+ (NSString *)linkFromImage:(UIImage *)image {
    
    if (!image) {
        return @"";
    }
    
    NSString *fileKey = [NSString uniqueString];
    NSString *cachedFilePath = [NSString stringWithFormat:@"%@/%@/%@",
                                [DKEnvironment documentsDirectory],
                                DKImageFilesFolder, fileKey];

    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    
    [imageData writeToFile:cachedFilePath atomically:YES];
    
    return fileKey;
}

+ (NSString *)linkFromData:(NSData *)data {
    
    if (data.length == 0) {
        return @"";
    }
    
    NSString *fileKey = [NSString uniqueString];
    NSString *cachedFilePath = [NSString stringWithFormat:@"%@/%@/%@",
                                [DKEnvironment documentsDirectory],
                                DKImageFilesFolder, fileKey];
    
    [data writeToFile:cachedFilePath atomically:YES];
    
    return fileKey;
}

- (void)migrateFromCoreDataToRealmWithBlock:(DKBooleanResultBlock)block {
    BOOL migrationExecuted = [[NSUserDefaults standardUserDefaults] boolForKey:DKModelCoreDataMigrationKey];
    
    if (migrationExecuted == NO) {
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DKModelCoreDataMigrationKey];
        [[NSUserDefaults standardUserDefaults] synchronize];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            RLMRealm *realm = [RLMRealm defaultRealm];
            
            [realm beginWriteTransaction];

            NSArray *timers = [Timer MR_findAllSortedBy:@"creationDate" ascending:NO];

            for (Timer *oldTimer in timers) {
                DKTimer *timer = [DKTimer new];

                timer.value = oldTimer.value;
                timer.creationDate = oldTimer.creationDate;
                
                [realm addObject:timer];
            }
            
            NSArray *weeks = [Week MR_findAllSortedBy:@"seqNumber" ascending:NO];

            for (Week *oldWeek in weeks) {
                NSPredicate *weekFilter = [NSPredicate predicateWithFormat:@"week = %@", oldWeek];
                NSArray *days = [Day MR_findAllSortedBy:@"seqNumber" ascending:NO withPredicate:weekFilter];

                DKWeek *week = [DKWeek new];
                
                week.seqNumber = [oldWeek.seqNumber integerValue];
                week.startDate = oldWeek.startDate;
                week.image = [DKModel linkFromData:oldWeek.image];
                week.imageSide = [DKModel linkFromData:oldWeek.imageSide];
                week.weight = @"";
                week.height = @"";
                week.volumes = @"";
                
                [realm addObject:week];
                
                for (Day *oldDay in days) {
                    NSPredicate *dayFilter = [NSPredicate predicateWithFormat:@"day = %@", oldDay];
                    NSArray *mealEntries = [[Meal MR_findAllSortedBy:@"time" ascending:NO withPredicate:dayFilter] mutableCopy];

                    DKDay *day = [DKDay new];
                    
                    day.date = oldDay.date;
                    day.name = oldDay.name;
                    day.comment = oldDay.comment;
                    day.seqNumber = [oldDay.seqNumber integerValue];
                    day.week = week;

                    [realm addObject:day];

                    for (Meal *oldMeal in mealEntries) {
                        DKMeal *meal = [DKMeal new];
                        
                        meal.picture = [DKModel linkFromData:oldMeal.picture];
                        meal.text = oldMeal.text;
                        meal.time = oldMeal.time;
                        meal.type = oldMeal.type;
                        meal.day = day;
                        
                        [realm addObject:day];
                    }
                }
            }
            
            [realm commitWriteTransaction];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                block(YES, nil);
            });
        });
    } else {
        block (NO, nil);
    }
}

+ (NSMutableArray *)loadAllTimers {
    return [DKModel arrayFromRLMArray:[[DKTimer objectsWithPredicate:nil] arraySortedByProperty:@"creationDate" ascending:NO]];
}

+ (NSMutableArray *)loadAllWeeks {
    return [DKModel arrayFromRLMArray:[[DKWeek objectsWithPredicate:nil] arraySortedByProperty:@"seqNumber" ascending:NO]];
}

+ (NSMutableArray *)loadAllDaysByWeek:(DKWeek *)week {
    NSPredicate *weekFilter = [NSPredicate predicateWithFormat:@"week = %@", week];
    return [DKModel arrayFromRLMArray:[[DKDay objectsWithPredicate:weekFilter] arraySortedByProperty:@"seqNumber" ascending:NO]];
}

+ (NSMutableArray *)loadAllMealEntriesByDay:(DKDay *)day {
    NSPredicate *dayFilter = [NSPredicate predicateWithFormat:@"day = %@", day];
    return [DKModel arrayFromRLMArray:[[DKMeal objectsWithPredicate:dayFilter] arraySortedByProperty:@"time" ascending:NO]];
}

+ (void)addObject:(RLMObject *)object {
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    [realm addObject:object];
    [realm commitWriteTransaction];
}

+ (void)deleteObject:(RLMObject *)object {
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    [realm deleteObject:object];
    [realm commitWriteTransaction];
}

+ (void)updateObjectsWithBlock:(DKUpdateItemBlock)block {
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    block();
    
    [realm commitWriteTransaction];
}

+ (NSMutableArray *)arrayFromRLMArray:(RLMArray *)array {
    
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithCapacity:array.count];
    
    for (RLMObject *object in array) {
        [mutableArray addObject:object];
    }
    
    return mutableArray;
}

@end

@implementation DKWorkout

@end

@implementation DKExercise
@end

@implementation DKMeal

+ (NSDictionary *)defaultPropertyValues {
    return @{@"picture": @"", @"text": @"", @"time": [NSDate date], @"type": @""};
}

@end

@implementation DKDay

+ (NSDictionary *)defaultPropertyValues {
    return @{@"date": [NSDate date], @"name": @"", @"comment": @""};
}

- (NSString *)fullDescription {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    
    int weekShift = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kSettingsWeekKey];
    
    if (weekShift > 0) {
        weekShift --;
    }
    
    NSString *textToShare = [NSString stringWithFormat:@"\n%@ %ld %@\n", NSLocalizedString(@"Week", nil),
                             self.week.seqNumber + weekShift, self.name];
    
    NSPredicate *dayFilter = [NSPredicate predicateWithFormat:@"day = %@", self];
    RLMArray *mealEntries = [[DKMeal objectsWithPredicate:dayFilter] arraySortedByProperty:@"time" ascending:YES];
    
    for (DKMeal *meal in mealEntries) {
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
    RLMArray *mealEntries = [[DKMeal objectsWithPredicate:dayFilter] arraySortedByProperty:@"time" ascending:YES];
    
    for (DKMeal *meal in mealEntries) {
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

@implementation DKWeek

+ (NSDictionary *)defaultPropertyValues {
    return @{@"startDate": [NSDate date], @"image": @"", @"imageSide": @"", @"weight": @"", @"height": @"", @"volumes": @""};
}

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
    RLMArray *days = [[DKDay objectsWithPredicate:weekFilter] arraySortedByProperty:@"seqNumber" ascending:NO];
    NSString *textToShare = [NSString stringWithFormat:@"\n%@ %ld\n", NSLocalizedString(@"Week", nil),
                             self.seqNumber + weekShift];
    
    for (DKDay *day in days) {
        textToShare = [textToShare stringByAppendingString:[day shortDescription]];
    }
    
    return textToShare;
}

@end
