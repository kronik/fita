//
//  DKEnvironment.h
//  FitA
//
//  Created by Dmitry Klimkin on 7/5/14.
//  Copyright (c) 2014 FitA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DKEnvironment : NSObject

+ (instancetype)sharedInstance;

+ (NSString *)documentsDirectory;

@end
