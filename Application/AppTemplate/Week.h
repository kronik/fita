//
//  Week.h
//  FitAssist
//
//  Created by Dmitry Klimkin on 19/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Day;

@interface Week : NSManagedObject

@property (nonatomic, retain) NSNumber * seqNumber;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSSet *days;
@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSData * imageSide;

@end

@interface Week (CoreDataGeneratedAccessors)

- (void)addDaysObject:(Day *)value;
- (void)removeDaysObject:(Day *)value;
- (void)addDays:(NSSet *)values;
- (void)removeDays:(NSSet *)values;

@end
