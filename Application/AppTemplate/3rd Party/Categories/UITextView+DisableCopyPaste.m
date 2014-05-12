//
//  UITextView+DisableCopyPaste.m
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 3/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "UITextView+DisableCopyPaste.h"

@implementation UITextView (DisableCopyPaste)

- (BOOL)canBecomeFirstResponder {
    return YES;
}

@end
