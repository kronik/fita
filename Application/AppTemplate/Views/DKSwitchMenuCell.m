//
//  DKSwitchMenuCell.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 22/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKSwitchMenuCell.h"

@interface DKSwitchMenuCell ()

@property (nonatomic, strong) UISwitch *switchView;

@end

@implementation DKSwitchMenuCell

@synthesize switchView = _switchView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        _switchView = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 60, 50)];
        
        _switchView.onTintColor = [UIColor whiteColor];
        _switchView.tintColor = [UIColor whiteColor];
        
        [_switchView addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];

        [self.contentView addSubview: _switchView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _switchView.center = CGPointMake(self.frame.size.width - 40, self.frame.size.height / 2);
}

- (void)switchValueChanged: (UISwitch *)switchView {

    [[NSUserDefaults standardUserDefaults] setBool:!switchView.on forKey:self.settingKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)updateUI {
    BOOL value = [[NSUserDefaults standardUserDefaults] boolForKey:self.settingKey];
    
    [self.switchView setOn:!value animated:YES];
}

@end
