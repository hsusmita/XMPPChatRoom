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
#import "ChatViewController.h"

@interface FriendsViewController ()<UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *friendsTableView;
@property (nonatomic,strong) NSFetchedResultsController *friendsListFetcher;
@end

@implementation FriendsViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self fetchData];
  [self setupTableView];
}

- (void)viewWillAppear:(BOOL)animated {
  self.title = [[XMPPModel sharedModel] currentUsername];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)fetchData {
  [[ChatManager sharedManager]connectAndAuthenticateWithCompletionBlock:^(NSArray *result, BOOL success, NSError *error) {
    if (success) {
      [[ChatManager sharedManager]goOnline];
    }
  }];
}

- (void)setupTableView {
  if (self.friendsListFetcher == nil) {
    self.friendsListFetcher = [[ChatManager sharedManager] friendsListFetcher];
    self.friendsListFetcher.delegate = self;
    NSError *error = nil;
    if (![self.friendsListFetcher performFetch:&error]) {
      DDLogError(@"Error performing fetch: %@", error);
    }
  }
}

- (IBAction)didTapLogout:(id)sender {
  [[ChatManager sharedManager]logoutWithCompletionBlock:^(NSArray *result, BOOL success, NSError *error) {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate showLoginFlow];
  }];
}

#pragma mark - UITableViewDataSource Methods 

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSArray *sections = [self.friendsListFetcher sections];
  if (section < [sections count]) {
    id <NSFetchedResultsSectionInfo> sectionInfo = sections[section];
    return sectionInfo.numberOfObjects;
    }
  
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"friendCell"];
  
  XMPPUserCoreDataStorageObject *user = [self.friendsListFetcher objectAtIndexPath:indexPath];
  cell.textLabel.text = user.displayName;
  return cell;
}

#pragma mark - NSFetchResultsControllerDeleagte

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
  [self.friendsTableView reloadData];
}

 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
   ChatViewController *chatVC = (ChatViewController *)segue.destinationViewController;
   NSInteger selectedRow = [self.friendsTableView indexPathForSelectedRow].row;
   chatVC.currentUser = [self.friendsListFetcher.fetchedObjects objectAtIndex:selectedRow];
 }

@end
