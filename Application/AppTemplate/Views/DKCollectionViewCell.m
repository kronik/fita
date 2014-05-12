//
//  DKCollectionView.m
//  AppTemplate
//
//  Created by Dmitry Klimkin on 28/2/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKCollectionViewCell.h"

@interface DKCollectionViewCell ()


@end

@implementation DKCollectionViewCell

@synthesize item = _item;
@synthesize title = _title;
@synthesize label = _label;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        _label = [[UILabel alloc] initWithFrame:frame];
        _label.font = [UIFont fontWithName:ApplicationLightFont size:14];
        
        [self.contentView addSubview: _label];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.label.frame = self.bounds;
}

- (void)setTitle:(NSString *)title {
    _title = title;
    
    self.label.text = title;
}

- (void)setItem:(NSObject *)item {
    _item = item;
    
    self.title = [item description];
}

@end
