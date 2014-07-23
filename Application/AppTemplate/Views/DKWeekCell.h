//
//  DKWeekCell.h
//  FitAssist
//
//  Created by Dmitry Klimkin on 20/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Week.h"
#import "SWTableViewCell.h"
#import "DKModel.h"

@protocol DKWeekCellDelegate <NSObject>

- (void)didTapOnPhotoOfWeek: (DKWeek *)week inView: (UIView *)view;

@end

@interface DKWeekCell : UITableViewCell

@property (nonatomic, weak) DKWeek *week;
@property (nonatomic, weak) id<DKWeekCellDelegate> delegate;

- (void)setWeek:(DKWeek *)week withShift: (int)shift;

@end
