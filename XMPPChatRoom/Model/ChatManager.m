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

- (void)teardownStream {
  [self.xmppReconnect         deactivate];
  [self.xmppvCardTempModule   deactivate];
  [self.xmppvCardAvatarModule deactivate];
  [self.xmppCapabilities      deactivate];
  [self.rosterHandler teardown];
  [self.streamHandler tearDown];
}


- (void)authenticateUsername:(NSString*)name
                 andPassword:(NSString*)password
         withCompletionBlock:(RequestCompletionBlock)block {
  [[XMPPModel sharedModel] storeUsername:name andPassword:password];
  if (self.streamHandler.xmppStream.isConnected) {
    [self.streamHandler authenticateWithCompletionBlock:block];
  }else {
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

- (void)connectAndAuthenticateWithCompletionBlock:(RequestCompletionBlock)block {
  if ([[XMPPModel sharedModel] isUserInfoPresent]) {
    [self.streamHandler setupJID:[[XMPPModel sharedModel] currentJID]
                     andPassword:[[XMPPModel sharedModel] currentPassword]];
  }
  [self.streamHandler connectWithCompletionBlock:^(NSArray *result, BOOL success, NSError *error) {
    if (success) {
      [self.streamHandler authenticateWithCompletionBlock:block];
    }else {
      if (block) block(nil,NO,error);
    }
  }];
}

- (void)goOnline {
  [self.streamHandler goOnline];
}

- (void)goOffline {
  [self.streamHandler goOffline];
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
  [self goOffline];
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

- (NSFetchedResultsController *)friendsListFetcher {
  
  NSSortDescriptor *sectionDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sectionNum" ascending:YES];
  NSSortDescriptor *nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
  
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"XMPPUserCoreDataStorageObject"];
  [fetchRequest setSortDescriptors:@[sectionDescriptor,nameDescriptor]];
  [fetchRequest setFetchBatchSize:10];
  
  return [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                             managedObjectContext:[self.rosterHandler rosterManagedObjectContext]
                                               sectionNameKeyPath:@"sectionNum"
                                                        cacheName:nil];
}

@end
