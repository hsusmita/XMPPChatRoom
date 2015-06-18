//
//  XMPPStreamHandler.m
//  XMPPChatRoom
//
//  Created by hsusmita on 18/06/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import "XMPPStreamHandler.h"

@interface XMPPStreamHandler()<XMPPStreamDelegate>

@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, assign) BOOL customCertEvaluation;
@property (nonatomic, strong) NSString *password;

@property (nonatomic,copy) RequestCompletionBlock connectionCompletionBlock;
@property (nonatomic,copy) RequestCompletionBlock authenticationCompletionBlock;


@end

@implementation XMPPStreamHandler

- (instancetype)initWithServerName:(NSString *)name andPort:(UInt16)hostPort {
  if (self = [super init]) {
    _xmppStream = [[XMPPStream alloc]init];
    _xmppStream.hostName = name;
    _xmppStream.hostPort = hostPort;
    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
      _xmppStream.enableBackgroundingOnSocket = YES;
    }
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
  }
  
  return self;
}

- (void)setupJID:(NSString *)JID andPassword:(NSString *)password {
  [self.xmppStream setMyJID:[XMPPJID jidWithString:JID]];
  self.password = password;
}

- (XMPPStream *)xmppStream {
  return _xmppStream;
}

- (void)connectWithCompletionBlock:(RequestCompletionBlock)block {
  self.connectionCompletionBlock = block;
  if (self.xmppStream.isConnected) {
    if (block) {
      block(nil,YES,nil);
    }
  }else {
    NSError *error = nil;
    [self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error];
    NSLog(@"error = %@",error);
    if (error && block) {
      block(nil,NO,error);
    }
  }
}

- (void)authenticateWithCompletionBlock:(RequestCompletionBlock)block {
  self.authenticationCompletionBlock = block;
  NSError *error;
  [self.xmppStream authenticateWithPassword:self.password error:&error];
  if (error && block) {
    block(nil,NO,nil);
  }
}

#pragma mark XMPPStream Delegate

- (void)xmppStreamWillConnect:(XMPPStream *)sender {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

}

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidStartNegotiation:(XMPPStream *)sender {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
  NSString *expectedCertName = [self.xmppStream.myJID domain];
  if (expectedCertName) {
    settings[(NSString *) kCFStreamSSLPeerName] = expectedCertName;
  }
  
  if (self.customCertEvaluation) {
    settings[GCDAsyncSocketManuallyEvaluateTrust] = @(YES);
  }
}

- (void)xmppStream:(XMPPStream *)sender didReceiveTrust:(SecTrustRef)trust
 completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
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
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);  
  if (self.connectionCompletionBlock) {
    self.connectionCompletionBlock(nil,YES,nil);
  }
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
  if (self.authenticationCompletionBlock) {
    self.authenticationCompletionBlock(nil,YES,nil);
  }
//  [self goOnline];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
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
  DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [presence fromStr]);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
  if (error) {
    DDLogError(@"Unable to connect to server. Check xmppStream.hostName.error = %@",error);
    if (self.connectionCompletionBlock) {
      self.connectionCompletionBlock(nil,NO,error);
    }
  }
}


@end
