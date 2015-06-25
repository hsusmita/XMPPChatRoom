//
//  ChatTableViewCell.m
//  XMPPChatRoom
//
//  Created by hsusmita on 24/06/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import "ChatTableViewCell.h"
#import "XMPPModel.h"

@interface ChatTableViewCell()
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

@end

@implementation ChatTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureChatCell:(ChatMessage *)chatMessage {
  if (chatMessage.sender == nil) {
    self.userNameLabel.text = [[XMPPModel sharedModel] currentUsername];
  }else {
    self.userNameLabel.text = chatMessage.sender.displayName;
  }
  self.messageLabel.text = chatMessage.messageBody;
}
@end
