//
//  DKDayCommentCell.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 6/5/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKDayCommentCell.h"

@implementation DKDayCommentCell

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.textLabel.frame = CGRectMake(5, 0, (self.frame.size.width - 10), self.frame.size.height);
}

@end
