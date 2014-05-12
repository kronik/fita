//
//  DKTimePicker.h
//  DKTimePicker
//
//  Created by Dmitry Klimkin on 28/2/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import <UIKit/UIKit.h>

#define DKTimePickerPartsSeparator @" "

@protocol DKTimePickerDelegate;

//Button for save
@interface DKTimePickerButton : UIButton

@end


//Scroll view
@interface DKTimePickerScrollView : UITableView

@property NSInteger tagLastSelected;

- (void)dehighlightLastCell;
- (void)highlightCellWithIndexPathRow:(NSUInteger)indexPathRow;

@end


//Data Picker
@interface DKTimePicker : UIView <UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id <DKTimePickerDelegate> delegate;
@property (nonatomic, strong) NSString *configuration;

@end
