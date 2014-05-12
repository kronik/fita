//
//  DKTableViewController.h
//  AppTemplate
//
//  Created by Dmitry Klimkin on 1/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKBaseViewController.h"
#import "DKTableViewCell.h"

@interface DKTableViewController : DKBaseViewController

@property (nonatomic, strong) UITableView *tableView;

- (void)configureCell:(DKTableViewCell *)cell atIndex:(NSIndexPath*)indexPath;
- (void)registerCellClassesForTableView: (UITableView *)tableView;
- (void)didSelectItem: (NSObject *)item atIndexPath: (NSIndexPath *)indexPath;
- (void)deleteItem: (NSObject *)item atIndexPath: (NSIndexPath *)indexPath;

@end
