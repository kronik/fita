//
//  DKModel.h
//  FitAssist
//
//  Created by Dmitry Klimkin on 23/7/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

@interface DKTimer : RLMObject

@property NSString * value;
@property NSDate * creationDate;

@end

RLM_ARRAY_TYPE(DKTimer)

@class DKWorkout;

@interface DKModel : NSObject

@end

@interface DKExercise : RLMObject

@property NSString *title;
@property NSNumber *repeats;
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

@property NSData * picture;
@property NSString * text;
@property NSDate * time;
@property NSString * type;
@property DKDay * day;

@end

RLM_ARRAY_TYPE(DKMeal)

@class DKWeek;

@interface DKDay : RLMObject

@property NSDate * date;
@property DKWeek *week;
@property NSString *name;
@property NSString *comment;
@property NSNumber * seqNumber;
@property RLMArray<DKMeal> *meals;

@end

RLM_ARRAY_TYPE(DKDay)

@interface DKWeek : RLMObject

@property (nonatomic, retain) NSNumber * seqNumber;
@property (nonatomic, retain) NSDate   * startDate;
@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSData * imageSide;
@property RLMArray<DKDay> *days;

@end

RLM_ARRAY_TYPE(DKWeek)




