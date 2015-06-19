//
//  XMPPRosterHandler.h
//  XMPPChatRoom
//
//  Created by hsusmita on 19/06/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMPPRosterHandler : NSObject

@property (nonatomic, strong,readonly) XMPPRoster *xmppRoster;

- (instancetype)initWithXMPPStream:(XMPPStream *)xmppStream;
- (void)fetchUsers;

@end
