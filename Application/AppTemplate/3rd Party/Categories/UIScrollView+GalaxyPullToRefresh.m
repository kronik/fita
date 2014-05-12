//
// UIScrollView+GalaxyPullToRefresh.m
// Galaxy Pull Demo
//
//  Created by Dmitry Klimkin on 5/5/13.
//  Copyright (c) 2013 Dmitry Klimkin. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "UIScrollView+GalaxyPullToRefresh.h"
#import "DKCircleImageView.h"

#define ScreenWidth  [[UIScreen mainScreen] bounds].size.width
#define ScreenHeight [[UIScreen mainScreen] bounds].size.height

#define GalaxyPullToRefreshViewHeight 300
#define GalaxyPullToRefreshViewTriggerAreaHeight 101
#define GalaxyPullToRefreshViewParticleSize 10.0

//Spinner rotation speed in range 0.9 - slowest, 0.01 - fastest
#define SPINNER_ROTATION_SPEED 0.25f

@interface GalaxyPullToRefreshView ()

@property (nonatomic, copy) void (^pullToRefreshActionHandler)(void);
@property (nonatomic, readwrite) GalaxyPullToRefreshState currentState;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalTopInset;
@property (nonatomic, assign) BOOL wasTriggeredByUser;
@property (nonatomic, assign) BOOL showsPullToRefresh;
@property (nonatomic, assign) BOOL isObserving;
@property (nonatomic, strong) NSArray *particles;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForLoading;
- (void)setScrollViewContentInset:(UIEdgeInsets)insets;

@end

#pragma mark - UIScrollView (GalaxyPullToRefresh)
#import <objc/runtime.h>

static char UIScrollViewPullToRefreshView;

@implementation UIScrollView (GalaxyPullToRefresh)

@dynamic pullToRefreshController, showsPullToRefresh;

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler andOffset: (float)offset {
    
    if (!self.pullToRefreshController) {
        GalaxyPullToRefreshView *view = [[GalaxyPullToRefreshView alloc] initWithFrame:CGRectMake(0, -GalaxyPullToRefreshViewHeight, self.bounds.size.width, GalaxyPullToRefreshViewHeight)];
        view.pullToRefreshActionHandler = actionHandler;
        view.scrollView = self;
        view.backgroundColor = [UIColor clearColor];
        
        [self addSubview:view];
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
            view.originalTopInset = self.contentInset.top;
        } else {
            view.originalTopInset = offset;
        }
        
        self.pullToRefreshController = view;
        self.showsPullToRefresh = YES;
    }
}
    
- (void)removePullToRefresh {

    if (self.pullToRefreshController == nil) {
        return;
    }
    
    if (self.pullToRefreshController.isObserving) {
        [self.pullToRefreshController.scrollView removeObserver:self.pullToRefreshController forKeyPath:@"contentOffset"];
        [self.pullToRefreshController.scrollView removeObserver:self.pullToRefreshController forKeyPath:@"frame"];
        
        self.pullToRefreshController.isObserving = NO;
    }

    self.pullToRefreshController.pullToRefreshActionHandler = nil;
    
    [self.pullToRefreshController removeFromSuperview];
    
    self.pullToRefreshController = nil;
    self.showsPullToRefresh = NO;
}

- (void)triggerPullToRefresh {
    self.pullToRefreshController.currentState = GalaxyPullToRefreshStateTriggered;
    [self.pullToRefreshController startAnimating];
}

- (void)setViewToHide:(UIView *)viewToHide {
    self.pullToRefreshController.viewToHide = viewToHide;
}

- (void)setPullToRefreshController:(GalaxyPullToRefreshView *)pullToRefreshView {
    [self willChangeValueForKey:@"GalaxyPullToRefreshView"];
    objc_setAssociatedObject(self, &UIScrollViewPullToRefreshView,
                             pullToRefreshView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"GalaxyPullToRefreshView"];
}

- (GalaxyPullToRefreshView *)pullToRefreshController {
    return objc_getAssociatedObject(self, &UIScrollViewPullToRefreshView);
}

- (void)setShowsPullToRefresh:(BOOL)showsPullToRefresh {
    self.pullToRefreshController.hidden = !showsPullToRefresh;
    
//    if (!showsPullToRefresh) {
//        if (self.pullToRefreshController.isObserving) {
//            
//            [self removeObserver:self.pullToRefreshController forKeyPath:@"contentOffset"];
//            [self removeObserver:self.pullToRefreshController forKeyPath:@"frame"];
//            //[self.pullToRefreshController resetScrollViewContentInset];
//            
//            self.pullToRefreshController.isObserving = NO;
//        }
//    }
//    else
        if (!self.pullToRefreshController.isObserving) {
        [self addObserver:self.pullToRefreshController forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        [self addObserver:self.pullToRefreshController forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
        
        self.pullToRefreshController.isObserving = YES;
      }
}

- (BOOL)showsPullToRefresh {
    return !self.pullToRefreshController.hidden;
}

@end

#pragma mark - GalaxyPullToRefresh
@implementation GalaxyPullToRefreshView

// public properties
@synthesize pullToRefreshActionHandler;

@synthesize currentState = _state;
@synthesize scrollView = _scrollView;
@synthesize showsPullToRefresh = _showsPullToRefresh;
@synthesize particles = _particles;
@synthesize viewToHide = _viewToHide;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        NSArray * circleColors = @[
                             [UIColor colorWithRed:0.42 green:0.8 blue:0.81 alpha:1],
                             [UIColor colorWithRed:0.91 green:0.12 blue:0.62 alpha:1],
                             [UIColor colorWithRed:0.42 green:0.8 blue:0.81 alpha:1],
                             [UIColor colorWithRed:0.94 green:0.4 blue:0.17 alpha:1],
                             [UIColor colorWithRed:0.84 green:0 blue:0.35 alpha:1],
                             [UIColor colorWithRed:1 green:0.9 blue:0.2 alpha:1],
                             [UIColor colorWithRed:0.95 green:0.48 blue:0.2 alpha:1]
                         ];
        
        // default styling values
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.currentState = GalaxyPullToRefreshStateStopped;
        
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;
        
        int colorIndex = arc4random() % circleColors.count;
                
        bottomLeftView = [[DKCircleImageView alloc] initWithImage:[UIImage imageNamed:@"bubble_orange"]];
        bottomLeftView.frame = CGRectMake(0, 0, GalaxyPullToRefreshViewParticleSize, GalaxyPullToRefreshViewParticleSize);
        bottomLeftView.backgroundColor = [UIColor clearColor];
        bottomLeftView.center = CGPointMake(10, self.frame.size.height - bottomLeftView.frame.size.height - GalaxyPullToRefreshViewParticleSize);
        bottomLeftView.backgroundColor = circleColors[colorIndex];
        
        colorIndex = (colorIndex + 1) % circleColors.count;
        
        [self addSubview: bottomLeftView];
        
        bottomRightView = [[DKCircleImageView alloc] initWithImage:[UIImage imageNamed:@"bubble_blue"]];
        bottomRightView.frame = CGRectMake(0, 0, GalaxyPullToRefreshViewParticleSize, GalaxyPullToRefreshViewParticleSize);
        bottomRightView.backgroundColor = [UIColor clearColor];
        bottomRightView.center = CGPointMake(ScreenWidth - 10, self.frame.size.height - bottomRightView.frame.size.height - GalaxyPullToRefreshViewParticleSize);
        bottomRightView.backgroundColor = circleColors[colorIndex];
        
        colorIndex = (colorIndex + 1) % circleColors.count;
        
        [self addSubview: bottomRightView];
        
        topLeftView = [[DKCircleImageView alloc] initWithImage:[UIImage imageNamed:@"bubble_blue"]];
        topLeftView.frame = CGRectMake(0, 0, GalaxyPullToRefreshViewParticleSize, GalaxyPullToRefreshViewParticleSize);
        topLeftView.backgroundColor = [UIColor clearColor];
        topLeftView.center = CGPointMake(ScreenWidth - 10, self.frame.size.height - topLeftView.frame.size.height - GalaxyPullToRefreshViewParticleSize);
        topLeftView.backgroundColor = circleColors[colorIndex];
        
        colorIndex = (colorIndex + 1) % circleColors.count;

        [self addSubview: topLeftView];
        
        topRightView = [[DKCircleImageView alloc] initWithImage:[UIImage imageNamed:@"bubble_orange"]];
        topRightView.frame = CGRectMake(0, 0, GalaxyPullToRefreshViewParticleSize, GalaxyPullToRefreshViewParticleSize);
        topRightView.backgroundColor = [UIColor clearColor];
        topRightView.center = CGPointMake(ScreenWidth - 10, self.frame.size.height - topRightView.frame.size.height - 5);
        topRightView.backgroundColor = circleColors[colorIndex];
        
        colorIndex = (colorIndex + 1) % circleColors.count;

        [self addSubview: topRightView];
        
        progressIndicatorView = [[DKCircleImageView alloc] initWithImage:[UIImage imageNamed:@"bubble_grey_large"]];
        progressIndicatorView.backgroundColor = [UIColor whiteColor];
        progressIndicatorView.frame = CGRectMake(0, 0, 47, 47);
        progressIndicatorView.center = CGPointMake(ScreenWidth / 2, self.frame.size.height - 50);
        progressIndicatorView.alpha = 0.0;
        
        UILabel *label = [[UILabel alloc] initWithFrame:progressIndicatorView.bounds];
        
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont fontWithName:ApplicationLightFont size:35];
        label.textColor = [UIColor grayColor];
        label.text = @"*";
        
        [progressIndicatorView addSubview: label];

        [self addSubview: progressIndicatorView];
        
        _particles = @[bottomLeftView, bottomRightView, topLeftView, topRightView];
        
        for (int i=0; i<self.particles.count; i++) {
            UIView *particleView = self.particles [i];
            particleView.alpha = 1.0;
        }
        
        innerBallView = [[DKCircleImageView alloc] initWithImage:[UIImage imageNamed:@"bubble_blue"]];
        innerBallView.frame = CGRectMake(0, 0, GalaxyPullToRefreshViewParticleSize, GalaxyPullToRefreshViewParticleSize);
        innerBallView.backgroundColor = [UIColor clearColor];
        innerBallView.center = CGPointMake(ScreenWidth / 2, self.frame.size.height - GalaxyPullToRefreshViewTriggerAreaHeight / 2 + progressIndicatorView.frame.size.width / 2);
        innerBallView.backgroundColor = circleColors[arc4random() % circleColors.count];

        //[self addSubview: innerBallView];
        
        barOffset = 0;
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
            barOffset = ApplicationNavigationAndStatusBarHeight;
        }
    }

    return self;
}

- (void)setViewToHide:(UIView *)viewToHide {
    _viewToHide = viewToHide;
}
- (void)dealloc {
    
    [self.layer removeAllAnimations];
    
    [animationTimer invalidate];
    animationTimer = nil;    
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview && newSuperview == nil) {
        //use self.superview, not self.scrollView. Why self.scrollView == nil here?
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (scrollView.showsPullToRefresh) {
            if (self.isObserving) {
                //If enter this branch, it is the moment just before "GalaxyPullToRefreshView's dealloc", so remove observer here
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
                [scrollView removeObserver:self forKeyPath:@"frame"];
                
                self.isObserving = NO;
            }
        }
    }
}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = self.originalTopInset;
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForLoading {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = GalaxyPullToRefreshViewTriggerAreaHeight + currentInsets.top;
        
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = contentInset;
                         //self.scrollView.contentOffset = CGPointMake(0, -self.originalTopInset);
                     }
                     completion:^(BOOL finished) {
                         [self contentOffsetChanged:0 andDelta:0];
                     }];
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        
        CGPoint newPoint = [change [NSKeyValueChangeNewKey] CGPointValue];
        CGPoint oldPoint = [change [NSKeyValueChangeOldKey] CGPointValue];
        
        CGFloat deltaY = newPoint.y - oldPoint.y;

        [self contentOffsetChanged: oldPoint.y + self.originalTopInset andDelta:deltaY];
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    } else {
        if ([keyPath isEqualToString:@"frame"]) {
            [self layoutSubviews];
        }
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if (self.currentState != GalaxyPullToRefreshStateLoading) {
        
        CGFloat scrollOffsetThreshold = self.frame.origin.y - self.originalTopInset;

        if (!self.scrollView.isDragging && self.currentState == GalaxyPullToRefreshStateTriggered) {
            self.currentState = GalaxyPullToRefreshStateLoading;
        }
        else if (((contentOffset.y < scrollOffsetThreshold) || (contentOffset.y + self.originalTopInset < -GalaxyPullToRefreshViewTriggerAreaHeight)) && self.scrollView.isDragging && self.currentState == GalaxyPullToRefreshStateStopped) {
            self.currentState = GalaxyPullToRefreshStateTriggered;
        }
        else if (contentOffset.y + self.originalTopInset >= scrollOffsetThreshold && self.currentState != GalaxyPullToRefreshStateStopped) {
            self.currentState = GalaxyPullToRefreshStateStopped;
        }
    }
}

- (void)triggerRefresh {
    [self.scrollView triggerPullToRefresh];    
}

- (void)doAnimationStepForRandomWaitingAnimation {
    float degrees = 80 + arc4random() % 200;
    float angle = (lastAngle + degrees) * M_PI / 180;
    float radius = (progressIndicatorView.frame.size.width / 2) - innerBallView.frame.size.width / 2;
    
    lastAngle += degrees;
    lastAngle = (int)lastAngle % 360;
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options: UIViewAnimationOptionCurveLinear
                     animations:^{
                         innerBallView.center = CGPointMake((ScreenWidth / 2) + radius * cos (angle), self.frame.size.height - ((GalaxyPullToRefreshViewTriggerAreaHeight / 2) + radius * sin(angle)));
                     }
                     completion:nil];
}

- (void)onAnimationTimer {
    
    if (isRefreshing) {
        [self doAnimationStepForRandomWaitingAnimation];
    } else {
        if (lastOffset < 30) {
            [animationTimer invalidate];
            animationTimer = nil;
            
            self.currentState = GalaxyPullToRefreshStateStopped;
            
            if (!self.wasTriggeredByUser) {
                [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -self.scrollView.contentInset.top) animated:YES];
            }
            
            return;
        }
        
        lastOffset -= 2;
        
        [self contentOffsetChanged:-lastOffset andDelta:0];
    }
}

- (void)startAnimating {
    if (self.scrollView.contentOffset.y == 0) {
        [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -GalaxyPullToRefreshViewTriggerAreaHeight) animated:YES];
        self.wasTriggeredByUser = NO;
    }
    else
        self.wasTriggeredByUser = YES;
    
    self.currentState = GalaxyPullToRefreshStateLoading;
    
    [animationTimer invalidate];
    animationTimer = nil;
        
//    progressIndicatorView.center = CGPointMake(ScreenWidth / 2, ((UIView *)self.particles [0]).center.y);
    
    [self updateActivityIndicatorAlpha: 1.0];

    isRefreshing = YES;
    animationStep = 0;
    
    [self startRotateAnimation];
    
    animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(onAnimationTimer) userInfo:nil repeats:YES];
    
    self.userInteractionEnabled = NO;
    self.scrollView.userInteractionEnabled = NO;
}

- (void)startRotateAnimation {
    
    if (isRefreshing == NO) {
        return;
    }
    
    __weak GalaxyPullToRefreshView *this = self;

    [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        
        for (int i=0; i<self.particles.count; i++) {
            int animationDelta = 7;
            int newX = (arc4random() % animationDelta) * ((arc4random() % 2 == 0) ? 1 : -1);
            int newY = (arc4random() % animationDelta) * ((arc4random() % 2 == 0) ? 1 : -1);
            
            UIView *viewToAnimate = self.particles[i];
            
            viewToAnimate.center = CGPointMake(progressIndicatorView.center.x + newX, progressIndicatorView.center.y + newY);
            viewToAnimate.alpha = (arc4random() % 2 == 0) ? 0.9 : 0.1;
        }
    } completion:^(BOOL finished) {
        if (finished) {
            [this startRotateAnimation];
        }
    }];

    
//    rotationAngle += M_PI / 2.0f;
//    
//    if (rotationAngle == 2.0f * M_PI) {
//        rotationAngle = 0.0f;
//    }
//    
//    if (rotationAngle != M_PI / 2.0f) {
//        [UIView beginAnimations:nil context:nil];
//        [UIView setAnimationDuration:SPINNER_ROTATION_SPEED];
//        [UIView setAnimationDelegate:self];
//        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
//        [UIView setAnimationDidStopSelector:@selector(startRotateAnimation)];
//        progressView.transform = CGAffineTransformMakeRotation(rotationAngle);
//        [UIView commitAnimations];
//    }
}

- (void)playPopSound {
}

- (void)didFinishRefresh {
    
    self.currentState = GalaxyPullToRefreshStateStopped;
    
    @synchronized (self) {
        if (isRefreshing == NO) {
            return;
        }
        isRefreshing = NO;
    }
    
    [animationTimer invalidate];
    animationTimer = nil;

    [self.layer removeAllAnimations];
    
    [self updateActivityIndicatorAlpha:0.0];
    
    for (int i=0; i<self.particles.count; i++) {
        UIView *viewToAnimate = self.particles[i];

        viewToAnimate.alpha = 1.0;
    }

    animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(onAnimationTimer) userInfo:nil repeats:YES];
    
    [self performSelector:@selector(playPopSound) withObject:nil afterDelay:0.01];
    
    self.userInteractionEnabled = YES;
    self.scrollView.userInteractionEnabled = YES;
}

- (void)setCurrentState:(GalaxyPullToRefreshState)newState {
    
    if (_state == newState)
        return;
    
    GalaxyPullToRefreshState previousState = _state;
    _state = newState;
    
    [self setNeedsLayout];
    
    switch (newState) {
        case GalaxyPullToRefreshStateStopped:
            [self resetScrollViewContentInset];
            break;
            
        case GalaxyPullToRefreshStateTriggered:
            
            if (self.hidden == NO) {
                [self startAnimating];
            } else {
                _state = GalaxyPullToRefreshStateStopped;
            }
            break;
            
        case GalaxyPullToRefreshStateLoading:
            [self setScrollViewContentInsetForLoading];
            
            if (previousState == GalaxyPullToRefreshStateTriggered && pullToRefreshActionHandler)
                pullToRefreshActionHandler();
            break;
            
        default: break;
    }
}

- (void) contentOffsetChanged:(float)contentOffset andDelta: (float)deltaY {
    
    float yPosition = ScreenHeight - self.viewToHide.frame.size.height / 2 - barOffset;
    
    if (contentOffset <= 0) {
        deltaY = 0;
    }
    
    realOffset += deltaY;
    
    if (realOffset > self.viewToHide.frame.size.height) {
        realOffset = self.viewToHide.frame.size.height;
        yPosition += realOffset;

    } else if (realOffset >= 0) {
        yPosition += realOffset;
    } else {
        realOffset = 0;
    }

    self.viewToHide.center = CGPointMake(self.viewToHide.center.x, yPosition);
    
    contentOffset = -contentOffset / 2;
    
    if (isRefreshing) {
        return;
    }
    
    if (contentOffset < 0) {
        contentOffset = 0;
    }
    
    if (contentOffset > 50) {
        contentOffset = 50;
    }
    
    float newOffset = contentOffset * 2;
    if (lastOffset != newOffset) {
        lastOffset = newOffset;
        
        CGPoint point = [self calcNewCurvePointForBottomLeftViewForOffset: contentOffset];
        CGPoint point2 = [self calcNewCurvePointForBottomRightViewForOffset: contentOffset];
            
        float ratio = (contentOffset / 1.3);
        
        bottomLeftView.frame = CGRectMake(0, 0, GalaxyPullToRefreshViewParticleSize + ratio, GalaxyPullToRefreshViewParticleSize + ratio);
        bottomRightView.frame = CGRectMake(0, 0, GalaxyPullToRefreshViewParticleSize + ratio, GalaxyPullToRefreshViewParticleSize + ratio);
        
        topLeftView.frame = CGRectMake(0, 0, GalaxyPullToRefreshViewParticleSize + ratio, GalaxyPullToRefreshViewParticleSize + ratio);
        topRightView.frame = CGRectMake(0, 0, GalaxyPullToRefreshViewParticleSize + ratio, GalaxyPullToRefreshViewParticleSize + ratio);
        
        if (contentOffset == 50.0) {
            for (int i=0; i<self.particles.count; i++) {
                UIView *particleView = self.particles [i];
                
                particleView.center = CGPointMake(ScreenWidth / 2, self.frame.size.height - contentOffset);
            }
        } else {
            bottomLeftView.center = CGPointMake(point.x, point.y);
            bottomRightView.center = CGPointMake(ScreenWidth - point2.x, self.frame.size.height - 100 + (self.frame.size.height - point2.y));
            
            topRightView.center = CGPointMake(ScreenWidth - point.x, self.frame.size.height - 100 + (self.frame.size.height - point.y));
            topLeftView.center = point2;
        }
    }
}

- (CGPoint) calcNewCurvePointForBottomLeftViewForOffset: (float)contentOffset {
    
    contentOffset *= 2;
    contentOffset = (contentOffset) * M_PI / 180;
    
    float radius = 130.0;
    
    return CGPointMake((ScreenWidth / 2) + 22.5 + radius * cos (contentOffset), self.frame.size.height - ((GalaxyPullToRefreshViewTriggerAreaHeight / 4) + radius * sin(contentOffset)) + 103);
}


- (CGPoint) calcNewCurvePointForBottomRightViewForOffset: (float)contentOffset {
    
    contentOffset *= 2;
    contentOffset = (contentOffset + GalaxyPullToRefreshViewTriggerAreaHeight / 2) * M_PI / 180;
    
    float radius = 130.0;
    
    CGPoint point =  CGPointMake((ScreenWidth / 2) + 110 + radius * cos (contentOffset), self.frame.size.height - ((GalaxyPullToRefreshViewTriggerAreaHeight / 4) + radius * sin(contentOffset)) + 40);
    
    return point;
}

- (void)updateActivityIndicatorAlpha: (float)newAlpha {
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options: UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         progressIndicatorView.alpha = newAlpha;
                     }
                     completion:nil];
}

@end

