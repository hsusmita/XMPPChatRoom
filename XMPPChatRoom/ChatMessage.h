//
//  ChatMessage.h
//  XMPPChatRoom
//
//  Created by hsusmita on 24/06/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChatMessage : NSObject

@property (nonatomic,strong) NSString *messageBody;
@property (nonatomic,strong) XMPPUserCoreDataStorageObject *sender;
@property (nonatomic,strong) XMPPUserCoreDataStorageObject *receiver;

@end
