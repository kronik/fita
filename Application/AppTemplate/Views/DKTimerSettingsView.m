//
//  DKTimerSettingsView.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 10/5/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKTimerSettingsView.h"
#import "IZValueSelectorView.h"
#import "DKCircleButton.h"
#import "UIColor+MLPFlatColors.h"

#define DKTimerSettingsViewPickerHeight 50.0

@interface DKTimerSettingsView() <IZValueSelectorViewDataSource, IZValueSelectorViewDelegate>

@property (nonatomic, strong) IZValueSelectorView *workTimeView;
@property (nonatomic, strong) IZValueSelectorView *restTimeView;
@property (nonatomic, strong) IZValueSelectorView *execView;
@property (nonatomic, strong) IZValueSelectorView *roundsTimeView;
@property (nonatomic, strong) DKCircleButton *saveButton;
@property (nonatomic) CGFloat pickerHeightSpace;

@property (nonatomic, strong) NSArray *arrWorkTimes;
@property (nonatomic, strong) NSArray *arrRestTimes;
@property (nonatomic, strong) NSArray *arrExercises;
@property (nonatomic, strong) NSArray *arrRounds;

@property (nonatomic, strong) NSString *workTime;
@property (nonatomic, strong) NSString *restTime;
@property (nonatomic, strong) NSString *execTime;
@property (nonatomic, strong) NSString *roundsTime;

@end

@implementation DKTimerSettingsView

@synthesize workTimeView = _workTimeView;
@synthesize restTimeView = _restTimeView;
@synthesize execView = _execView;
@synthesize roundsTimeView = _roundsTimeView;
@synthesize saveButton = _saveButton;
@synthesize delegate = _delegate;
@synthesize configuration = _configuration;
@synthesize pickerHeightSpace = _pickerHeightSpace;
@synthesize restTime = _restTime;
@synthesize workTime = _workTime;
@synthesize execTime = _execTime;
@synthesize roundsTime = _roundsTime;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self customInit];
    }
    return self;
}

- (void)customInit {
    
    if (ScreenHeight > 480.0) {
        self.pickerHeightSpace = 15;
    } else {
        self.pickerHeightSpace = 7;
    }
    
    CGFloat yOffset = ApplicationNavigationAndStatusBarHeight + self.pickerHeightSpace;
    
    NSMutableArray *workTimes = [NSMutableArray new];
    
    for (int i=0; i<21; i++) {
        for (int j=0; j<59; j+=5) {
            [workTimes addObject:[NSString stringWithFormat:@"%02d:%02d", i, j]];
        }
    }
    
    [workTimes removeObjectAtIndex:0];
    
    _arrWorkTimes = [workTimes copy];
    
    [workTimes insertObject:@"00:00" atIndex:0];
    _arrRestTimes = [workTimes copy];
    
    workTimes = [NSMutableArray new];
    
    for (int i=1; i<100; i++) {
        [workTimes addObject:[NSString stringWithFormat:@"%02d", i]];
    }
    
    [workTimes addObject:@"100"];
    
    _arrExercises = [workTimes copy];
    _arrRounds = [workTimes copy];
    
    //Set the acutal date
    _configuration = @"00:10 00:00 10 10";
    
    UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, yOffset, ScreenWidth, 20)];
    
    infoLabel.backgroundColor = [UIColor clearColor];
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.numberOfLines = 1;
    infoLabel.font = [UIFont fontWithName:ApplicationFont size:16];
    infoLabel.textColor = [UIColor whiteColor];
    infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
    infoLabel.text = NSLocalizedString(@"Work time", nil);

    [self addSubview:infoLabel];

    yOffset += infoLabel.frame.size.height;
    
    UIColor *mainColor = ApplicationMainColor;
    
    self.workTimeView = [[IZValueSelectorView alloc] initWithFrame:CGRectMake(15, yOffset, ScreenWidth - 30, DKTimerSettingsViewPickerHeight)];
    
    self.workTimeView.dataSource = self;
    self.workTimeView.delegate = self;
    self.workTimeView.shouldBeTransparent = YES;
    self.workTimeView.horizontalScrolling = YES;
    self.workTimeView.decelerates = YES;
    self.workTimeView.backgroundColor = [mainColor darkerColor];
    self.workTimeView.selectedColor = mainColor;
    self.workTimeView.layer.borderWidth = 3.0;
    self.workTimeView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6].CGColor;
    self.workTimeView.layer.cornerRadius = DKTimerSettingsViewPickerHeight / 2;
    
    [self addSubview:self.workTimeView];

    yOffset += DKTimerSettingsViewPickerHeight + self.pickerHeightSpace;
    
    infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, yOffset, ScreenWidth, 20)];
    
    infoLabel.backgroundColor = [UIColor clearColor];
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.numberOfLines = 1;
    infoLabel.font = [UIFont fontWithName:ApplicationFont size:16];
    infoLabel.textColor = [UIColor whiteColor];
    infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
    infoLabel.text = NSLocalizedString(@"Rest time", nil);
    
    [self addSubview:infoLabel];
    
    yOffset += infoLabel.frame.size.height;
    
    self.restTimeView = [[IZValueSelectorView alloc] initWithFrame:CGRectMake(15, yOffset, ScreenWidth - 30, DKTimerSettingsViewPickerHeight)];
    
    self.restTimeView.dataSource = self;
    self.restTimeView.delegate = self;
    self.restTimeView.shouldBeTransparent = YES;
    self.restTimeView.horizontalScrolling = YES;
    self.restTimeView.decelerates = YES;
    self.restTimeView.backgroundColor = [mainColor darkerColor];
    self.restTimeView.selectedColor = mainColor;
    self.restTimeView.layer.borderWidth = 3.0;
    self.restTimeView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6].CGColor;
    self.restTimeView.layer.cornerRadius = DKTimerSettingsViewPickerHeight / 2;

    [self addSubview:self.restTimeView];
    
    yOffset += DKTimerSettingsViewPickerHeight + self.pickerHeightSpace;
    
    infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, yOffset, ScreenWidth, 20)];
    
    infoLabel.backgroundColor = [UIColor clearColor];
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.numberOfLines = 1;
    infoLabel.font = [UIFont fontWithName:ApplicationFont size:16];
    infoLabel.textColor = [UIColor whiteColor];
    infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
    infoLabel.text = NSLocalizedString(@"Exercises", nil);
    
    [self addSubview:infoLabel];
    
    yOffset += infoLabel.frame.size.height;

    self.execView = [[IZValueSelectorView alloc] initWithFrame:CGRectMake(15, yOffset, ScreenWidth - 30, DKTimerSettingsViewPickerHeight)];
    
    self.execView.dataSource = self;
    self.execView.delegate = self;
    self.execView.shouldBeTransparent = YES;
    self.execView.horizontalScrolling = YES;
    self.execView.decelerates = YES;
    self.execView.backgroundColor = [mainColor darkerColor];
    self.execView.selectedColor = mainColor;
    self.execView.layer.borderWidth = 3.0;
    self.execView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6].CGColor;
    self.execView.layer.cornerRadius = DKTimerSettingsViewPickerHeight / 2;

    [self addSubview:self.execView];

    yOffset += DKTimerSettingsViewPickerHeight + self.pickerHeightSpace;
    
    infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, yOffset, ScreenWidth, 20)];
    
    infoLabel.backgroundColor = [UIColor clearColor];
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.numberOfLines = 1;
    infoLabel.font = [UIFont fontWithName:ApplicationFont size:16];
    infoLabel.textColor = [UIColor whiteColor];
    infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
    infoLabel.text = NSLocalizedString(@"Rounds", nil);
    
    [self addSubview:infoLabel];
    
    yOffset += infoLabel.frame.size.height;

    self.roundsTimeView = [[IZValueSelectorView alloc] initWithFrame:CGRectMake(15, yOffset, ScreenWidth - 30, DKTimerSettingsViewPickerHeight)];
    
    self.roundsTimeView.dataSource = self;
    self.roundsTimeView.delegate = self;
    self.roundsTimeView.shouldBeTransparent = YES;
    self.roundsTimeView.horizontalScrolling = YES;
    self.roundsTimeView.decelerates = YES;
    self.roundsTimeView.backgroundColor = [mainColor darkerColor];
    self.roundsTimeView.selectedColor = mainColor;
    self.roundsTimeView.layer.borderWidth = 3.0;
    self.roundsTimeView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6].CGColor;
    self.roundsTimeView.layer.cornerRadius = DKTimerSettingsViewPickerHeight / 2;

    [self addSubview:self.roundsTimeView];
    
    yOffset += DKTimerSettingsViewPickerHeight + (self.pickerHeightSpace * 2);

    //Create save button
    self.saveButton = [DKCircleButton buttonWithType:UIButtonTypeCustom];
    
    self.saveButton.frame = CGRectMake(-45 + ScreenWidth / 2, yOffset, 90, 90);
    self.saveButton.backgroundColor = ApplicationMainColor;
    self.saveButton.clipsToBounds = YES;
    self.saveButton.titleLabel.font = [UIFont fontWithName:ApplicationLightFont size:25];
    
    self.saveButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.saveButton.layer.borderWidth = 1.0;
    self.saveButton.layer.cornerRadius = 5;
    
    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.saveButton setTitle:NSLocalizedString(@"Set", nil) forState:UIControlStateNormal];
    [self.saveButton addTarget:self action:@selector(saveButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:self.saveButton];
}

- (NSInteger)numberOfRowsInSelector:(IZValueSelectorView *)valueSelector {
    if (valueSelector == self.workTimeView) {
        return self.arrWorkTimes.count;
    } else if (valueSelector == self.restTimeView) {
        return self.arrRestTimes.count;
    } else if (valueSelector == self.execView) {
        return self.arrExercises.count;
    } else if (valueSelector == self.roundsTimeView) {
        return self.arrRounds.count;
    } else {
        return 0;
    }
}

//ONLY ONE OF THESE WILL GET CALLED (DEPENDING ON the horizontalScrolling property Value)
- (CGFloat)rowHeightInSelector:(IZValueSelectorView *)valueSelector {
    return 100.0;
}

- (CGFloat)rowWidthInSelector:(IZValueSelectorView *)valueSelector {
    return 100.0;
}

- (CGRect)rectForSelectionInSelector:(IZValueSelectorView *)valueSelector {
    //Just return a rect in which you want the selector image to appear
    //Use the IZValueSelector coordinates
    //Basically the x will be 0
    //y will be the origin of your image
    //width and height will be the same as in your selector image
    return CGRectMake(valueSelector.frame.size.width / 2 - [self rowWidthInSelector: nil] / 2, 0.0,
                      [self rowWidthInSelector: nil], DKTimerSettingsViewPickerHeight);
}

- (void)selector:(IZValueSelectorView *)valueSelector didSelectRowAtIndex:(NSInteger)index {
    
    if (valueSelector == self.workTimeView) {
        self.workTime =  self.arrWorkTimes[index];
    } else if (valueSelector == self.restTimeView) {
        self.restTime = self.arrRestTimes[index];
    } else if (valueSelector == self.execView) {
        self.execTime = self.arrExercises[index];
    } else if (valueSelector == self.roundsTimeView) {
        self.roundsTime = self.arrRounds[index];
    }
}

- (UIView *)selector:(IZValueSelectorView *)valueSelector viewForRowAtIndex:(NSInteger)index {
    return [self selector:valueSelector viewForRowAtIndex:index selected:NO];
}

- (UIView *)selector:(IZValueSelectorView *)valueSelector viewForRowAtIndex:(NSInteger)index selected:(BOOL)selected {
    
    NSString *value = @"";
    
    if (valueSelector == self.workTimeView) {
        value =  self.arrWorkTimes[index];
    } else if (valueSelector == self.restTimeView) {
        value = self.arrRestTimes[index];
    } else if (valueSelector == self.execView) {
        value = self.arrExercises[index];
    } else if (valueSelector == self.roundsTimeView) {
        value = self.arrRounds[index];
    }
    
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, DKTimerSettingsViewPickerHeight)];

    label.text = value;
    label.textAlignment =  NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    
    if (selected) {
        label.font = [UIFont fontWithName:ApplicationFont size:24];
        label.textColor = [UIColor whiteColor];
    } else {
        label.font = [UIFont fontWithName:ApplicationFont size:20];
        label.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
    }
    return label;
}

- (void)saveButtonPressed {
    NSString *configuration = [NSString stringWithFormat:@"%@ %@ %@ %@",
                               self.workTime, self.restTime, self.execTime, self.roundsTime];
    
    //Send the date to the delegate
    if([_delegate respondsToSelector:@selector(timePicker:saveConfiguration:)]) {
        [_delegate timePicker:self saveConfiguration:configuration];
    }
}

- (void)setConfiguration:(NSString *)configuration {
    _configuration = configuration;
    
    NSArray *parts = [configuration componentsSeparatedByString:DKTimerPickerPartsSeparator];
    
    if (parts.count < 4) {
        return;
    }
    
    //Center the other fields
    [self.workTimeView selectRowAtIndex:[_arrWorkTimes indexOfObject:parts[0]] animated:NO];
    [self.restTimeView selectRowAtIndex:[_arrRestTimes indexOfObject:parts[1]] animated:NO];
    [self.execView selectRowAtIndex:[_arrExercises indexOfObject:parts[2]] animated:NO];
    [self.roundsTimeView selectRowAtIndex:[_arrRounds indexOfObject:parts[3]] animated:NO];
}

@end
