//
//  ControllerTransitionContext.m
//  XMPPChatRoom
//
//  Created by hsusmita on 17/06/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import "ControllerTransitionContext.h"

@interface ControllerTransitionContext()

@property (nonatomic, strong) NSDictionary *privateViewControllers;
@property (nonatomic, assign) CGRect privateDisappearingFromRect;
@property (nonatomic, assign) CGRect privateAppearingFromRect;
@property (nonatomic, assign) CGRect privateDisappearingToRect;
@property (nonatomic, assign) CGRect privateAppearingToRect;
@property (nonatomic, weak) UIView *containerView;
@property (nonatomic, assign) UIModalPresentationStyle presentationStyle;

@end

@implementation ControllerTransitionContext

- (instancetype)initWithFromViewController:(UIViewController *)fromViewController
                          toViewController:(UIViewController *)toViewController
                                shouldMoveRight:(BOOL)moveRight {
  NSAssert ([fromViewController isViewLoaded] && fromViewController.view.superview, @"The fromViewController view must reside in the container view upon initializing the transition context.");
  
  if ((self = [super init])) {
    self.presentationStyle = UIModalPresentationCustom;
    self.containerView = fromViewController.view.superview;
    self.shouldMoveRight = moveRight;
    self.privateViewControllers = @{
                                    UITransitionContextFromViewControllerKey:fromViewController,
                                    UITransitionContextToViewControllerKey:toViewController,
                                    };
    
    CGFloat travelDistance = (self.shouldMoveRight ? -self.containerView.bounds.size.width : self.containerView.bounds.size.width);
    self.privateDisappearingFromRect = self.privateAppearingToRect = self.containerView.bounds;
    self.privateDisappearingToRect = CGRectOffset (self.containerView.bounds, travelDistance, 0);
    self.privateAppearingFromRect = CGRectOffset (self.containerView.bounds, -travelDistance, 0);
  }
  
  return self;
}

- (CGRect)initialFrameForViewController:(UIViewController *)viewController {
  if (viewController == [self viewControllerForKey:UITransitionContextFromViewControllerKey]) {
    return self.privateDisappearingFromRect;
  } else {
    return self.privateAppearingFromRect;
  }
}

- (CGRect)finalFrameForViewController:(UIViewController *)viewController {
  if (viewController == [self viewControllerForKey:UITransitionContextFromViewControllerKey]) {
    return self.privateDisappearingToRect;
  } else {
    return self.privateAppearingToRect;
  }
}

- (UIViewController *)viewControllerForKey:(NSString *)key {
  return self.privateViewControllers[key];
}

- (void)completeTransition:(BOOL)didComplete {
  if (self.completionBlock) {
    self.completionBlock (didComplete);
  }
}

- (BOOL)transitionWasCancelled { return NO; } // Our non-interactive transition can't be cancelled (it could be interrupted, though)

// Supress warnings by implementing empty interaction methods for the remainder of the protocol:

- (void)updateInteractiveTransition:(CGFloat)percentComplete {}
- (void)finishInteractiveTransition {}
- (void)cancelInteractiveTransition {}

- (UIView *)viewForKey:(NSString *)key {
  return [self viewControllerForKey:key].view;
}

- (CGAffineTransform)targetTransform NS_AVAILABLE_IOS(8_0) {
  return CGAffineTransformIdentity;
}

@end
