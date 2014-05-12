//
//  DKAutoTableViewController.m
//  AppTemplate
//
//  Created by Dmitry Klimkin on 1/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKAutoTableViewController.h"
#import <objc/runtime.h>

@interface DKAutoTableViewController ()

@end

@implementation DKAutoTableViewController

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
    
    [self.tableView removeFromSuperview];
    self.tableView = nil;
    
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([DKBaseViewController class], &outCount);
    for(i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        fprintf(stdout, "%s %s\n", property_getName(property), property_getAttributes(property));
    }
    free(properties);
    
}


@end
