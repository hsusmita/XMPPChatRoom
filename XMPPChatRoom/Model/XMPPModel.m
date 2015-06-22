//
//  XMPPModel.m
//  XMPPChatRoom
//
//  Created by Susmita Horrow on 6/11/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import "XMPPModel.h"

static XMPPModel *_sharedModel = nil;
static NSString *kXMPPmyJID = @"My JID";
static NSString *kXMPPmyUsername = @"My Username";
static NSString *kXMPPmyPassword = @"My Password";

@implementation XMPPModel

+ (id)sharedModel {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedModel = [[XMPPModel alloc]init];
	});
	return _sharedModel;
}

- (BOOL)isUserInfoPresent {
  return ([self currentJID] && [self currentPassword]);
}

- (NSString *)currentJID {
  return [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
}

- (NSString *)currentPassword {
  return [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyPassword];
}

- (NSString *)currentUsername {
  return [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyUsername];
}

- (void)storeUsername:(NSString*)username andPassword:(NSString *)password {
  NSString *JID = [NSString stringWithFormat:@"%@@%@",username,kHostName];
  [[NSUserDefaults standardUserDefaults]setObject:JID forKey:kXMPPmyJID];
  [[NSUserDefaults standardUserDefaults]setObject:username forKey:kXMPPmyUsername];
  [[NSUserDefaults standardUserDefaults]setObject:password forKey:kXMPPmyPassword];
  [[NSUserDefaults standardUserDefaults]synchronize];
}

- (void)clearUserInfo {
  [[NSUserDefaults standardUserDefaults]removeObjectForKey:kXMPPmyJID];
  [[NSUserDefaults standardUserDefaults]removeObjectForKey:kXMPPmyPassword];
  [[NSUserDefaults standardUserDefaults]removeObjectForKey:kXMPPmyUsername];
  [[NSUserDefaults standardUserDefaults]synchronize];
}

@end
