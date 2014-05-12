//
//  Day.h
//  FitAssist
//
//  Created by Dmitry Klimkin on 19/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Meal, Week;

@interface Day : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSSet *meals;
@property (nonatomic, retain) Week *week;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *comment;
@property (nonatomic, retain) NSNumber * seqNumber;

@end

@interface Day (CoreDataGeneratedAccessors)

- (void)addMealsObject:(Meal *)value;
- (void)removeMealsObject:(Meal *)value;
- (void)addMeals:(NSSet *)values;
- (void)removeMeals:(NSSet *)values;

@end
