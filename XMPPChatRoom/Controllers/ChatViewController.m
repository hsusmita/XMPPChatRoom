//
//  ChatViewController.m
//  XMPPChatRoom
//
//  Created by Susmita Horrow on 6/11/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import "ChatViewController.h"
#import <GrowingTextViewHandler.h>

@interface ChatViewController ()<UITextViewDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UITextView *chatTextView;
@property (strong, nonatomic) GrowingTextViewHandler *growingTextViewHandler;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewBottomConstraint;

@end

@implementation ChatViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self registerKeyboardNotification];
  self.chatTextView.textContainerInset = UIEdgeInsetsMake(10, 50, 10, 10);
  self.growingTextViewHandler = [[GrowingTextViewHandler alloc]initWithTextView:self.chatTextView
                                                           withHeightConstraint:self.textViewHeightConstraint];
  [self.growingTextViewHandler updateMinimumNumberOfLines:2 andMaximumNumberOfLine:5];
  self.growingTextViewHandler.animationDuration = 0.7;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.title = self.currentUser.displayName;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)textViewDidChange:(UITextView *)textView {
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

@end
