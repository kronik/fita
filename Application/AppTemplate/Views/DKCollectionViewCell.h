//
//  DKCollectionView.h
//  AppTemplate
//
//  Created by Dmitry Klimkin on 28/2/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DKCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSObject *item;

@end
