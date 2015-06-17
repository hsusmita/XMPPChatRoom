//
//  ContainerViewController.m
//  XMPPChatRoom
//
//  Created by hsusmita on 16/06/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import "ContainerViewController.h"
#import "TransitionAnimator.h"
#import "ControllerTransitionContext.h"

@interface ContainerViewController ()

@property (nonatomic,strong) NSArray *viewControllers;

@end

@implementation ContainerViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self transitionToChildViewController:[self.viewControllers objectAtIndex:0]];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)moveToViewControllerWithIndex:(NSInteger)index {
  [self transitionToChildViewController:[self.viewControllers objectAtIndex:index]];
}

- (instancetype)initWithViewControllers:(NSArray *)viewControllers {
  NSParameterAssert ([viewControllers count] > 0);
  if ((self = [super init])) {
    self.viewControllers = [viewControllers copy];
  }
  return self;
}

- (void)transitionToChildViewController:(UIViewController *)toViewController {
  
  UIViewController *fromViewController = ([self.childViewControllers count] > 0 ? self.childViewControllers[0] : nil);
  if (toViewController == fromViewController || ![self isViewLoaded]) {
    return;
  }
  
  UIView *toView = toViewController.view;
  [toView setTranslatesAutoresizingMaskIntoConstraints:YES];
  
  [fromViewController willMoveToParentViewController:nil];
  [self addChildViewController:toViewController];
  
  // If this is the initial presentation, add the new child with no animation.
  if (!fromViewController) {
    [self.view addSubview:toViewController.view];
    toView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    toView.frame = self.view.bounds;
    return;
  }
  
  // Because of the nature of our view controller, with horizontally arranged buttons, we instantiate our private transition context with information about whether this is a left-to-right or right-to-left transition. The animator can use this information if it wants.
  NSUInteger fromIndex = [self.viewControllers indexOfObject:fromViewController];
  NSUInteger toIndex = [self.viewControllers indexOfObject:toViewController];
  
  // Animate the transition by calling the animator with our private transition context.
  TransitionAnimator *animator = [[TransitionAnimator alloc] initWithTransitionDirection:(toIndex > fromIndex) ? TransitionDirectionRight :TransitionDirectionLeft];
  

  ControllerTransitionContext *transitionContext =
        [[ControllerTransitionContext alloc] initWithFromViewController:fromViewController
                                                       toViewController:toViewController
                                                             shouldMoveRight:toIndex > fromIndex];
  
  transitionContext.animated = YES;
  transitionContext.interactive = NO;
  transitionContext.completionBlock = ^(BOOL didComplete) {
    [fromViewController.view removeFromSuperview];
    [fromViewController removeFromParentViewController];
    [toViewController didMoveToParentViewController:self];
    
    if ([animator respondsToSelector:@selector (animationEnded:)]) {
      [animator animationEnded:didComplete];
    }
    self.isTransitionDone = YES;
  };
  self.isTransitionDone = NO;
  [animator animateTransition:transitionContext];
}


@end
