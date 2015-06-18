//
//  XMPPModel.h
//  XMPPChatRoom
//
//  Created by Susmita Horrow on 6/11/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

@interface XMPPModel : NSObject

+ (id)sharedModel;
- (BOOL)isUserAuthenticated;
- (NSString *)currentJID;
- (NSString *)currentPassword;
- (void)clearUserInfo;
- (void)storeJID:(NSString *)JID andPassword:(NSString *)password;

@end
