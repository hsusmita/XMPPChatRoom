//
//  TransitionAnimator.m
//  XMPPChatRoom
//
//  Created by hsusmita on 17/06/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import "TransitionAnimator.h"

@interface TransitionAnimator()

@property (nonatomic,assign) TransitionDirection direction;

@end

@implementation TransitionAnimator

- (instancetype)initWithTransitionDirection:(TransitionDirection)direction {
  if (self = [super init]) {
    _direction = direction;
  }
  return self;
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
  return 1;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
  UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
  UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
//  [self scaleFrom:fromViewController.view toView:toViewController.view forTransitionContext:transitionContext];
  [self rotateFrom:fromViewController.view toView:toViewController.view forTransitionContext:transitionContext];
//  [self slideFrom:fromViewController.view toView:toViewController.view forTransitionContext:transitionContext];
}

- (void)rotateFrom:(UIView *)fromView toView:(UIView *)toView forTransitionContext:(id<UIViewControllerContextTransitioning>)transitionContext {
  [[transitionContext containerView] addSubview:toView];
  toView.alpha = 1;
  [UIView transitionFromView:fromView
                      toView:toView
                    duration:[self transitionDuration:transitionContext]
                     options: self.direction == TransitionDirectionRight ? UIViewAnimationOptionTransitionFlipFromLeft : UIViewAnimationOptionTransitionFlipFromRight
                  completion:^(BOOL finished) {
                    [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                  }];

}

- (void)slideFrom:(UIView *)fromView toView:(UIView *)toView forTransitionContext:(id<UIViewControllerContextTransitioning>)transitionContext {
    CGFloat travelDistance = [transitionContext containerView].bounds.size.width + 16;
    CGAffineTransform travel = CGAffineTransformMakeTranslation (self.direction == TransitionDirectionLeft ? travelDistance : -travelDistance, 0);
  
    [[transitionContext containerView] addSubview:toView];
    toView.alpha = 0;
    toView.transform = CGAffineTransformInvert (travel);
  
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.5 options:0x00 animations:^{
      fromView.transform = travel;
      fromView.alpha = 0;
      toView.transform = CGAffineTransformIdentity;
      toView.alpha = 1;
    } completion:^(BOOL finished) {
      fromView.transform = CGAffineTransformIdentity;
      [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

- (void)scaleFrom:(UIView *)fromView toView:(UIView *)toView forTransitionContext:(id<UIViewControllerContextTransitioning>)transitionContext {
  [[transitionContext containerView] addSubview:toView];
  toView.alpha = 0;
  
  //Initial state
  if (self.direction == TransitionDirectionRight) {
    fromView.transform = CGAffineTransformIdentity;
  }else {
    toView.transform =  CGAffineTransformMakeScale(0.1, 0.1);
  }
  [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
    if (self.direction == TransitionDirectionRight) {
      fromView.transform = CGAffineTransformMakeScale(0.1, 0.1);
    }else {
      toView.transform =  CGAffineTransformIdentity;
    }

    toView.alpha = 1;
  } completion:^(BOOL finished) {
    fromView.transform = CGAffineTransformIdentity;
    [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    
  }];
}

@end
