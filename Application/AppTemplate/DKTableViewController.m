//
//  DKTableViewController.m
//  AppTemplate
//
//  Created by Dmitry Klimkin on 1/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKTableViewController.h"

#define DKTableViewCellId @"regularTableViewCellIdentifier"

@interface DKTableViewController () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation DKTableViewController

@synthesize tableView = _tableView;

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
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    [self.view addSubview: self.tableView];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (DKTableViewCell *)prepareCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DKTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:DKTableViewCellId];
    
    if (cell == nil) {
        cell = [[DKTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:DKTableViewCellId];
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    DKTableViewCell *cell = [self prepareCellForRowAtIndexPath:indexPath];
	[self configureCell:cell atIndex:indexPath];
    
    return cell;
}

- (void)registerCellClassesForTableView: (UITableView *)tableView {
    [tableView registerClass:[DKTableViewCell class] forCellReuseIdentifier:DKTableViewCellId];
}

- (void)configureCell:(DKTableViewCell *)cell atIndex:(NSIndexPath*)indexPath {
    if (indexPath.row < self.items.count) {
        cell.item = self.items[indexPath.row];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void) didSelectItem: (NSObject *)item atIndexPath: (NSIndexPath *)indexPath {
    
}

- (void)deleteItem: (NSObject *)item atIndexPath: (NSIndexPath *)indexPath {
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row < self.items.count) {
        [self didSelectItem: self.items [indexPath.row] atIndexPath:indexPath];
    } else {
        [self didSelectItem: nil atIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSObject *item = self.items [indexPath.row];

        [self deleteItem: item atIndexPath:indexPath];
        [self.items removeObjectAtIndex:indexPath.row];

        [tableView reloadData];
//
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end
