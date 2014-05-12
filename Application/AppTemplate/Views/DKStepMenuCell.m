//
//  DKStepMenuCell.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 22/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKStepMenuCell.h"

@interface DKStepMenuCell ()

@property (nonatomic, strong) UIStepper *stepperView;

@end

@implementation DKStepMenuCell

@synthesize stepperView = _stepperView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        _stepperView = [[UIStepper alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        
        _stepperView.tintColor = [UIColor whiteColor];
        _stepperView.maximumValue = 100;
        _stepperView.minimumValue = 0;
        _stepperView.stepValue = 1;
        
        [_stepperView addTarget:self action:@selector(stepValueChanged:) forControlEvents:UIControlEventValueChanged];
        
        [self.contentView addSubview: _stepperView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _stepperView.center = CGPointMake(self.frame.size.width - 60, self.frame.size.height / 2);
}

- (void)stepValueChanged: (UIStepper *)stepperView {
    
    self.textLabel.text = [NSString stringWithFormat:self.valueFormat, ((NSInteger)stepperView.value)];
    
    [[NSUserDefaults standardUserDefaults] setInteger:((NSInteger)stepperView.value) forKey:self.settingKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)updateUI {
    NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:self.settingKey];

    self.textLabel.text = [NSString stringWithFormat:self.valueFormat, value];

    self.stepperView.value = value;
}

@end
