//
//  DKCollectionViewController.h
//  AppTemplate
//
//  Created by Dmitry Klimkin on 27/2/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKBaseViewController.h"
#import "DKCollectionViewCell.h"

@interface DKCollectionViewController : DKBaseViewController

@property (nonatomic, strong) UICollectionView *collectionView;

- (void)configureCell:(DKCollectionViewCell *)cell atIndex:(NSIndexPath*)indexPath;
- (void)registerCellClassesForCollectionView: (UICollectionView *)collectionView;
- (void)didSelectItem: (NSObject *)item atIndex:(NSIndexPath*)indexPath;

@end
