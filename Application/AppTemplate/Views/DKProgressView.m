//
//  DKProgressView.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 1/5/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKProgressView.h"

@interface DKProgressView ()

@property (nonatomic, strong) UIView *progressView;

@end

@implementation DKProgressView

@synthesize progress = _progress;
@synthesize progressView = _progressView;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.backgroundColor = [UIColor colorWithRed:0.22 green:0.45 blue:0.62 alpha:1];//[UIColor colorWithRed:0.33 green:0.84 blue:0.41 alpha:1];
        
        _progressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        
        _progressView.backgroundColor = ApplicationMainColor;
        
        [self addSubview:_progressView];
    }
    return self;
}

- (void)setProgress:(float)progress {
    
    if (progress < 0.0) {
        progress = 0.0;
    }
    
    if (progress > 1.0) {
        progress = 1.0;
    }
    
    _progress = progress;
    
    [self updateUI];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateUI];
}

- (void)updateUI {
    float newHeight = self.frame.size.height * (1 - self.progress);
 
    __weak typeof(self) this = self;
    
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        this.progressView.frame = CGRectMake(0, this.frame.size.height - newHeight, this.frame.size.width, newHeight);
    } completion:^(BOOL finished) {
        
    }];
}

@end
