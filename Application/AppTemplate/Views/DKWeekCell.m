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

@synthesize week = _week;
@synthesize delegate = _delegate;
@synthesize imageButton = _imageButton;
@synthesize emptyImage = _emptyImage;
@synthesize weekShift = _weekShift;

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

- (void)setWeek:(Week *)week withShift: (int)shift {
    _week = week;
    _weekShift = shift;
    
    [self updateUI];
}

- (void)setWeek:(Week *)week {
    _week = week;
    
    [self updateUI];
}

- (void)updateUI {
//    [self.imageButton setBackgroundImage:[UIImage imageWithData:self.week.image] forState:UIControlStateNormal];

    self.textLabel.text = NSLocalizedString(@"Week", nil);
    
    NSString *buttonTitle = [NSString stringWithFormat:@"%d", [self.week.seqNumber intValue] + self.weekShift];
    
    [self.imageButton setTitle:buttonTitle forState:UIControlStateNormal];
    [self.imageButton setTitle:buttonTitle forState:UIControlStateSelected];
    [self.imageButton setTitle:buttonTitle forState:UIControlStateHighlighted];

//    if (self.week.image == nil) {
//        [self.imageButton setImage:self.emptyImage forState:UIControlStateNormal];
//        [self.imageButton setImage:self.emptyImage forState:UIControlStateSelected];
//        [self.imageButton setImage:self.emptyImage forState:UIControlStateHighlighted];
//    } else {
//    }
    self.textLabel.text = [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"Week", nil), [self.week.seqNumber intValue] + self.weekShift];


    [self layoutSubviews];
}

//- (void)layoutSubviews {
//    [super layoutSubviews];
//    
//    float imageWidth = self.frame.size.height - 4;
//    
////    if (self.week.image == nil) {
////        self.imageButton.frame = CGRectZero;
////        self.textLabel.frame = CGRectMake(5, 5, (self.frame.size.width - 20), self.frame.size.height - 10);
////    } else {
//        self.imageButton.frame = CGRectMake(self.frame.size.width - imageWidth - 15, 2, imageWidth, imageWidth);
//        self.textLabel.frame = CGRectMake(5, 5, (self.frame.size.width - imageWidth - 35), self.frame.size.height - 10);
////    }
//}

@end
