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

static ChatManager *chatManager = nil;

@interface ChatManager()<XMPPStreamDelegate>

@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPRoster *xmppRoster;
@property (nonatomic, strong) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic, strong) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong) XMPPvCardCoreDataStorage *xmppvCardStorage;
@property (nonatomic, strong) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, assign) BOOL isXmppConnected;

@property (nonatomic,strong) XMPPStreamHandler *streamHandler;

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
  if ([[XMPPModel sharedModel] isUserAuthenticated]) {
    [self.streamHandler setupJID:[[XMPPModel sharedModel] currentJID]
                     andPassword:[[XMPPModel sharedModel] currentPassword]];
  }
  [self setupRoster];
  [self setupCapabilities];
  [self setupVCardSetup];
  
  [self.xmppReconnect         activate:self.streamHandler.xmppStream];
  [self.xmppRoster            activate:self.streamHandler.xmppStream];
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

// The XMPPRoster handles the xmpp protocol stuff related to the roster.
// The storage for the roster is abstracted.
// So you can use any storage mechanism you want.
// You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
// or setup your own using raw SQLite, or create your own storage mechanism.
// You can do it however you like! It's your application.
// But you do need to provide the roster with some storage facility.

- (void)setupRoster {
  self.xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
  self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:self.xmppRosterStorage];
  self.xmppRoster.autoFetchRoster = YES;
  self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
  [self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
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

//- (void)connectWithCompletionBlock:(RequestCompletionBlock)block {
//  self.streamHandler.connectionCompletionBlock = block;
//  NSError *error = nil;
//  [self.streamHandler.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error];
//  if (isAlreadyConnencted && self.connectionCompletionBlock) {
//    self.connectionCompletionBlock(nil,YES,nil);
//  }else if ([[XMPPModel sharedModel]isUserAuthenticated]) {
//    NSError *error = nil;
//    [self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error];
//  }else {
//    if (self.connectionCompletionBlock) {
//      self.connectionCompletionBlock(nil,NO,nil);
//    } 
//  }
//
//
//}

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


- (void)goOnline {
  XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
  
  NSString *domain = [self.xmppStream.myJID domain];
  
  //Google set their presence priority to 24, so we do the same to be compatible.
  
  if([domain isEqualToString:@"gmail.com"]
     || [domain isEqualToString:@"gtalk.com"]
     || [domain isEqualToString:@"talk.google.com"])
    {
    NSXMLElement *priority = [NSXMLElement elementWithName:@"priority" stringValue:@"24"];
    [presence addChild:priority];
    }
  
  [[self xmppStream] sendElement:presence];
}

- (void)goOffline {
  XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
  
  [[self xmppStream] sendElement:presence];
}

- (void)connectWithCompletionBlock:(RequestCompletionBlock)block {
  self.connectionCompletionBlock = block;
  BOOL isAlreadyConnencted = ![self.xmppStream isDisconnected];
  NSError *error = nil;
 [self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error];
//  if (isAlreadyConnencted && self.connectionCompletionBlock) {
//    self.connectionCompletionBlock(nil,YES,nil);
//  }else if ([[XMPPModel sharedModel]isUserAuthenticated]) {
//    NSError *error = nil;
//    [self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error];
//  }else {
//    if (self.connectionCompletionBlock) {
//      self.connectionCompletionBlock(nil,NO,nil);
//    }
//  }
//  
//  
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
/*
#pragma mark XMPPRosterDelegate 

- (void)xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
  
  XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[presence from]
                                                           xmppStream:xmppStream
                                                 managedObjectContext:[self managedObjectContext_roster]];
  
  NSString *displayName = [user displayName];
  NSString *jidStrBare = [presence fromStr];
  NSString *body = nil;
  
  if (![displayName isEqualToString:jidStrBare])
    {
    body = [NSString stringWithFormat:@"Buddy request from %@ <%@>", displayName, jidStrBare];
    }
  else
    {
    body = [NSString stringWithFormat:@"Buddy request from %@", displayName];
    }
  
  
  if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:displayName
                                                        message:body
                                                       delegate:nil
                                              cancelButtonTitle:@"Not implemented"
                                              otherButtonTitles:nil];
    [alertView show];
    }
  else
    {
    // We are not active, so use a local notification instead
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.alertAction = @"Not implemented";
    localNotification.alertBody = body;
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
    }
  
}*/
@end
