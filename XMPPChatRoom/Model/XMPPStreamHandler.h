//
//  XMPPStreamHandler.h
//  XMPPChatRoom
//
//  Created by hsusmita on 18/06/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

typedef  void(^RequestCompletionBlock)(NSArray *result,BOOL success, NSError *error) ;

@interface XMPPStreamHandler : NSObject

- (instancetype)initWithServerName:(NSString *)name andPort:(UInt16)hostPort;
- (void)setupJID:(NSString*)JID andPassword:(NSString*)password;
- (XMPPStream *)xmppStream;

- (void)disconnectWithCompletionBlock:(RequestCompletionBlock)block;
- (void)connectWithCompletionBlock:(RequestCompletionBlock)block;
- (void)authenticateWithCompletionBlock:(RequestCompletionBlock)block;
- (void)registerWithCompletionBlock:(RequestCompletionBlock)block;
- (void)goOnlineWithCompletionBlock:(RequestCompletionBlock)block;

@end
