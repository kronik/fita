//
//  DKCollectionViewController.m
//  AppTemplate
//
//  Created by Dmitry Klimkin on 27/2/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKCollectionViewController.h"
#import "THSpringyFlowLayout.h"
#import "DVCollectionViewFlowLayout.h"

#define DKCollectionViewCellId @"regularCollectionViewCellIdentifier"

@interface DKCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate>


@end

@implementation DKCollectionViewController

@synthesize collectionView = _collectionView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    THSpringyFlowLayout *flowLayout = [[THSpringyFlowLayout alloc] init];
    
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.itemSize = CGSizeMake (ScreenWidth, 50);

    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout: flowLayout];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.opaque = NO;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    self.collectionView.backgroundView = nil;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.bounces = YES;

    [self.view addSubview: self.collectionView];
    
    [self registerCellClassesForCollectionView: self.collectionView];
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource & Delegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DKCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:DKCollectionViewCellId
                                                                           forIndexPath:indexPath];
	[self configureCell:cell atIndex:indexPath];

    return cell;
}

- (void)registerCellClassesForCollectionView: (UICollectionView *)collectionView {
    [collectionView registerClass:[DKCollectionViewCell class]
       forCellWithReuseIdentifier:DKCollectionViewCellId];
}

- (void)configureCell:(DKCollectionViewCell *)cell atIndex:(NSIndexPath*)indexPath {
}

//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
//    return YES;
//}

- (void) didSelectItem: (NSObject *)item atIndex:(NSIndexPath*)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row < self.items.count) {
        [self didSelectItem: self.items [indexPath.row] atIndex:indexPath];
    }
}

@end
