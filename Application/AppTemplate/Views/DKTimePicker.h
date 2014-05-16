//
//  DKTimePicker.h
//  FitAssist
//
//  Created by Dmitry Klimkin on 16/5/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DKTimePicker;

@protocol DKTimePickerDelegate <NSObject>

@optional
- (void)timePicker:(DKTimePicker *)timePicker didSelectTime: (NSDate *)time;

@end

@interface DKTimePicker : UIView

@property (nonatomic, weak) id<DKTimePickerDelegate> delegate;
@property (nonatomic, strong) NSDate *time;

@end
