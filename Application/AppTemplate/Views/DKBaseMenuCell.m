//
//  DKBaseMenuCell.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 22/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKBaseMenuCell.h"

@interface DKBaseMenuCell ()

@end

@implementation DKBaseMenuCell

@synthesize settingKey = _settingKey;
@synthesize valueFormat = _valueFormat;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.userInteractionEnabled = YES;
        self.selectedBackgroundView = nil;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.textLabel.font = [UIFont fontWithName:ApplicationFont size:20];
        self.textLabel.textColor = [UIColor whiteColor];
        self.textLabel.numberOfLines = 1;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.textLabel.textAlignment = NSTextAlignmentLeft;
        
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.textLabel.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setSettingKey:(NSString *)settingKey {
    _settingKey = settingKey;
    
    [self updateUI];
}

- (void)updateUI {
}

@end
