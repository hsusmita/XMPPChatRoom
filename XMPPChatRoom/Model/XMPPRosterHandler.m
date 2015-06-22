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

- (void)setupRoster {
  _xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
  _xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:_xmppRosterStorage];

  self.xmppRoster.autoFetchRoster = YES;
  self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
  [self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (void)fetchUsers {
  [self.xmppRoster fetchRoster];
}

- (void)teardown {
  [self.xmppRoster removeDelegate:self];
  [self.xmppRoster deactivate];
}

#pragma mark XMPPRosterDelegate

- (void)xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
  
}

- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence {
  DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, [presence type]);
}

/**
 * Sent when a Roster Push is received as specified in Section 2.1.6 of RFC 6121.
 **/
- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterPush:(XMPPIQ *)iq {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

/**
 * Sent when the initial roster is received.
 **/
- (void)xmppRosterDidBeginPopulating:(XMPPRoster *)sender {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

/**
 * Sent when the initial roster has been populated into storage.
 **/
- (void)xmppRosterDidEndPopulating:(XMPPRoster *)sender {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

/**
 * Sent when the roster receives a roster item.
 **/
- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterItem:(NSXMLElement *)item {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (NSManagedObjectContext *)rosterManagedObjectContext {
  return [self.xmppRosterStorage mainThreadManagedObjectContext];
}

@end
