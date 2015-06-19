//
//  XMPPRosterHandler.m
//  XMPPChatRoom
//
//  Created by hsusmita on 19/06/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import "XMPPRosterHandler.h"

@interface XMPPRosterHandler()<XMPPRosterDelegate>

@property (nonatomic, strong) XMPPRosterCoreDataStorage *xmppRosterStorage;

@end

@implementation XMPPRosterHandler

- (instancetype)initWithXMPPStream:(XMPPStream *)xmppStream {
  if (self = [super init]) {
    [self setupRoster];
    [self.xmppRoster activate:xmppStream];
  }
  return self;
}

// The XMPPRoster handles the xmpp protocol stuff related to the roster.
// The storage for the roster is abstracted.
// So you can use any storage mechanism you want.
// You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
// or setup your own using raw SQLite, or create your own storage mechanism.
// You can do it however you like! It's your application.
// But you do need to provide the roster with some storage facility.

- (void)setupRoster {
  _xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
  _xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:_xmppRosterStorage];

  self.xmppRoster.autoFetchRoster = YES;
  self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
  [self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (void)fetchUsers {

}

#pragma mark XMPPRosterDelegate

- (void)xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
  
/*  XMPPUserCoreDataStorageObject *user = [self.xmppRosterStorage userForJID:[presence from]
                                                           xmppStream:self.xmppRoster.xmppStream
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
    }*/
  
}

- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence {
  
}

/**
 * Sent when a Roster Push is received as specified in Section 2.1.6 of RFC 6121.
 **/
- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterPush:(XMPPIQ *)iq {
  
}

/**
 * Sent when the initial roster is received.
 **/
- (void)xmppRosterDidBeginPopulating:(XMPPRoster *)sender {
  
}

/**
 * Sent when the initial roster has been populated into storage.
 **/
- (void)xmppRosterDidEndPopulating:(XMPPRoster *)sender {
  
}

/**
 * Sent when the roster receives a roster item.
 *
 * Example:
 *
 * <item jid='romeo@example.net' name='Romeo' subscription='both'>
 *   <group>Friends</group>
 * </item>
 **/
- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterItem:(NSXMLElement *)item {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
  
}


@end
