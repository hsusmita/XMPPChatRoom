//
//  TransitionAnimator.h
//  XMPPChatRoom
//
//  Created by hsusmita 17/06/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, TransitionDirection){
  TransitionDirectionRight,
  TransitionDirectionLeft
};

@interface TransitionAnimator : NSObject<UIViewControllerAnimatedTransitioning>

- (instancetype)initWithTransitionDirection:(TransitionDirection)direction;

@end
