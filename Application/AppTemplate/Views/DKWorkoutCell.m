//
//  DKWorkoutCell.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 6/5/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKWorkoutCell.h"
#import "NIKFontAwesomeIconFactory.h"
#import "NIKFontAwesomeIconFactory+iOS.h"

@interface DKWorkoutCell ()

@property (nonatomic, strong) UIView *lineView;

@end

@implementation DKWorkoutCell

@synthesize workout = _workout;
@synthesize delegate = _delegate;
@synthesize lineView = _lineView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        self.userInteractionEnabled = YES;
        self.selectedBackgroundView = nil;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.textLabel.font = [UIFont fontWithName:ApplicationFont size:18];
        self.textLabel.textColor = [UIColor whiteColor];
        self.textLabel.numberOfLines = 2;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.textLabel.textAlignment = NSTextAlignmentLeft;
                
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.textLabel.backgroundColor = [UIColor clearColor];
        
        _lineView = [[UIView alloc] initWithFrame:CGRectMake(5, self.frame.size.height - 1, self.frame.size.width - 10, 1)];
        
        _lineView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.4];
        _lineView.alpha = 0.5;
        
        [self.contentView addSubview:_lineView];
    }
    return self;
}


- (void)setWorkout:(Workout *)workout {
    _workout = workout;
    
    [self updateUI];
}

- (void)updateUI {
    
    self.textLabel.text = self.workout.title;
    
    [self layoutSubviews];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.textLabel.frame = CGRectMake(5, 0, (self.frame.size.width - 10), self.frame.size.height);
    
    self.lineView.frame = CGRectMake(5, self.frame.size.height - 1, self.frame.size.width - 10, 1);
}

@end
