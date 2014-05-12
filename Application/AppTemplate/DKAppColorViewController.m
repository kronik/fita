//
//  DKAppColorViewController.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 11/5/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKAppColorViewController.h"
#import "DKPurchaseViewController.h"

#define DKAppColorViewControllerCellId @"DKAppColorViewControllerCellId"

@interface DKAppColorViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, strong) UIImage *originalBackgroundImage;

@end

@implementation DKAppColorViewController

@synthesize colors = _colors;
@synthesize originalBackgroundImage = _originalBackgroundImage;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.colors = @[[UIColor flatRedColor],
                    [UIColor flatDarkRedColor],
                    [UIColor flatGreenColor],
                    [UIColor flatDarkGreenColor],
                    [UIColor flatBlueColor],
                    [UIColor flatDarkBlueColor],
                    [UIColor colorWithRed:0.29 green:0.59 blue:0.81 alpha:1],
                    [UIColor flatTealColor],
                    [UIColor flatDarkTealColor],
                    [UIColor flatPurpleColor],
                    [UIColor flatDarkPurpleColor],
                    [UIColor flatYellowColor],
                    [UIColor flatDarkYellowColor],
                    [UIColor flatOrangeColor],
                    [UIColor flatDarkOrangeColor],
                    [UIColor flatGrayColor],
                    [UIColor flatDarkGrayColor],
                    [UIColor flatBlackColor]];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 1)];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;

    [self.view addSubview: self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    
    CGRect rect = CGRectMake(0, 0, 1, 1);
    // Create a 1 by 1 pixel context
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    
    [ApplicationMainColor setFill];
    
    UIRectFill(rect);   // Fill it with your color
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.originalBackgroundImage = image;
    
    self.navigationController.navigationBar.translucent = YES;
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];

    [self.tableView reloadData];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController.navigationBar setBackgroundImage:self.originalBackgroundImage forBarMetrics:UIBarMetricsDefault];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.colors.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:DKAppColorViewControllerCellId];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DKAppColorViewControllerCellId];
        
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.textLabel.font = [UIFont fontWithName:ApplicationUltraLightFont size:30];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.numberOfLines = 1;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.textAlignment = NSTextAlignmentRight;
    }
    
//    cell.backgroundColor = self.colors[indexPath.row];
    cell.contentView.backgroundColor = self.colors[indexPath.row];
    cell.textLabel.backgroundColor = self.colors[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([[DKSettingsManager sharedInstance][kSettingThemes] boolValue] == NO) {
        
        DKPurchaseViewController *viewController = [[DKPurchaseViewController alloc] init];
        
        [self.navigationController pushViewController:viewController animated:YES];
        
        return;
    }
    
    UIColor *selectedColor = self.colors[indexPath.row];
    
    [DKSettingsManager sharedInstance][kSettingApplicationColor] = [selectedColor hexString];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAppColorDidChangeNotification object:nil];
    
    CGRect rect = CGRectMake(0, 0, 1, 1);
    // Create a 1 by 1 pixel context
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    
    [ApplicationMainColor setFill];
    
    UIRectFill(rect);   // Fill it with your color
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.originalBackgroundImage = image;

    [self.navigationController popViewControllerAnimated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

@end
