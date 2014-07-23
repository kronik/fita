//
//  Meal.h
//  FitAssist
//
//  Created by Dmitry Klimkin on 19/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Day;

@interface Meal : NSManagedObject

@property (nonatomic, retain) NSData * picture;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) Day * day;

@end

