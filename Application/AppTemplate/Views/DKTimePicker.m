//
//  DKTimePicker.m
//  DKTimePicker
//
//  Created by Dmitry Klimkin on 28/2/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKTimePicker.h"
#import "DKTimePickerDelegate.h"
#import "DKCircleButton.h"

//Check screen macros
#define IS_WIDESCREEN (fabs ( (double)[[UIScreen mainScreen] bounds].size.height - (double)568) < DBL_EPSILON)

//Editable macros
#define TEXT_COLOR [UIColor colorWithWhite:1 alpha:1.0]
#define SELECTED_TEXT_COLOR [UIColor whiteColor]
#define LINE_COLOR [UIColor colorWithWhite:0.80 alpha:1.0]
#define SAVE_AREA_COLOR ApplicationMainColor
#define BAR_SEL_COLOR [ApplicationMainColor colorWithAlphaComponent:0.5]
//[UIColor colorWithRed:76.0f/255.0f green:172.0f/255.0f blue:239.0f/255.0f alpha:0.8]

//Editable constants
static const float VALUE_HEIGHT = 65.0;
static const float SAVE_AREA_HEIGHT = 100.0;
static const float SAVE_AREA_MARGIN_TOP = 20.0;

//Editable values
float PICKER_HEIGHT = 300.0;
NSString *FONT_NAME = ApplicationFont;

//Static macros and constants
#define SELECTOR_ORIGIN (PICKER_HEIGHT/2.0-VALUE_HEIGHT/2.0)
#define SAVE_AREA_ORIGIN_Y ScreenHeight - 100
#define PICKER_ORIGIN_Y SAVE_AREA_ORIGIN_Y-SAVE_AREA_MARGIN_TOP-PICKER_HEIGHT
#define BAR_SEL_ORIGIN_Y PICKER_HEIGHT/2.0-VALUE_HEIGHT/2.0


//Custom UIButton
@implementation DKTimePickerButton

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor clearColor]];
        [self setTitleColor:BAR_SEL_COLOR forState:UIControlStateNormal];
        [self setTitleColor:SELECTED_TEXT_COLOR forState:UIControlStateHighlighted];
        [self.titleLabel setFont:[UIFont fontWithName:FONT_NAME size:18.0]];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat outerMargin = 5.0f;
    CGRect outerRect = CGRectInset(self.bounds, outerMargin, outerMargin);
    CGFloat radius = 6.0;
    
    CGMutablePathRef outerPath = CGPathCreateMutable();
    CGPathMoveToPoint(outerPath, NULL, CGRectGetMidX(outerRect), CGRectGetMinY(outerRect));
    CGPathAddArcToPoint(outerPath, NULL, CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect), CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect), radius);
    CGPathAddArcToPoint(outerPath, NULL, CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect), CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect), radius);
    CGPathAddArcToPoint(outerPath, NULL, CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect), CGRectGetMinX(outerRect), CGRectGetMinY(outerRect), radius);
    CGPathAddArcToPoint(outerPath, NULL, CGRectGetMinX(outerRect), CGRectGetMinY(outerRect), CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect), radius);
    CGPathCloseSubpath(outerPath);
    
    CGContextSaveGState(context);
    CGContextSetStrokeColorWithColor(context, (self.state != UIControlStateHighlighted) ? BAR_SEL_COLOR.CGColor : SELECTED_TEXT_COLOR.CGColor);
    CGContextAddPath(context, outerPath);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self setNeedsDisplay];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [self setNeedsDisplay];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [self setNeedsDisplay];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    [self setNeedsDisplay];
}

@end


//Custom scrollView
@interface DKTimePickerScrollView ()

@property (nonatomic, strong) NSArray *arrValues;
@property (nonatomic, strong) UIFont *cellFont;

@end


@implementation DKTimePickerScrollView

//Constants
const float LBL_BORDER_OFFSET = 8.0;

//Configure the tableView
- (id)initWithFrame:(CGRect)frame andValues:(NSArray *)arrayValues
      withTextAlign:(NSTextAlignment)align andTextSize:(float)txtSize {
    
    if(self = [super initWithFrame:frame]) {
        [self setScrollEnabled:YES];
        [self setShowsVerticalScrollIndicator:NO];
        [self setUserInteractionEnabled:YES];
        [self setBackgroundColor:[UIColor clearColor]];
        [self setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        [self setContentInset:UIEdgeInsetsMake(BAR_SEL_ORIGIN_Y, 0.0, BAR_SEL_ORIGIN_Y, 0.0)];
        
        _cellFont = [UIFont fontWithName:FONT_NAME size:txtSize];
        
        if(arrayValues)
            _arrValues = [arrayValues copy];
    }
    return self;
}


//Dehighlight the last cell
- (void)dehighlightLastCell {
    NSArray *paths = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:_tagLastSelected inSection:0], nil];
    [self setTagLastSelected:-1];
    [self beginUpdates];
    [self reloadRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationNone];
    [self endUpdates];
}

//Highlight a cell
- (void)highlightCellWithIndexPathRow:(NSUInteger)indexPathRow {
    [self setTagLastSelected:indexPathRow];
    NSArray *paths = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:_tagLastSelected inSection:0], nil];
    [self beginUpdates];
    [self reloadRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationNone];
    [self endUpdates];
}

@end


//Custom Data Picker
@interface DKTimePicker ()

@property (nonatomic, strong) NSArray *arrWorkTimes;
@property (nonatomic, strong) NSArray *arrRestTimes;
@property (nonatomic, strong) NSArray *arrExercises;
@property (nonatomic, strong) NSArray *arrRounds;
@property (nonatomic, strong) DKCircleButton *saveButton;

@property (nonatomic, strong) DKTimePickerScrollView *svWorkTimes;
@property (nonatomic, strong) DKTimePickerScrollView *svRestTimes;
@property (nonatomic, strong) DKTimePickerScrollView *svExercises;
@property (nonatomic, strong) DKTimePickerScrollView *svRounds;


@end


@implementation DKTimePicker

-(void)drawRect:(CGRect)rect {
    [self initialize];
    [self buildControl];
}

- (void)initialize {
    //Set the height of picker if isn't an iPhone 5 or 5s
    [self checkScreenSize];
    
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
    _configuration = @"00:10-00:00-10-10";
}

- (void)buildControl {
    
    float singlePickerWidth = ScreenWidth / 4;
    
    //Create a view as base of the picker
    UIView *pickerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, PICKER_ORIGIN_Y, self.frame.size.width, PICKER_HEIGHT)];
    [pickerView setBackgroundColor:self.backgroundColor];
    
    //Create bar selector
    UIView *barSel = [[UIView alloc] initWithFrame:CGRectMake(0.0, BAR_SEL_ORIGIN_Y, self.frame.size.width, VALUE_HEIGHT)];
    [barSel setBackgroundColor:BAR_SEL_COLOR];
    
    //Create the first column (moments) of the picker
    _svWorkTimes = [[DKTimePickerScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, singlePickerWidth, PICKER_HEIGHT) andValues:_arrWorkTimes withTextAlign:NSTextAlignmentCenter andTextSize:18.0];
    _svWorkTimes.tag = 0;
    [_svWorkTimes setDelegate:self];
    [_svWorkTimes setDataSource:self];
    
    UILabel *worksLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, PICKER_ORIGIN_Y - 40, singlePickerWidth - 10, 50)];
    
    worksLabel.backgroundColor = [UIColor clearColor];
    worksLabel.textAlignment = NSTextAlignmentCenter;
    worksLabel.numberOfLines = 2;
    worksLabel.font = [UIFont fontWithName:FONT_NAME size:16];
    worksLabel.textColor = [UIColor whiteColor];
    worksLabel.lineBreakMode = NSLineBreakByWordWrapping;
    worksLabel.text = NSLocalizedString(@"Work time", nil);
    
    //Create the second column (hours) of the picker
    _svRestTimes = [[DKTimePickerScrollView alloc] initWithFrame:CGRectMake(singlePickerWidth, 0.0, singlePickerWidth, PICKER_HEIGHT) andValues:_arrRestTimes withTextAlign:NSTextAlignmentCenter  andTextSize:18.0];
    _svRestTimes.tag = 1;
    [_svRestTimes setDelegate:self];
    [_svRestTimes setDataSource:self];
    
    UILabel *restLabel = [[UILabel alloc] initWithFrame:CGRectMake(singlePickerWidth + 5, PICKER_ORIGIN_Y - 40, singlePickerWidth - 10, 50)];
    
    restLabel.backgroundColor = [UIColor clearColor];
    restLabel.textAlignment = NSTextAlignmentCenter;
    restLabel.numberOfLines = 2;
    restLabel.font = [UIFont fontWithName:FONT_NAME size:16];
    restLabel.textColor = [UIColor whiteColor];
    restLabel.lineBreakMode = NSLineBreakByWordWrapping;
    restLabel.text = NSLocalizedString(@"Rest time", nil);
    
    //Create the third column (minutes) of the picker
    _svExercises = [[DKTimePickerScrollView alloc] initWithFrame:CGRectMake(singlePickerWidth * 2, 0.0, singlePickerWidth, PICKER_HEIGHT) andValues:_arrExercises withTextAlign:NSTextAlignmentRight andTextSize:20.0];
    _svExercises.tag = 2;
    [_svExercises setDelegate:self];
    [_svExercises setDataSource:self];
    
    UILabel *exerciseLabel = [[UILabel alloc] initWithFrame:CGRectMake(5 + singlePickerWidth * 2, PICKER_ORIGIN_Y - 40, singlePickerWidth - 10, 50)];
    
    exerciseLabel.backgroundColor = [UIColor clearColor];
    exerciseLabel.textAlignment = NSTextAlignmentCenter;
    exerciseLabel.numberOfLines = 2;
    exerciseLabel.font = [UIFont fontWithName:FONT_NAME size:16];
    exerciseLabel.textColor = [UIColor whiteColor];
    exerciseLabel.lineBreakMode = NSLineBreakByWordWrapping;
    exerciseLabel.text = NSLocalizedString(@"Exercises", nil);

    //Create the fourth column (meridians) of the picker
    _svRounds = [[DKTimePickerScrollView alloc] initWithFrame:CGRectMake(singlePickerWidth * 3, 0.0, singlePickerWidth, PICKER_HEIGHT) andValues:_arrRounds withTextAlign:NSTextAlignmentRight andTextSize:20.0];
    _svRounds.tag = 3;
    [_svRounds setDelegate:self];
    [_svRounds setDataSource:self];
    
    UILabel *roundLabel = [[UILabel alloc] initWithFrame:CGRectMake(5 + singlePickerWidth * 3, PICKER_ORIGIN_Y - 40, singlePickerWidth - 10, 50)];
    
    roundLabel.backgroundColor = [UIColor clearColor];
    roundLabel.textAlignment = NSTextAlignmentCenter;
    roundLabel.numberOfLines = 2;
    roundLabel.font = [UIFont fontWithName:FONT_NAME size:16];
    roundLabel.textColor = [UIColor whiteColor];
    roundLabel.lineBreakMode = NSLineBreakByWordWrapping;
    roundLabel.text = NSLocalizedString(@"Rounds", nil);

    //Create separators lines
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(singlePickerWidth - 1.0, 0.0, 2.0, PICKER_HEIGHT)];
    [line setBackgroundColor:LINE_COLOR];
    
    UIView *line2 = [[UIView alloc] initWithFrame:CGRectMake((singlePickerWidth * 2) - 1.0, 0.0, 2.0, PICKER_HEIGHT)];
    [line2 setBackgroundColor:LINE_COLOR];
    
    UIView *line3 = [[UIView alloc] initWithFrame:CGRectMake((singlePickerWidth * 3) - 1.0, 0.0, 2.0, PICKER_HEIGHT)];
    [line3 setBackgroundColor:LINE_COLOR];
    
    //Layer gradient
    CAGradientLayer *gradientLayerTop = [CAGradientLayer layer];
    gradientLayerTop.frame = CGRectMake(0.0, 0.0, pickerView.frame.size.width, PICKER_HEIGHT/2.0);
    gradientLayerTop.colors = [NSArray arrayWithObjects:(id)[ApplicationMainColor colorWithAlphaComponent:0.1].CGColor, (id)self.backgroundColor.CGColor, nil];
    gradientLayerTop.startPoint = CGPointMake(0.0f, 0.7f);
    gradientLayerTop.endPoint = CGPointMake(0.0f, 0.0f);
    
    CAGradientLayer *gradientLayerBottom = [CAGradientLayer layer];
    gradientLayerBottom.frame = CGRectMake(0.0, PICKER_HEIGHT/2.0, pickerView.frame.size.width, PICKER_HEIGHT/2.0);
    gradientLayerBottom.colors = gradientLayerTop.colors;
    gradientLayerBottom.startPoint = CGPointMake(0.0f, 0.3f);
    gradientLayerBottom.endPoint = CGPointMake(0.0f, 1.0f);
    
    
    //Create save area
    UIView *saveArea = [[UIView alloc] initWithFrame:CGRectMake(0.0, SAVE_AREA_ORIGIN_Y, self.frame.size.width, SAVE_AREA_HEIGHT)];
    [saveArea setBackgroundColor:SAVE_AREA_COLOR];
    
    //Create save button
    _saveButton = [DKCircleButton buttonWithType:UIButtonTypeCustom];
    
    _saveButton.frame = CGRectMake(0, 0, 90, 90);
    _saveButton.backgroundColor = ApplicationMainColor;
    _saveButton.clipsToBounds = YES;

    _saveButton.center = CGPointMake(ScreenWidth / 2, 40);// CGRectMake(80.0, -10.0, self.frame.size.width - 160.0, SAVE_AREA_HEIGHT);
    _saveButton.layer.borderColor = [UIColor whiteColor].CGColor;
    _saveButton.layer.borderWidth = 1.0;
    _saveButton.layer.cornerRadius = 5;
    
    [_saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_saveButton setTitle:NSLocalizedString(@"Set", nil) forState:UIControlStateNormal];
    [_saveButton addTarget:self action:@selector(saveButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    //Add pickerView
    [self addSubview:pickerView];
    
    //Add separator lines
    [pickerView addSubview:line];
    [pickerView addSubview:line2];
    [pickerView addSubview:line3];
    
    //Add the bar selector
    [pickerView addSubview:barSel];
    
    //Add scrollViews
    [pickerView addSubview:_svWorkTimes];
    [pickerView addSubview:_svRestTimes];
    [pickerView addSubview:_svExercises];
    [pickerView addSubview:_svRounds];
    
    [self addSubview:worksLabel];
    [self addSubview:restLabel];
    [self addSubview:exerciseLabel];
    [self addSubview:roundLabel];
    
    //Add gradients
    [pickerView.layer addSublayer:gradientLayerTop];
    [pickerView.layer addSublayer:gradientLayerBottom];
    
    //Add Savearea
    [self addSubview:saveArea];
    
    //Add button save
    [saveArea addSubview:_saveButton];
}

#pragma mark - Other methods

//Save button pressed
- (void)saveButtonPressed:(id)sender {
    //Create date
    
    [self didTapItem: sender];
    
    NSString *configuration = [NSString stringWithFormat:@"%@ %@ %@ %@",
                               _arrWorkTimes[_svWorkTimes.tagLastSelected],
                               _arrRestTimes[_svRestTimes.tagLastSelected],
                               _arrExercises[_svExercises.tagLastSelected],
                               _arrRounds[_svRounds.tagLastSelected]];
    
    //Send the date to the delegate
    if([_delegate respondsToSelector:@selector(timePicker:saveConfiguration:)]) {
        [_delegate timePicker:self saveConfiguration:configuration];
    }
}

//Center the value in the bar selector
- (void)centerValueForScrollView:(DKTimePickerScrollView *)scrollView {
    
    //Takes the actual offset
    float offset = scrollView.contentOffset.y;
    
    //Removes the contentInset and calculates the prcise value to center the nearest cell
    offset += scrollView.contentInset.top;
    int mod = (int)offset%(int)VALUE_HEIGHT;
    float newValue = (mod >= VALUE_HEIGHT/2.0) ? offset+(VALUE_HEIGHT-mod) : offset-mod;
    
    //Calculates the indexPath of the cell and set it in the object as property
    NSInteger indexPathRow = (int)(newValue/VALUE_HEIGHT);
    
    //Center the cell
    [self centerCellWithIndexPathRow:indexPathRow forScrollView:scrollView];
}

//Center phisically the cell
- (void)centerCellWithIndexPathRow:(NSUInteger)indexPathRow forScrollView:(DKTimePickerScrollView *)scrollView {
    
    if(indexPathRow >= [scrollView.arrValues count]) {
        indexPathRow = [scrollView.arrValues count]-1;
    }
    
    float newOffset = indexPathRow*VALUE_HEIGHT;
    
    //Re-add the contentInset and set the new offset
    newOffset -= BAR_SEL_ORIGIN_Y;
    [scrollView setContentOffset:CGPointMake(0.0, newOffset) animated:YES];
    
    //Highlight the cell
    [scrollView highlightCellWithIndexPathRow:indexPathRow];
    
    [_saveButton setEnabled:YES];
}

- (void)setConfiguration:(NSString *)configuration {
    _configuration = configuration;
    
    NSArray *parts = [configuration componentsSeparatedByString:DKTimePickerPartsSeparator];
    
    if (parts.count < 4) {
        return;
    }
    
    //Set the tableViews
    [_svWorkTimes dehighlightLastCell];
    [_svRestTimes dehighlightLastCell];
    [_svExercises dehighlightLastCell];
    [_svRounds    dehighlightLastCell];
    
    //Center the other fields
    [self centerCellWithIndexPathRow:[_arrWorkTimes indexOfObject:parts[0]] forScrollView:_svWorkTimes];
    [self centerCellWithIndexPathRow:[_arrRestTimes indexOfObject:parts[1]] forScrollView:_svRestTimes];
    [self centerCellWithIndexPathRow:[_arrExercises indexOfObject:parts[2]] forScrollView:_svExercises];
    [self centerCellWithIndexPathRow:[_arrRounds    indexOfObject:parts[3]] forScrollView:_svRounds];
}

//Set the time automatically
//- (void)setTime:(NSString *)time {
//    //Get the string
//    NSString *strTime;
//    if([time isEqualToString:NOW])
//        strTime = [self stringFromDate:[NSDate date] withFormat:@"hh:mm a"];
//    else
//        strTime = (NSString *)time;
//    
//    //Split
//    NSArray *comp = [strTime componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" :"]];
//    
//    //Set the tableViews
//    [_svHours dehighlightLastCell];
//    [_svMins dehighlightLastCell];
//    [_svMeridians dehighlightLastCell];
//    
//    //Center the other fields
//    [self centerCellWithIndexPathRow:([comp[0] intValue]%12)-1 forScrollView:_svHours];
//    [self centerCellWithIndexPathRow:[comp[1] intValue] forScrollView:_svMins];
//    [self centerCellWithIndexPathRow:[_arrMeridians indexOfObject:comp[2]] forScrollView:_svMeridians];
//}
//
////Switch to the previous or next day
//- (void)switchToDay:(NSInteger)dayOffset {
//    //Calculate and save the new date
//    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
//    NSDateComponents *offsetComponents = [NSDateComponents new];
//    
//    //Set the offset
//    [offsetComponents setDay:dayOffset];
//    
//    NSDate *newDate = [gregorian dateByAddingComponents:offsetComponents toDate:_selectedDate options:0];
//    _selectedDate = newDate;
//    
//    //Show new date
//    [_lblWeekDay setText:[self stringFromDate:_selectedDate withFormat:@"EEEE"]];
//    [_lblDayMonth setText:[self stringFromDate:_selectedDate withFormat:@"dd LLLL yyyy"]];
//}
//
//- (void)switchToDayPrev {
//    //Check if the again previous day is a past day and in this case i disable the button
//    //Calculate the new date
//    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
//    NSDateComponents *offsetComponents = [NSDateComponents new];
//    
//    //Set the offset
//    [offsetComponents setDay:-2];
//    NSDate *newDate = [gregorian dateByAddingComponents:offsetComponents toDate:_selectedDate options:0];
//    
//    //If newDate is in the past
//    if([newDate compare:[NSDate date]] == NSOrderedAscending) {
//        //Disable button previus day
//        [_btPrev setEnabled:NO];
//    }
//    
//    [self switchToDay:-1];
//}
//
//- (void)switchToDayNext {
//    if(![_btPrev isEnabled]) [_btPrev setEnabled:YES];
//    
//    [self switchToDay:1];
//}

//Check the screen size
- (void)checkScreenSize {
    if(IS_WIDESCREEN) {
        PICKER_HEIGHT = 212.0;
    } else {
        PICKER_HEIGHT = 212.0;
    }
}

//- (void)setSelectedDate:(NSDate *)date {
//    _selectedDate = date;
//    [self switchToDay:0];
//    
//    NSString *strTime = [self stringFromDate:date withFormat:@"hh:mm a"];
//    [self setTime:strTime];
//}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (![scrollView isDragging]) {
        [self centerValueForScrollView:(DKTimePickerScrollView *)scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self centerValueForScrollView:(DKTimePickerScrollView *)scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    [_saveButton setEnabled:NO];
    
    DKTimePickerScrollView *sv = (DKTimePickerScrollView *)scrollView;
    
    [sv dehighlightLastCell];
}

#pragma - UITableViewDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    DKTimePickerScrollView *sv = (DKTimePickerScrollView *)tableView;
    return [sv.arrValues count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = @"reusableCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    DKTimePickerScrollView *sv = (DKTimePickerScrollView *)tableView;
    
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        [cell setBackgroundColor:[UIColor clearColor]];
        [cell.textLabel setFont:sv.cellFont];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    [cell.textLabel setTextColor:(indexPath.row == sv.tagLastSelected) ? SELECTED_TEXT_COLOR : TEXT_COLOR];
    [cell.textLabel setText:sv.arrValues[indexPath.row]];
    
    return cell;
}

- (void)didTapItem:(UIView *)view {
    
    CGRect pathFrame = CGRectMake(-CGRectGetMidX(view.bounds), -CGRectGetMidY(view.bounds), view.bounds.size.width, view.bounds.size.height);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:pathFrame cornerRadius:view.layer.cornerRadius];
    
    // accounts for left/right offset and contentOffset of scroll view
    CGPoint shapePosition = [self convertPoint:view.center fromView:view.superview];
    
    CAShapeLayer *circleShape = [CAShapeLayer layer];
    circleShape.path = path.CGPath;
    circleShape.position = shapePosition;
    circleShape.fillColor = [UIColor clearColor].CGColor;
    circleShape.opacity = 0;
    circleShape.strokeColor = [UIColor whiteColor].CGColor;
    circleShape.lineWidth = 2.0;
    
    [self.layer addSublayer:circleShape];
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(2.5, 2.5, 1)];
    
    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.fromValue = @1;
    alphaAnimation.toValue = @0;
    
    CAAnimationGroup *animation = [CAAnimationGroup animation];
    animation.animations = @[scaleAnimation, alphaAnimation];
    animation.duration = 0.5f;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [circleShape addAnimation:animation forKey:nil];
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return VALUE_HEIGHT;
}

@end
