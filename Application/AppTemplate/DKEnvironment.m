//
//  BMEnvironment.m
//  FitA
//
//  Created by Dmitry Klimkin on 7/5/14.
//  Copyright (c) 2014 FitA. All rights reserved.
//

#import "DKEnvironment.h"

@implementation DKEnvironment

+ (instancetype)sharedInstance {
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}

- (id)init {
    self = [super init];
    
	if (self != nil) {
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (NSString *)documentsDirectory {
	static NSString *documentsDirectory = nil;
    
	if (!documentsDirectory) {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		documentsDirectory = paths.firstObject;
	}
    
	return documentsDirectory;
}

@end
