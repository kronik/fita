//
//  DKButtonCell.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 11/5/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKButtonCell.h"

@interface DKButtonCell ()

@property (nonatomic, strong) UIView *lineView;

@end

@implementation DKButtonCell

@synthesize lineView = _lineView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        _lineView = [[UIView alloc] initWithFrame:CGRectMake(5, self.frame.size.height - 1, self.frame.size.width - 10, 1)];
        
        _lineView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.4];
        _lineView.alpha = 0.5;
        
        [self.contentView addSubview:_lineView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.textLabel.frame = CGRectMake(5, 0, (self.frame.size.width - 10), self.frame.size.height);
    self.lineView.frame = CGRectMake(5, self.frame.size.height - 1, self.frame.size.width - 10, 1);
}

@end
