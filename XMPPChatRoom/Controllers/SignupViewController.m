//
//  SignupViewController.m
//  XMPPChatRoom
//
//  Created by Susmita Horrow on 6/11/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import "SignupViewController.h"
#import "ChatManager.h"

static CGFloat animationDuration = 0.5;

@interface SignupViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *repeatTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerViewVerticalCenterConstraint;

@end

@implementation SignupViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self registerKeyboardNotification];
  [self addGestures];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didTapOnCancel:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didTapSignup:(id)sender {
  if ([self isValidationSuccessful]) {
    [[ChatManager sharedManager]registerUsername:self.usernameTextField.text
                                     andPassword:self.passwordTextField.text
                             withCompletionBlock:^(NSArray *result, BOOL success, NSError *error) {
      NSLog(@"Done registration = %d",success);
                              if (success) {
                                [self showSuccessAlertWithMessage:@"Registration Done successfully"];
                              }else {
                                [self showErrorAlertWithMessage:@"Registration Failed.Try Again"];
                              }
    }];
  }
}

- (BOOL)isValidationSuccessful {
  BOOL isValid = NO;
  if (self.usernameTextField.text.length == 0) {
    [self showErrorAlertWithMessage:@"Username cannot be empty"];
  }else if (self.passwordTextField.text.length == 0) {
    [self showErrorAlertWithMessage:@"Password cannot be empty"];
  }else if (![self.passwordTextField.text isEqualToString:self.repeatTextField.text]) {
    [self showErrorAlertWithMessage:@"Passwords Do not Match"];
  }else {
    isValid = YES;
  }
  return isValid;
}

- (void)showErrorAlertWithMessage:(NSString *)errorMessage {
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:errorMessage
                                                                    preferredStyle:UIAlertControllerStyleAlert];
  __block SignupViewController *weakSelf = self;
  UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    [alertController dismissViewControllerAnimated:YES completion:^{
      [weakSelf hideKeyboard];
    }];
  }];
  [alertController addAction:dismissAction];
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showSuccessAlertWithMessage:(NSString *)message {
  __block SignupViewController *weakSelf = self;
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Success"
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel
                                                        handler:^(UIAlertAction *action) {
    [alertController dismissViewControllerAnimated:YES completion:^{
      [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }];
  }];
  [alertController addAction:dismissAction];
  [self presentViewController:alertController animated:YES completion:nil];

}

- (void)registerKeyboardNotification {
  [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillShowNotification
                                                    object:nil
                                                     queue:[NSOperationQueue mainQueue]
                                                usingBlock:^(NSNotification *note) {
                                                  NSDictionary* info = [note userInfo];
                                                  CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
                                                  //Shift the textfields up so that keyboard does not obscure them
                                                  CGFloat finalVerticalCenter = (CGRectGetHeight(self.view.frame) - kbSize.height - 64)/2;
                                                  self.containerViewVerticalCenterConstraint.constant = CGRectGetHeight(self.view.frame)/2 - finalVerticalCenter;
                                                  
                                                  [UIView animateWithDuration:animationDuration
                                                                   animations:^{
                                                                     [self.view layoutIfNeeded];
                                                                   }];
                                                }];
  
  [[NSNotificationCenter defaultCenter]addObserverForName:UIKeyboardWillHideNotification
                                                   object:nil
                                                    queue:[NSOperationQueue mainQueue]
                                               usingBlock:^(NSNotification *note) {
                                                 self.containerViewVerticalCenterConstraint.constant = 0;
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
  [self.repeatTextField resignFirstResponder];
}


@end
