//
//  Timer.h
//  FitAssist
//
//  Created by Dmitry Klimkin on 25/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Timer : NSManagedObject

@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) NSDate * creationDate;

@end

