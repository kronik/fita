//
//  DKTimePickerDelegate.h
//  DKTimePicker
//
//  Created by Dmitry Klimkin on 28/2/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DKTimePicker;

//Protocol to return the date
@protocol DKTimePickerDelegate <NSObject>

@optional
- (void)timePicker:(DKTimePicker *)timePicker saveConfiguration:(NSString *)configuration;

@end
