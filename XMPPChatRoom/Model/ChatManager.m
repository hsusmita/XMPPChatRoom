//
//  DataManager.m
//  XMPPChatRoom
//
//  Created by hsusmita on 17/06/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import "ChatManager.h"
#import "XMPPModel.h"
#import "DDFileLogger.h"
#import "DDTTYLogger.h"

#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

static ChatManager *chatManager = nil;

@interface ChatManager()

@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPRoster *xmppRoster;
@property (nonatomic, strong) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic, strong) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong) XMPPvCardCoreDataStorage *xmppvCardStorage;
@property (nonatomic, strong) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, assign) BOOL customCertEvaluation;
@property (nonatomic, assign) BOOL isXmppConnected;

@end

@implementation ChatManager

+ (instancetype)sharedManager {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    chatManager = [[ChatManager alloc]init];
  });
  return chatManager;
}

- (void)setupStream {
  NSAssert(self.xmppStream == nil, @"Method setupStream invoked multiple times");
  self.xmppStream = [[XMPPStream alloc] init];
  if ([[UIDevice currentDevice] isMultitaskingSupported]) {
    self.xmppStream.enableBackgroundingOnSocket = YES;
  }
  
  // Setup reconnect
  //
  // The XMPPReconnect module monitors for "accidental disconnections" and
  // automatically reconnects the stream for you.
  
  self.xmppReconnect = [[XMPPReconnect alloc] init];
  [self setupRoster];
  [self setupCapabilities];
  [self setupVCardSetup];
  
  [self.xmppReconnect         activate:self.xmppStream];
  [self.xmppRoster            activate:self.xmppStream];
  [self.xmppvCardTempModule   activate:self.xmppStream];
  [self.xmppvCardAvatarModule activate:self.xmppStream];
  [self.xmppCapabilities      activate:self.xmppStream];
  
  // Add ourself as a delegate to anything we may be interested in
  
  [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
  [self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
  
  // Optional:
  //
  // Replace me with the proper domain and port.
  // The example below is setup for a typical google talk account.
  //
  // If you don't supply a hostName, then it will be automatically resolved using the JID (below).
  // For example, if you supply a JID like 'user@quack.com/rsrc'
  // then the xmpp framework will follow the xmpp specification, and do a SRV lookup for quack.com.
  //
  // If you don't specify a hostPort, then the default (5222) will be used.
  
  //	[xmppStream setHostName:@"talk.google.com"];
  //	[xmppStream setHostPort:5222];
  
  
  // You may need to alter these settings depending on the server you're connecting to
  self.customCertEvaluation = YES;
}

// The XMPPRoster handles the xmpp protocol stuff related to the roster.
// The storage for the roster is abstracted.
// So you can use any storage mechanism you want.
// You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
// or setup your own using raw SQLite, or create your own storage mechanism.
// You can do it however you like! It's your application.
// But you do need to provide the roster with some storage facility.

- (void)setupRoster {
  self.xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
  //	xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
  
  self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:self.xmppRosterStorage];
  
  self.xmppRoster.autoFetchRoster = YES;
  self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
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

- (void)teardownStream {
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


- (void)connectWithCompletionBlock:()block{

}
- (BOOL)connect {
  if (![self.xmppStream isDisconnected]) {
    return YES;
  }
  if (![[XMPPModel sharedModel]isUserAuthenticated]) {
    return NO;
  }
  
  [self.xmppStream setMyJID:[XMPPJID jidWithString:[[XMPPModel sharedModel]currentJID]]];
//  password = myPassword;
  
  NSError *error = nil;
  if (![self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error]) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error connecting"
                                                        message:@"See console for error details."
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
    [alertView show];
    
    NSLog(@"Error connecting: %@", error);
    
    return NO;
    }
  
  return YES;
}

- (void)disconnect {
  [self goOffline];
  [self.xmppStream disconnect];
}

#pragma mark XMPPStream Delegate

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket {
//  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
  NSLog(@"Did Connect Socket");
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings {
//  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
  NSLog(@"willSecureWithSettings");
  NSString *expectedCertName = [self.xmppStream.myJID domain];
  if (expectedCertName) {
    settings[(NSString *) kCFStreamSSLPeerName] = expectedCertName;
    }
  
  if (self.customCertEvaluation)
    {
    settings[GCDAsyncSocketManuallyEvaluateTrust] = @(YES);
    }
}

/**
 * Allows a delegate to hook into the TLS handshake and manually validate the peer it's connecting to.
 *
 * This is only called if the stream is secured with settings that include:
 * - GCDAsyncSocketManuallyEvaluateTrust == YES
 * That is, if a delegate implements xmppStream:willSecureWithSettings:, and plugs in that key/value pair.
 *
 * Thus this delegate method is forwarding the TLS evaluation callback from the underlying GCDAsyncSocket.
 *
 * Typically the delegate will use SecTrustEvaluate (and related functions) to properly validate the peer.
 *
 * Note from Apple's documentation:
 *   Because [SecTrustEvaluate] might look on the network for certificates in the certificate chain,
 *   [it] might block while attempting network access. You should never call it from your main thread;
 *   call it only from within a function running on a dispatch queue or on a separate thread.
 *
 * This is why this method uses a completionHandler block rather than a normal return value.
 * The idea is that you should be performing SecTrustEvaluate on a background thread.
 * The completionHandler block is thread-safe, and may be invoked from a background queue/thread.
 * It is safe to invoke the completionHandler block even if the socket has been closed.
 *
 * Keep in mind that you can do all kinds of cool stuff here.
 * For example:
 *
 * If your development server is using a self-signed certificate,
 * then you could embed info about the self-signed cert within your app, and use this callback to ensure that
 * you're actually connecting to the expected dev server.
 *
 * Also, you could present certificates that don't pass SecTrustEvaluate to the client.
 * That is, if SecTrustEvaluate comes back with problems, you could invoke the completionHandler with NO,
 * and then ask the client if the cert can be trusted. This is similar to how most browsers act.
 *
 * Generally, only one delegate should implement this method.
 * However, if multiple delegates implement this method, then the first to invoke the completionHandler "wins".
 * And subsequent invocations of the completionHandler are ignored.
 **/
- (void)xmppStream:(XMPPStream *)sender didReceiveTrust:(SecTrustRef)trust
 completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler {
//  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
  NSLog(@"Did receive trust");
  // The delegate method should likely have code similar to this,
  // but will presumably perform some extra security code stuff.
  // For example, allowing a specific self-signed certificate that is known to the app.
  
  dispatch_queue_t bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_async(bgQueue, ^{
    
    SecTrustResultType result = kSecTrustResultDeny;
    OSStatus status = SecTrustEvaluate(trust, &result);
    
    if (status == noErr && (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified)) {
      completionHandler(YES);
    }
    else {
      completionHandler(NO);
    }
  });
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
  NSLog(@"Did Stream secure");
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender {
//  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
  NSLog(@"Stream did Connect");
  
  self.isXmppConnected = YES;
  
  NSError *error = nil;
  
  if (![[self xmppStream] authenticateWithPassword:[[XMPPModel sharedModel]currentPassword] error:&error]) {
//    DDLogError(@"Error authenticating: %@", error);
    NSLog(@"Error authenticating: %@", error);
    }
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
//  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
  NSLog(@"xmppStreamDidAuthenticate");
  [self goOnline];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error {
  NSLog(@"didNotAuthenticate");
//  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
//  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
  NSLog(@"didReceiveIQ");
  return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
/*//  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
  NSLog(@"Did receive message");
  // A simple example of inbound message handling.
  
  if ([message isChatMessageWithBody]) {
    XMPPUserCoreDataStorageObject *user = [self.xmppRosterStorage userForJID:[message from]
                                                             xmppStream:self.xmppStream
                                                   managedObjectContext:[self managedObjectContext_roster]];
    
    NSString *body = [[message elementForName:@"body"] stringValue];
    NSString *displayName = [user displayName];
    
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
      {
      UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:displayName
                                                          message:body
                                                         delegate:nil
                                                cancelButtonTitle:@"Ok"
                                                otherButtonTitles:nil];
      [alertView show];
      }
    else
      {
      // We are not active, so use a local notification instead
      UILocalNotification *localNotification = [[UILocalNotification alloc] init];
      localNotification.alertAction = @"Ok";
      localNotification.alertBody = [NSString stringWithFormat:@"From: %@\n\n%@",displayName,body];
      
      [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
      }
    }*/
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
//  DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [presence fromStr]);
  NSLog(@"didReceivePresence");
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
//  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
  NSLog(@"didReceiveError");
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
//  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
  
  if (!self.isXmppConnected)
    {
//    DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
    }
}
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
