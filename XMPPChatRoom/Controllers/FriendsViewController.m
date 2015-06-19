//
//  FriendsViewController.m
//  XMPPChatRoom
//
//  Created by Susmita Horrow on 6/11/15.
//  Copyright (c) 2015 Susmita Horrow. All rights reserved.
//

#import "FriendsViewController.h"
#import "AppDelegate.h"
#import "ChatManager.h"
#import "XMPPModel.h"

@interface FriendsViewController ()

@end

@implementation FriendsViewController

- (void)viewDidLoad {
  [super viewDidLoad];
//  [self.navigationController setTitle:[[XMPPModel sharedModel] currentUsername]];
  self.title = [[XMPPModel sharedModel] currentUsername];
  [[ChatManager sharedManager] connectAndBeOnlineWithCompletionBlock:^(NSArray *result, BOOL success, NSError *error) {
    if (success)
      NSLog(@"User is now online");
    [[ChatManager sharedManager]fetchUsers];
  }];
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
- (IBAction)didTapLogout:(id)sender {
//  [[ChatManager sharedManager]disconnectWithCompletionBlock:^(NSArray *result, BOOL success, NSError *error) {
//    NSLog(@"Disconnect status = %d",success);
//  }];
  [[ChatManager sharedManager]logoutWithCompletionBlock:^(NSArray *result, BOOL success, NSError *error) {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate showLoginFlow];
  }];

}

@end
