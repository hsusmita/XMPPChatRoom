//
//  LoginViewController.m
//  XMPPChatRoom
//
//  Created by Susmita Horrow on 6/11/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"
#import "SignupViewController.h"
#import "ChatManager.h"
#import "XMPPModel.h"

static CGFloat animationDuration = 0.5;

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerVerticalCenterConstraint;

@end

@implementation LoginViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self registerKeyboardNotification];
  [self addGestures];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didTapSignUp:(id)sender {
  SignupViewController *singupVC = [self.storyboard instantiateViewControllerWithIdentifier:@"SignupVC"];
  [self presentViewController:singupVC animated:YES completion:nil];
}

- (IBAction)didTapLogin:(id)sender {
  [[ChatManager sharedManager] authenticateUsername:self.usernameTextField.text
                                        andPassword:self.passwordTextField.text
                                withCompletionBlock:^(NSArray *result, BOOL success, NSError *error) {
    NSLog(@"Is Authenticated = %d",success);
  }];
  AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
  [appDelegate showChatFlow];
}

#pragma mark - Keyboard Notification handler

- (void)registerKeyboardNotification {
  [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardDidShowNotification
                                                    object:nil
                                                     queue:[NSOperationQueue mainQueue]
                                                usingBlock:^(NSNotification *note) {
                                                  NSDictionary* info = [note userInfo];
                                                  CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
                                                  //Shift the textfields up so that keyboard does not obscure them
                                                  CGFloat displacement = (CGRectGetHeight(self.view.frame) - kbSize.height)/2;
                                                  self.containerVerticalCenterConstraint.constant = displacement;
                                                  
                                                  [UIView animateWithDuration:animationDuration
                                                                   animations:^{
                                                    [self.view layoutIfNeeded];
                                                  }];
  }];
  
  [[NSNotificationCenter defaultCenter]addObserverForName:UIKeyboardDidHideNotification
                                                   object:nil
                                                    queue:[NSOperationQueue mainQueue]
                                               usingBlock:^(NSNotification *note) {
                                                 self.containerVerticalCenterConstraint.constant = 0;
                                                 [UIView animateWithDuration:animationDuration
                                                                  animations:^{
                                                   [self.view layoutIfNeeded];
                                                 }];
  }];
}

- (void)addGestures {
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideKeyboard)];
  [self.view addGestureRecognizer:tap];
}

- (void)hideKeyboard {
  [self.usernameTextField resignFirstResponder];
  [self.passwordTextField resignFirstResponder];
}
@end
