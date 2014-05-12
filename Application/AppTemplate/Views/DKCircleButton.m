//
//  DKCircleButton.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 23/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKCircleButton.h"

@interface DKCircleButton ()

@property (nonatomic, strong) UIView *highLightView;

@end

@implementation DKCircleButton

@synthesize highLightView = _highLightView;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        _highLightView = [[UIView alloc] initWithFrame:frame];
        
        _highLightView.userInteractionEnabled = YES;
        _highLightView.alpha = 0;
        _highLightView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
        
        [self addSubview:_highLightView];        
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateMaskToBounds:self.bounds];
}

- (void)setHighlighted:(BOOL)highlighted {
    
    if(highlighted) {
        self.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:1.0].CGColor;

        self.highLightView.alpha = 1;

        __weak typeof(self) this = self;
        
        [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            
            this.highLightView.alpha = 0.0;
            
        } completion:^(BOOL finished) {
            
        }];
    }
    else {
        self.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7].CGColor;
    }
}

- (void)updateMaskToBounds:(CGRect)maskBounds {
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    
    CGPathRef maskPath = CGPathCreateWithEllipseInRect(maskBounds, NULL);
    
    maskLayer.bounds = maskBounds;
    maskLayer.path = maskPath;
    maskLayer.fillColor = [UIColor blackColor].CGColor;
    
    CGPoint point = CGPointMake(maskBounds.size.width/2, maskBounds.size.height/2);
    maskLayer.position = point;
    
    [self.layer setMask:maskLayer];
    
    self.layer.cornerRadius = CGRectGetHeight(maskBounds) / 2.0;
    self.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7].CGColor;
    self.layer.borderWidth = 3.0f;
    
    self.highLightView.frame = self.bounds;
}

@end
