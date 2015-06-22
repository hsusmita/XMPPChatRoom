//
//  XMPPModel.h
//  XMPPChatRoom
//
//  Created by Susmita Horrow on 6/11/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

@interface XMPPModel : NSObject

+ (id)sharedModel;
- (BOOL)isUserInfoPresent;
- (NSString *)currentJID;
- (NSString *)currentPassword;
- (NSString *)currentUsername;
- (void)clearUserInfo;
- (void)storeUsername:(NSString*)username andPassword:(NSString *)password;
@end
