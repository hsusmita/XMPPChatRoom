//
//  Configuration.m
//  XMPPChatRoom
//
//  Created by hsusmita on 18/06/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import "Configuration.h"

#if DEBUG
const int ddLogLevel = LOG_LEVEL_VERBOSE;
NSString* const kHostName = @"susmita.local";

#elif SNAPSHOT
const int ddLogLevel = LOG_LEVEL_VERBOSE;

#elif STAGING
const int ddLogLevel = LOG_LEVEL_ERROR;

#elif RELEASE
const int ddLogLevel = LOG_LEVEL_OFF;

#elif PRODUCTION
const int ddLogLevel = LOG_LEVEL_OFF;

#else

#endif