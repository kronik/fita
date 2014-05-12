//
// UIScrollView+GalaxyPullToRefresh.h
// Galaxy Pull Demo
//
//  Created by Dmitry Klimkin on 5/5/13.
//  Copyright (c) 2013 Dmitry Klimkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DKCircleImageView.h"
#import "MRActivityIndicatorView.h"

typedef enum {
    GalaxyPullToRefreshStateStopped = 0,
    GalaxyPullToRefreshStateTriggered,
    GalaxyPullToRefreshStateLoading
} GalaxyPullToRefreshState;

@class GalaxyPullToRefreshView;

@interface UIScrollView (GalaxyPullToRefresh)

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler andOffset: (float)offset;
- (void)triggerPullToRefresh;
- (void)setViewToHide: (UIView *)viewToHide;
- (void)removePullToRefresh;

@property (nonatomic, strong, readonly) GalaxyPullToRefreshView *pullToRefreshController;
@property (nonatomic, assign) BOOL showsPullToRefresh;

@end

@interface GalaxyPullToRefreshView : UIImageView {
    DKCircleImageView *bottomLeftView;
    DKCircleImageView *bottomRightView;
    
    DKCircleImageView *topLeftView;
    DKCircleImageView *topRightView;
    
    DKCircleImageView *progressIndicatorView;
    DKCircleImageView *innerBallView;
    
    float rotationAngle;
    BOOL isRefreshing;
    NSTimer *animationTimer;
    float lastOffset;
    float lastAngle;
    int animationStep;
    
    float realOffset;
    float barOffset;
}

@property (nonatomic, readonly) GalaxyPullToRefreshState currentState;
@property (nonatomic, weak) UIView *viewToHide;

- (void)startAnimating;
- (void)didFinishRefresh;

@end