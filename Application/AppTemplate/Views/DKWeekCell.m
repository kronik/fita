//
//  DKWeekself.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 20/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKWeekCell.h"
#import "DKCircleButton.h"

#import "NIKFontAwesomeIconFactory.h"
#import "NIKFontAwesomeIconFactory+iOS.h"

@interface DKWeekCell ()

@property (nonatomic, strong) DKCircleButton *imageButton;
@property (nonatomic, strong) UIImage *emptyImage;
@property (nonatomic) int weekShift;

@end

@implementation DKWeekCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        self.userInteractionEnabled = YES;
        self.selectedBackgroundView = nil;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.textLabel.font = [UIFont fontWithName:ApplicationLightFont size:30];
        self.textLabel.textColor = [UIColor whiteColor];
        self.textLabel.numberOfLines = 1;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.textLabel.textAlignment = NSTextAlignmentRight;
        
        self.imageButton = [DKCircleButton buttonWithType:UIButtonTypeCustom];
        
        self.imageButton.frame = CGRectZero;
        self.imageButton.backgroundColor = ApplicationMainColor;
        self.imageButton.clipsToBounds = YES;
        self.imageButton.layer.borderColor = [UIColor whiteColor].CGColor;
        self.imageButton.layer.borderWidth = 1.0;
        self.imageButton.titleLabel.font = [UIFont fontWithName:ApplicationFont size:30];
        self.imageButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        [self.imageButton addTarget:self action:@selector(tapOnImageButton) forControlEvents:UIControlEventTouchUpInside];
        
        [self.imageButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.imageButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateSelected];
        [self.imageButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        
        [self.contentView addSubview: self.imageButton];

        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.textLabel.backgroundColor = [UIColor clearColor];
        
        NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory generalFactory];
        
        factory.colors = @[[UIColor whiteColor]];
        factory.size = 40;

        self.emptyImage = [factory createImageForIcon:NIKFontAwesomeIconCameraRetro];
    }
    return self;
}


- (void)tapOnImageButton {
    if ([self.delegate respondsToSelector:@selector(didTapOnPhotoOfWeek:inView:)]) {
        [self.delegate didTapOnPhotoOfWeek:self.week inView:self];
    }
}

- (void)setWeek:(DKWeek *)week withShift: (int)shift {
    _week = week;
    _weekShift = shift;
    
    [self updateUI];
}

- (void)setWeek:(DKWeek *)week {
    _week = week;
    
    [self updateUI];
}

- (void)updateUI {
    self.textLabel.text = NSLocalizedString(@"Week", nil);
    
    NSString *buttonTitle = [NSString stringWithFormat:@"%ld", self.week.seqNumber + self.weekShift];
    
    [self.imageButton setTitle:buttonTitle forState:UIControlStateNormal];
    [self.imageButton setTitle:buttonTitle forState:UIControlStateSelected];
    [self.imageButton setTitle:buttonTitle forState:UIControlStateHighlighted];

    self.textLabel.text = [NSString stringWithFormat:@"%@ %ld", NSLocalizedString(@"Week", nil), self.week.seqNumber + self.weekShift];
    [self layoutSubviews];
}

@end
