//
//  ChatViewController.m
//  XMPPChatRoom
//
//  Created by Susmita Horrow on 6/11/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import "ChatViewController.h"
#import <GrowingTextViewHandler.h>
#import "ChatManager.h"
#import "ChatMessage.h"
#import "ChatTableViewCell.h"

@interface ChatViewController ()<UITextViewDelegate,UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UITextView *chatTextView;
@property (weak, nonatomic) IBOutlet UITableView *chatTableView;
@property (strong, nonatomic) GrowingTextViewHandler *growingTextViewHandler;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewBottomConstraint;
@property (strong, nonatomic) NSMutableArray *chatMessages;
@property (strong, nonatomic) XMPPUserCoreDataStorageObject *currentUser;

@end

@implementation ChatViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self registerKeyboardNotification];
  self.growingTextViewHandler = [[GrowingTextViewHandler alloc]initWithTextView:self.chatTextView
                                                           withHeightConstraint:self.textViewHeightConstraint];
  [self.growingTextViewHandler updateMinimumNumberOfLines:2 andMaximumNumberOfLine:5];
  [self configureChatMessages];
  self.chatTableView.estimatedRowHeight = 44.0;
  self.chatTextView.contentInset = UIEdgeInsetsZero;
  self.chatTableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.title = self.selectedFriend.displayName;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)textViewDidChange:(UITextView *)textView {
  self.chatTextView.contentInset = UIEdgeInsetsZero;
  [self.growingTextViewHandler resizeTextViewWithAnimation:YES];
}

- (void)registerKeyboardNotification {
  [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillShowNotification
                                                    object:nil
                                                     queue:[NSOperationQueue mainQueue]
                                                usingBlock:^(NSNotification *note) {
                                                  NSDictionary* info = [note userInfo];
                                                  CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
                                                  //Shift the textfields up so that keyboard does not obscure them
                                                  self.textViewBottomConstraint.constant = kbSize.height+10;
                                                  [UIView animateWithDuration:0.2
                                                                   animations:^{
                                                                     [self.view layoutIfNeeded];
                                                                   }];
                                                }];
  
  [[NSNotificationCenter defaultCenter]addObserverForName:UIKeyboardWillHideNotification
                                                   object:nil
                                                    queue:[NSOperationQueue mainQueue]
                                               usingBlock:^(NSNotification *note) {
                                                 self.textViewBottomConstraint.constant = 0;
                                                 [UIView animateWithDuration:0.2
                                                                  animations:^{
                                                                    [self.view layoutIfNeeded];
                                                                  }];
                                               }];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)didTapSendButton:(id)sender {
  if (self.chatTextView.text.length == 0)return;
  ChatMessage *message = [ChatMessage new];
  message.receiver = self.selectedFriend;
  message.sender = self.currentUser;
  message.messageBody = self.chatTextView.text;
  [[ChatManager sharedManager]sendMessage:message withCompletionBlock:^(NSArray *result, BOOL success, NSError *error) {
    //Completion block not yet implemented
  }];
  [self.chatMessages addObject:message];
  [self.chatTableView reloadData];
  self.chatTextView.text = @"";
//  [self textViewDidChange:self.chatTextView];
}

- (void)configureChatMessages {
  self.chatMessages = [NSMutableArray array];
  [[ChatManager sharedManager]handleMessageReceivedWithCompletionBlock:^(ChatMessage *message, NSError *error) {
    if (!error) {
      [self.chatMessages addObject:message];
      [self.chatTableView reloadData];
    }
  }];
}


#pragma mark - UITableViewDataSource Methods 

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.chatMessages.count;
}

- (ChatTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  ChatTableViewCell *cell = (ChatTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"chatCell"];
  [cell configureChatCell:[self.chatMessages objectAtIndex:indexPath.row]];
  return cell;
}

@end
