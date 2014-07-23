//
//  DKModel.h
//  FitAssist
//
//  Created by Dmitry Klimkin on 23/7/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

typedef void (^DKArrayResultBlock)(NSArray *objects, NSError *error);
typedef void (^DKIntegerResultBlock)(int number, NSError *error);
typedef void (^DKBooleanResultBlock)(BOOL success, NSError *error);
typedef void (^DKItemResultBlock)(RLMObject *object, NSError *error);
typedef void (^DKMultiArrayResultBlock)(NSArray *objects, NSMutableDictionary *data, NSError *error);
typedef void (^DKUpdateItemBlock)(void);

@interface DKTimer : RLMObject

@property NSString * value;
@property NSDate * creationDate;

@end

RLM_ARRAY_TYPE(DKTimer)

@class DKWorkout;

@interface DKExercise : RLMObject

@property NSString  *title;
@property NSInteger repeats;
@property DKWorkout *workout;

@end

RLM_ARRAY_TYPE(DKExercise)

@interface DKWorkout : RLMObject

@property NSDate * date;
@property NSString * timer;
@property NSString * title;
@property RLMArray<DKExercise> *exercises;

@end

RLM_ARRAY_TYPE(DKWorkout)

@class DKDay;

@interface DKMeal : RLMObject

@property NSString * picture;
@property NSString * text;
@property NSDate * time;
@property NSString * type;
@property DKDay * day;

@end

RLM_ARRAY_TYPE(DKMeal)

@class DKWeek;

@interface DKDay : RLMObject

@property NSDate *date;
@property DKWeek *week;
@property NSString *name;
@property NSString *comment;
@property NSInteger seqNumber;

- (NSString *)shortDescription;
- (NSString *)fullDescription;

@end

RLM_ARRAY_TYPE(DKDay)

@interface DKWeek : RLMObject

@property NSInteger  seqNumber;
@property NSDate   * startDate;
@property NSString * image;
@property NSString * imageSide;
@property NSString * weight;
@property NSString * height;
@property NSString * volumes;

- (NSString *)fullDescription;

@end

RLM_ARRAY_TYPE(DKWeek)

@interface DKModel : NSObject

+ (instancetype)sharedInstance;

- (void)migrateFromCoreDataToRealmWithBlock:(DKBooleanResultBlock)block;

+ (NSMutableArray *)loadAllTimers;
+ (NSMutableArray *)loadAllWeeks;
+ (NSMutableArray *)loadAllDaysByWeek:(DKWeek *)week;
+ (NSMutableArray *)loadAllMealEntriesByDay:(DKDay *)day;

+ (void)addObject:(RLMObject *)object;
+ (void)deleteObject:(RLMObject *)object;
+ (void)updateObjectsWithBlock:(DKUpdateItemBlock)block;

+ (NSString *)linkFromImage:(UIImage *)image;
+ (NSString *)linkFromData:(NSData *)data;
+ (UIImage *)imageFromLink:(NSString *)link;

+ (NSMutableArray *)arrayFromRLMArray:(RLMArray *)array;

@end



