//
//  XMPPModel.h
//  XMPPChatRoom
//
//  Created by Susmita Horrow on 6/11/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMPPModel : NSObject

+ (id)sharedModel;
- (BOOL)isUserAuthenticated;

@end
