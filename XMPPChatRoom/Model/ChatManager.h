//
//  DataManager.h
//  XMPPChatRoom
//
//  Created by hsusmita on 17/06/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"

@interface ChatManager : NSObject

+ (instancetype)sharedManager;

- (void)setupStream;
- (void)teardownStream;

- (void)goOnline;
- (void)goOffline;

@end
