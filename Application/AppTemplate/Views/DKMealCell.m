//
//  DKMealCell.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 19/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKMealCell.h"
#import "DKCircleButton.h"

@interface DKMealCell ()

@property (nonatomic, strong) UIView *lineView;

@end

@implementation DKMealCell

@synthesize lineView = _lineView;
@synthesize isCorrect = _isCorrect;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        _lineView = [[UIView alloc] initWithFrame:CGRectMake(5, self.frame.size.height - 1, self.frame.size.width - 10, 1)];
        
        _lineView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.4];
        _lineView.alpha = 0.5;
        
        [self.contentView addSubview:_lineView];
        
        self.imageView.layer.cornerRadius = 3;
        self.imageView.clipsToBounds = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    float imageHeight = 0;
    
    if (self.imageView.image) {
        imageHeight = self.frame.size.height - 10;
        
        self.imageView.frame = CGRectMake(self.frame.size.width - imageHeight - 5, 5, imageHeight, imageHeight);
    } else {
        self.imageView.frame = CGRectZero;
    }
    
    self.detailTextLabel.frame = CGRectMake(5, 5, (self.frame.size.width - imageHeight - 20), (self.frame.size.height - 10) / 3);
    
    self.textLabel.frame = CGRectMake(5, 5 + (self.frame.size.height - 10) / 3,
                                      (self.frame.size.width - imageHeight - 10),
                                      (self.frame.size.height - 10) * 2 / 3);
    
    self.lineView.frame = CGRectMake(5, self.frame.size.height - 1, self.frame.size.width - 10, 1);
}

- (void)setIsCorrect:(BOOL)isCorrect {
    _isCorrect = isCorrect;
    
    self.detailTextLabel.textColor = isCorrect ? [UIColor whiteColor] : [UIColor redColor];
}

@end
