//
//  ChatTableViewCell.h
//  XMPPChatRoom
//
//  Created by hsusmita on 24/06/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatMessage.h"

@interface ChatTableViewCell : UITableViewCell

- (void)configureChatCell:(ChatMessage *)chatMessage;

@end
