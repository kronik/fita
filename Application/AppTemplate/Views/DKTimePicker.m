//
//  DKTimePicker.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 16/5/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKTimePicker.h"
#import "IZValueSelectorView.h"
#import "UIColor+MLPFlatColors.h"

#define DKTimePickerHeight 50.0

@interface DKTimePicker () <IZValueSelectorViewDataSource, IZValueSelectorViewDelegate>

@property (nonatomic, strong) IZValueSelectorView *timeView;
@property (nonatomic, strong) NSArray *values;
@property (nonatomic, strong) NSString *stringValue;

@end

@implementation DKTimePicker

@synthesize delegate = _delegate;
@synthesize timeView = _timeView;
@synthesize values = _values;
@synthesize stringValue = _stringValue;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self customInit];
    }
    return self;
}

- (void)customInit {
    NSMutableArray *workTimes = [NSMutableArray new];
    
    for (int i=0; i<24; i++) {
        for (int j=0; j<59; j+=5) {
            [workTimes addObject:[NSString stringWithFormat:@"%02d:%02d", i, j]];
        }
    }
    
    [workTimes removeObjectAtIndex:0];
    
    UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, ScreenWidth, 20)];
    
    infoLabel.backgroundColor = [UIColor clearColor];
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.numberOfLines = 1;
    infoLabel.font = [UIFont fontWithName:ApplicationFont size:16];
    infoLabel.textColor = [UIColor whiteColor];
    infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
    infoLabel.text = NSLocalizedString(@"Time", nil);
    
    [self addSubview:infoLabel];
    
    UIColor *mainColor = ApplicationMainColor;
    
    self.timeView = [[IZValueSelectorView alloc] initWithFrame:CGRectMake(15, 30, ScreenWidth - 30, DKTimePickerHeight)];
    
    self.timeView.dataSource = self;
    self.timeView.delegate = self;
    self.timeView.shouldBeTransparent = YES;
    self.timeView.horizontalScrolling = YES;
    self.timeView.decelerates = YES;
    self.timeView.backgroundColor = [mainColor darkerColor];
    self.timeView.selectedColor = mainColor;
    self.timeView.layer.borderWidth = 3.0;
    self.timeView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6].CGColor;
    self.timeView.layer.cornerRadius = DKTimePickerHeight / 2;
    
    [self addSubview:self.timeView];
    
    self.values = workTimes;
    self.time = [NSDate date];
}

- (NSInteger)numberOfRowsInSelector:(IZValueSelectorView *)valueSelector {
    return self.values.count;
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
                      [self rowWidthInSelector: nil], DKTimePickerHeight);
}

- (void)selector:(IZValueSelectorView *)valueSelector didSelectRowAtIndex:(NSInteger)index {
    
    _stringValue = self.values[index];
    
    NSCalendarUnit unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *comps = [calendar components:unitFlags fromDate:self.time];
    NSArray *parts = [self.stringValue componentsSeparatedByString:@":"];
    
    comps.hour   = [parts[0] intValue];
    comps.minute = [parts[1] intValue];
    comps.second = 0;

    _time = [calendar dateFromComponents:comps];
    
    if ([_delegate respondsToSelector:@selector(timePicker:didSelectTime:)]) {
        [_delegate timePicker:self didSelectTime:self.time];
    }
}

- (void)setTime:(NSDate *)time {
    
    _time = time;
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    
    [timeFormat setTimeZone:[NSTimeZone localTimeZone]];
    [timeFormat setDateFormat:@"HH:mm"];

    self.stringValue = [timeFormat stringFromDate:time];
}

- (void)setStringValue:(NSString *)stringValue {
    
    NSUInteger index = [self.values indexOfObject:stringValue];
    
    if (index < self.values.count) {
        [self.timeView selectRowAtIndex:[self.values indexOfObject:stringValue] animated:NO];
    } else {
        NSArray *parts = [stringValue componentsSeparatedByString:@":"];
        
        int minutes = [parts[1] intValue];
                
        minutes -= minutes % 5;
        
        stringValue = [NSString stringWithFormat:@"%@:%02d", parts[0], minutes];
        
        index = [self.values indexOfObject:stringValue];
        
        [self.timeView selectRowAtIndex:[self.values indexOfObject:stringValue] animated:NO];
    }
    
    _stringValue = stringValue;
}

- (UIView *)selector:(IZValueSelectorView *)valueSelector viewForRowAtIndex:(NSInteger)index {
    return [self selector:valueSelector viewForRowAtIndex:index selected:NO];
}

- (UIView *)selector:(IZValueSelectorView *)valueSelector viewForRowAtIndex:(NSInteger)index selected:(BOOL)selected {
    
    NSString *value = self.values[index];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, DKTimePickerHeight)];
    
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

@end
