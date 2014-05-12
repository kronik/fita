//
//  DKBaseMenuCell.h
//  FitAssist
//
//  Created by Dmitry Klimkin on 22/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DKBaseMenuCell : UITableViewCell

@property (nonatomic, strong) NSString *settingKey;
@property (nonatomic, strong) NSString *valueFormat;

- (void)updateUI;

@end
