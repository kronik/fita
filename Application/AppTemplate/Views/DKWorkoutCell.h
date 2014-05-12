//
//  DKWorkoutCell.h
//  FitAssist
//
//  Created by Dmitry Klimkin on 6/5/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Workout.h"

@protocol DKWorkoutCellDelegate <NSObject>


@end

@interface DKWorkoutCell : UITableViewCell

@property (nonatomic, weak) Workout *workout;
@property (nonatomic, weak) id<DKWorkoutCellDelegate> delegate;

@end
