//
//  DataManager.m
//  XMPPChatRoom
//
//  Created by hsusmita on 17/06/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import "ChatManager.h"
#import "XMPPModel.h"
#import "XMPPStreamHandler.h"
#import "XMPPRosterHandler.h"

static ChatManager *chatManager = nil;

@interface ChatManager()

@property (nonatomic, strong) XMPPReconnect *xmppReconnect;

@property (nonatomic, strong) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong) XMPPvCardCoreDataStorage *xmppvCardStorage;

@property (nonatomic, strong) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, assign) BOOL isXmppConnected;

@property (nonatomic,strong) XMPPStreamHandler *streamHandler;
@property (nonatomic,strong) XMPPRosterHandler *rosterHandler;

@end

@implementation ChatManager

+ (instancetype)sharedManager {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    chatManager = [[ChatManager alloc]init];
    [chatManager initialSetup];
  });
  return chatManager;
}

- (void)initialSetup {
  self.streamHandler = [[XMPPStreamHandler alloc]initWithServerName:kHostName andPort:5222];
  self.rosterHandler = [[XMPPRosterHandler alloc]initWithXMPPStream:self.streamHandler.xmppStream];
 
  [self setupCapabilities];
  [self setupVCardSetup];
  [self.xmppReconnect         activate:self.streamHandler.xmppStream];
  [self.xmppvCardTempModule   activate:self.streamHandler.xmppStream];
  [self.xmppvCardAvatarModule activate:self.streamHandler.xmppStream];
  [self.xmppCapabilities      activate:self.streamHandler.xmppStream];
}

- (void)authenticateUsername:(NSString*)name
                 andPassword:(NSString*)password
         withCompletionBlock:(RequestCompletionBlock)block {
  if (self.streamHandler.xmppStream.isConnected) {
    [self.streamHandler authenticateWithCompletionBlock:block];
  }else {
    [[XMPPModel sharedModel] storeUsername:name andPassword:password];
    [self.streamHandler setupJID:[[XMPPModel sharedModel] currentJID] andPassword:password];
    [self.streamHandler connectWithCompletionBlock:^(NSArray *result, BOOL success, NSError *error) {
      if (success) {
        [self.streamHandler authenticateWithCompletionBlock:block];
      }else {
        if (block) {
          block(nil,NO,error);
        }
      }
    }];
  }
}

- (void)connectAndBeOnlineWithCompletionBlock:(RequestCompletionBlock)block {
  if ([[XMPPModel sharedModel] isUserAuthenticated]) {
    [self.streamHandler setupJID:[[XMPPModel sharedModel] currentJID]
                     andPassword:[[XMPPModel sharedModel] currentPassword]];
  }
  [self.streamHandler connectWithCompletionBlock:^(NSArray *result, BOOL success, NSError *error) {
    if (success) {
      [self.streamHandler goOnlineWithCompletionBlock:block];
    }else {
      if (block)block(nil,NO,nil);
    }
  }];
}

- (void)registerUsername:(NSString *)name
             andPassword:(NSString *)password
     withCompletionBlock:(RequestCompletionBlock)block {
  NSString *JID = [NSString stringWithFormat:@"%@@%@",name,kHostName];
  [self.streamHandler setupJID:JID andPassword:password];
  [self.streamHandler connectWithCompletionBlock:^(NSArray *result, BOOL success, NSError *error) {
    if (success) {
      [self.streamHandler registerWithCompletionBlock:block];
    }else if (block){
      block(nil,NO,error);
    }
  }];
}

- (void)fetchUsers {
  [self.rosterHandler fetchUsers];
}

- (void)logoutWithCompletionBlock:(RequestCompletionBlock)completionBlock {
  [self.streamHandler disconnectWithCompletionBlock:^(NSArray *result, BOOL success, NSError *error) {
    if (success) {
      NSLog(@"Logout successful");
      [[XMPPModel sharedModel]clearUserInfo];
      if (completionBlock) {
        completionBlock(nil,YES,nil);
      }
    }else {
      if (completionBlock) {
        completionBlock(nil,NO,error);
      }
    }
  }];
}

// Setup capabilities
//
// The XMPPCapabilities module handles all the complex hashing of the caps protocol (XEP-0115).
// Basically, when other clients broadcast their presence on the network
// they include information about what capabilities their client supports (audio, video, file transfer, etc).
// But as you can imagine, this list starts to get pretty big.
// This is where the hashing stuff comes into play.
// Most people running the same version of the same client are going to have the same list of capabilities.
// So the protocol defines a standardized way to hash the list of capabilities.
// Clients then broadcast the tiny hash instead of the big list.
// The XMPPCapabilities protocol automatically handles figuring out what these hashes mean,
// and also persistently storing the hashes so lookups aren't needed in the future.
//
// Similarly to the roster, the storage of the module is abstracted.
// You are strongly encouraged to persist caps information across sessions.
//
// The XMPPCapabilitiesCoreDataStorage is an ideal solution.
// It can also be shared amongst multiple streams to further reduce hash lookups.

- (void)setupCapabilities {
  self.xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
  self.xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:self.xmppCapabilitiesStorage];

  self.xmppCapabilities.autoFetchHashedCapabilities = YES;
  self.xmppCapabilities.autoFetchNonHashedCapabilities = NO;
}

// Setup vCard support
//
// The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
// The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
- (void)setupVCardSetup {

  self.xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
  self.xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:self.xmppvCardStorage];

  self.xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:self.xmppvCardTempModule];
}

/*- (void)teardownStream {
  [self.xmppStream removeDelegate:self];
  [self.xmppRoster removeDelegate:self];
  
  [self.xmppReconnect         deactivate];
  [self.xmppRoster            deactivate];
  [self.xmppvCardTempModule   deactivate];
  [self.xmppvCardAvatarModule deactivate];
  [self.xmppCapabilities      deactivate];
  
  [self.xmppStream disconnect];
}

- (void)goOffline {
  XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
  
  [[self xmppStream] sendElement:presence];
}


- (void)disconnect {
  [self goOffline];
  [self.xmppStream disconnect];
}

- (void)disconnectWithCompletionBlock:(RequestCompletionBlock)block {
  self.disconnectCompletionBlock = block;
  [self goOffline];
  [self.xmppStream disconnect];
}
*/

@end
