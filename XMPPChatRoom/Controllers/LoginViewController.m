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

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)didTapSignUp:(id)sender {
  SignupViewController *singupVC = [self.storyboard instantiateViewControllerWithIdentifier:@"SignupVC"];
  [self presentViewController:singupVC animated:YES completion:nil];
}

- (IBAction)didTapLogin:(id)sender {
  AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
  [appDelegate showChatFlow];
}

@end
