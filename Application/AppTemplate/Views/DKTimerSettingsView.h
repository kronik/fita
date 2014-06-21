//
//  DKTimerSettingsView.h
//  FitAssist
//
//  Created by Dmitry Klimkin on 10/5/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import <UIKit/UIKit.h>

#define DKTimerPickerPartsSeparator @" "

@class DKTimerSettingsView;

@protocol DKTimerSettingsViewDelegate <NSObject>

@optional
- (void)timePicker:(DKTimerSettingsView *)timePicker saveConfiguration:(NSString *)configuration;
- (void)openPurchases;

@end

@interface DKTimerSettingsView : UIView

@property (nonatomic, weak) id<DKTimerSettingsViewDelegate> delegate;
@property (nonatomic, strong) NSString *configuration;

@end
