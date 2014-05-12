//
//  DKMenuCell.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 21/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKMenuCell.h"

@implementation DKMenuCell

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect textRect = [self.textLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width, self.frame.size.height)
                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                     attributes:@{NSFontAttributeName: self.textLabel.font}
                                                        context:nil];

    self.imageView.center = CGPointMake(self.frame.size.width - textRect.size.width - 25 - self.imageView.frame.size.width / 2,
                                        2 + self.frame.size.height / 2);

//    self.imageView.center = CGPointMake(10 + self.imageView.frame.size.width / 2, 2 + self.frame.size.height / 2);
}

@end
