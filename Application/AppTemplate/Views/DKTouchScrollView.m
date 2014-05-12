//
//  DKTouchScrollView.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 29/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKTouchScrollView.h"

@implementation DKTouchScrollView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event {
    // If not dragging, send event to next responder
    if (!self.dragging)
        [self.nextResponder touchesBegan: touches withEvent:event];
    else
        [super touchesBegan: touches withEvent: event];
}

- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event {
    // If not dragging, send event to next responder
    if (!self.dragging)
        [self.nextResponder touchesEnded: touches withEvent:event];
    else
        [super touchesEnded: touches withEvent: event];
}

@end
