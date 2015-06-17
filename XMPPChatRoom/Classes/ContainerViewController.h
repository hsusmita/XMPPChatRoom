//
//  ContainerViewController.h
//  XMPPChatRoom
//
//  Created by hsusmita on 16/06/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContainerViewController : UIViewController

@property (nonatomic, assign) BOOL isTransitionDone;

- (instancetype)initWithViewControllers:(NSArray *)viewControllers;
- (void)moveToViewControllerWithIndex:(NSInteger)index;

@end
