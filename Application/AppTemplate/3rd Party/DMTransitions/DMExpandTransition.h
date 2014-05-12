//
//  DMExpandTransition.h
//  DMCustomTransition
//
//  Created by Thomas Ricouard on 26/11/13.
//  Copyright (c) 2013 Thomas Ricouard. All rights reserved.
//

#import "DMBaseTransition.h"

@interface DMExpandTransition : DMBaseTransition

@property (nonatomic) CGRect initialRect;
@property (nonatomic, strong) UIImage *initialImage;
@property (nonatomic, strong) NSString *bgImageName;

@end
