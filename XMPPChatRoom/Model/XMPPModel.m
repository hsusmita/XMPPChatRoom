//
//  XMPPModel.m
//  XMPPChatRoom
//
//  Created by Susmita Horrow on 6/11/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import "XMPPModel.h"

static XMPPModel *_sharedModel = nil;

@implementation XMPPModel

+ (id)sharedModel {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedModel = [[XMPPModel alloc]init];
	});
	return _sharedModel;
}

- (BOOL)isUserAuthenticated {
	return YES;
}

@end
