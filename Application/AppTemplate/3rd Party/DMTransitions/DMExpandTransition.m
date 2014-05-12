//
//  DMExpandTransition.m
//  DMCustomTransition
//
//  Created by Thomas Ricouard on 26/11/13.
//  Copyright (c) 2013 Thomas Ricouard. All rights reserved.
//

#import "DMExpandTransition.h"
#import "UIView+Screenshot.h"
#import "UIImage-JTImageCrop.h"

@implementation DMExpandTransition

@synthesize initialRect = _initialRect;
@synthesize initialImage = _initialImage;
@synthesize bgImageName = _bgImageName;

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    if (self.isPresenting) {
        return 0.5f;
    } else {
        return 0.5f;
    }
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    CGRect bgRect = CGRectMake(0, self.initialRect.origin.y - 2, containerView.frame.size.width, self.initialRect.size.height + 8);
    
    UIImageView *bgView = [[UIImageView alloc] initWithFrame:bgRect];
    
//    bgView.image = [UIImage imageWithImage:[UIImage imageNamed:self.bgImageName] cropInRect:self.initialRect];

    bgView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    
    if (self.isPresenting) {
        
        UIImageView *fromImageView = [[UIImageView alloc] initWithFrame:self.initialRect];
        
        fromImageView.image = self.initialImage;
        fromImageView.contentMode = UIViewContentModeScaleAspectFit;
        fromImageView.layer.zPosition = 1024;

        toVC.view.frame = self.initialRect;
        toVC.view.layer.zPosition = 1024;

        [containerView addSubview:bgView];
        [containerView addSubview:fromImageView];
        [containerView addSubview:toVC.view];

        CGRect fromFrame = fromVC.view.frame;
        CGRect halfwayFrame = self.initialRect;
        
        //pre-flip the destination view halfway around and hide it
        CATransform3D preTransform = CATransform3DMakeRotation(-M_PI/2, 1, 0, 0);
        preTransform.m34 = 1.0f/-500;
        toVC.view.layer.transform = preTransform;
        toVC.view.frame = halfwayFrame;
        toVC.view.hidden = YES;
        
        //perform the first half of the animation
        CATransform3D srcTransform = CATransform3DMakeRotation(M_PI/2, 1, 0, 0);
        srcTransform.m34 = 1.0f/-500;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] / 5
                         animations:^{
                             
                             fromImageView.layer.transform = srcTransform;
                             fromImageView.frame = halfwayFrame;
                             
                         } completion:^(BOOL finished) {

                             [fromImageView removeFromSuperview];
                             toVC.view.hidden = NO;
                             toVC.view.layer.borderWidth = 1;
                             toVC.view.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1].CGColor;
                             toVC.view.layer.cornerRadius = 5;

                             CATransform3D destTransform = CATransform3DMakeRotation(0, 1, 0, 0);
                             destTransform.m34 = 1.0f/-500;

                             [UIView animateWithDuration:[self transitionDuration:transitionContext] / 5
                                              animations:^{
                                                  
                                                  toVC.view.layer.transform = destTransform;
                                                  toVC.view.frame = self.initialRect;

                                              }
                                              completion:^(BOOL finished) {
                                                  
                                                  [UIView animateWithDuration:[self transitionDuration:transitionContext] * 3 / 5
                                                                   animations:^{
                                                                       toVC.view.frame = fromFrame;
                                                                   }
                                                                   completion:^(BOOL finished) {
                                                                       
                                                                       toVC.view.layer.borderWidth = 0;
                                                                       toVC.view.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1].CGColor;
                                                                       toVC.view.layer.cornerRadius = 0;

                                                                       [transitionContext completeTransition:YES];
                                                  }];
                             }];
        }];
    }
    else {
        
        CGRect halfwayFrame = self.initialRect;
        UIImageView *fromView = [[UIImageView alloc] initWithFrame:fromVC.view.bounds];
        
        fromView.contentMode = UIViewContentModeTop;
        fromView.clipsToBounds = YES;
        fromView.backgroundColor = [UIColor greenColor];
        fromView.image = [fromVC.view screenshotFast];
        fromView.layer.zPosition = 1024;
        fromView.layer.borderWidth = 1;
        fromView.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1].CGColor;
        fromView.layer.cornerRadius = 5;
        
        UIImageView *toView = [[UIImageView alloc] initWithFrame:self.initialRect];
        
        toView.image = self.initialImage;
        toView.layer.zPosition = 1024;
        toView.hidden = YES;
        
        [fromVC.view removeFromSuperview];
        
        [containerView addSubview:toVC.view];
        [containerView addSubview:bgView];
        [containerView addSubview:toView];
        [containerView addSubview:fromView];
        
        toVC.view.frame = containerView.bounds;
        toVC.view.hidden = NO;
        toVC.view.alpha = 1.0;

        CGRect toFrame = self.initialRect;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] * 3 / 5
                         animations:^{
                             fromView.frame = toFrame;
                         }
                         completion:^(BOOL finished) {
                             
                             //pre-flip the destination view halfway around and hide it
                             CATransform3D preTransform = CATransform3DMakeRotation(M_PI/2, 1, 0, 0);
                             preTransform.m34 = 1.0f/-500;
                             toView.layer.transform = preTransform;
                             toView.frame = halfwayFrame;
                             toView.hidden = YES;
                             
                             //perform the first half of the animation
                             CATransform3D srcTransform = CATransform3DMakeRotation(-M_PI/2, 1, 0, 0);
                             srcTransform.m34 = 1.0f/-500;
                             
                             [UIView animateWithDuration:[self transitionDuration:transitionContext] / 5
                                              animations:^{
                                                  
                                                  fromView.layer.transform = srcTransform;
                                                  fromView.frame = halfwayFrame;

                                              }
                                              completion:^(BOOL finished) {
                                                  
                                                  [fromView removeFromSuperview];
                                                  toView.hidden = NO;
                                                  
                                                  CATransform3D destTransform = CATransform3DMakeRotation(0, 1, 0, 0);
                                                  destTransform.m34 = 1.0f/-500;
                                                  
                                                  [UIView animateWithDuration:[self transitionDuration:transitionContext] / 5
                                                                   animations:^{
                                                                       
                                                                       toView.layer.transform = destTransform;
                                                                       toView.frame = self.initialRect;
                                                                       
                                                                   }
                                                                   completion:^(BOOL finished) {
                                                                      [transitionContext completeTransition:YES];
                                                                   }];
                                              }];
                         }];
    }
}

- (UIImage *)imageByCropping:(UIImage *)image {
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], self.initialRect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    
    return cropped;
}

- (CGRect)rectBetween:(CGRect)firstRect andRect:(CGRect)secondRect {
	CGRect betweenRect = CGRectZero;
	betweenRect.origin.x = (firstRect.origin.x + secondRect.origin.x) / 2;
	betweenRect.origin.y = (firstRect.origin.y + secondRect.origin.y) / 2;
	betweenRect.size.width = (firstRect.size.width + secondRect.size.width) / 2;
	betweenRect.size.height = (firstRect.size.height + secondRect.size.height) / 2;
	
	return betweenRect;
}

- (CATransform3D) rotate:(CGFloat) angle {
    return  CATransform3DMakeRotation(angle, 1.0, 0.0, 0.0);
}

@end
