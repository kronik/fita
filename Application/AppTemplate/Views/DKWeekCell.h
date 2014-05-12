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

@protocol DKWeekCellDelegate <NSObject>

- (void)didTapOnPhotoOfWeek: (Week *)week inView: (UIView *)view;

@end

@interface DKWeekCell : UITableViewCell

@property (nonatomic, weak) Week *week;
@property (nonatomic, weak) id<DKWeekCellDelegate> delegate;

- (void)setWeek:(Week *)week withShift: (int)shift;

@end
