//
//  DKGlassScrollViewController.h
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 26/2/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

@import UIKit;

#import "DKBaseViewController.h"
#import "DKWeatherManager.h"

#import "BTGlassScrollView.h"

@interface DKWeatherViewController : DKBaseViewController

@property (nonatomic, assign) int index;
@property (nonatomic, strong) BTGlassScrollView *glassScrollView;

- (id)initWithLatitude: (double)latitude
          andLongitude: (double)longitude;

@end
