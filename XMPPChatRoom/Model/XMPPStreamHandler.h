//
//  XMPPStreamHandler.h
//  XMPPChatRoom
//
//  Created by hsusmita on 18/06/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

typedef  void(^RequestCompletionBlock)(NSArray *result,BOOL success, NSError *error) ;

@interface XMPPStreamHandler : NSObject

@property (nonatomic,strong,readonly) XMPPStream *xmppStream;

- (instancetype)initWithServerName:(NSString *)name andPort:(UInt16)hostPort;
- (void)setupJID:(NSString*)JID andPassword:(NSString*)password;
- (void)disconnectWithCompletionBlock:(RequestCompletionBlock)block;
- (void)connectWithCompletionBlock:(RequestCompletionBlock)block;
- (void)authenticateWithCompletionBlock:(RequestCompletionBlock)block;
- (void)registerWithCompletionBlock:(RequestCompletionBlock)block;
- (void)goOnline;
- (void)goOffline;
- (void)sendMessage:(NSString *)message
         toUsername:(NSString *)username
withCompletionBlock:(RequestCompletionBlock)completionBlock;
- (void)handleMessageReceivedEventWithBlock:(RequestCompletionBlock)completionBlock;
- (void)tearDown;

@end
