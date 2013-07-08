//
//  MatchmakingViewController.m
//  WizardWar
//
//  Created by Sean Hess on 5/17/13.
//  Copyright (c) 2013 The LAB. All rights reserved.
//

// This is such a crappy way of doing all of this
// I need another approach.
// CoreData? -- would be a good idea

// How to do distance?
// Hmm..... Well, I have the location and userId of each one
// I just have to evaluate distance and keep track of ones that are close!

#import "MatchmakingViewController.h"
#import "WizardDirector.h"
#import "MatchLayer.h"
#import "Challenge.h"
#import "NSArray+Functional.h"
#import "FirebaseCollection.h"
#import "FirebaseConnection.h"
#import "MatchViewController.h"
#import "User.h"
#import "LobbyService.h"
#import "UserService.h"
#import "ChallengeService.h"
#import "AccountViewController.h"
#import "LocationService.h"
#import "UserFriendService.h"
#import <ReactiveCocoa.h>
#import "ComicZineDoubleLabel.h"
#import "ObjectStore.h"

@interface MatchmakingViewController () <AccountFormDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, weak) IBOutlet UITableView * tableView;
@property (weak, nonatomic) IBOutlet UIView *accountView;

@property (nonatomic, readonly) NSArray * challenges;
@property (nonatomic, readonly) NSArray * users;

@property (nonatomic, strong) FirebaseConnection* connection;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UILabel *userLoginLabel;

@property (nonatomic, readonly) User * currentUser;
@property (strong, nonatomic) MatchLayer * match;

@property (strong, nonatomic) NSFetchedResultsController * friendResults;
@property (strong, nonatomic) NSFetchedResultsController * localResults;

@end

@implementation MatchmakingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Matchmaking";
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationItem.titleView = [ComicZineDoubleLabel titleView:self.title navigationBar:self.navigationController.navigationBar];
    
    // CHECK AUTHENTICATED
    if ([UserService shared].isAuthenticated) {
        [self connect];
    }
    else {
        AccountViewController * accounts = [AccountViewController new];
        accounts.delegate = self;
        [self.navigationController presentViewController:accounts animated:YES completion:nil];
    }
}

- (void)connect {
    NSError *error = nil;
    
    self.friendResults = [ObjectStore.shared fetchedResultsForRequest:[UserService.shared requestFriends]];
    self.friendResults.delegate = self;
    [self.friendResults performFetch:&error];
    
    self.localResults = [ObjectStore.shared fetchedResultsForRequest:[LobbyService.shared requestCloseUsers]];
    self.localResults.delegate = self;
    [self.localResults performFetch:&error];

    // I think friends should be showing up faster, no?
    [self.tableView reloadData];
    
    [LocationService.shared connect];
//    [ChallengeService.shared connect];

    __weak MatchmakingViewController * wself = self;

    // LOBBY
    self.accountView.hidden = YES;

//    [UserService.shared.updated subscribeNext:^(id x) {
//        [wself.tableView reloadData];
//    }];
    
    [RACAble(LocationService.shared, location) subscribeNext:^(id x) {
        [wself didUpdateLocation];
    }];
    [self didUpdateLocation];
//
//    // CHALLENGES
//    [ChallengeService.shared.updated subscribeNext:^(Challenge *challenge) {
//        [wself.tableView reloadData];
//        [wself checkAutoconnectChallenge:challenge];
//    }];
}


- (void)viewDidAppear:(BOOL)animated {}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)disconnect {
//    [self leaveLobby];
//}
//
//- (void)reconnect {
//    [self joinLobby];
//}

#pragma mark NSFetchedResultsControllerDelegate methods

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    NSLog(@"controllerDidChangeContent");
    [self.tableView reloadData];
}



#pragma mark - Location
-(void)didUpdateLocation {
    if (LocationService.shared.hasLocation) {
        CLLocation * location = LocationService.shared.location;
        self.currentUser.locationLongitude = location.coordinate.longitude;
        self.currentUser.locationLatitude = location.coordinate.latitude;
    }
    
    if (LocationService.shared.hasLocation || LocationService.shared.denied) {
        [self joinLobby];
    }
}


#pragma mark - AccountFormDelegate
-(void)didCancelAccountForm {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
    
}
-(void)didSubmitAccountForm:(NSString *)name {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self connect];
}

#pragma mark - Login

- (IBAction)didTapLogin:(id)sender {
    
}

- (NSArray*)challenges {
//    return ChallengeService.shared.myChallenges.allValues;
    return @[];
}

- (User*)currentUser {
    return UserService.shared.currentUser;
}

#pragma mark - Challenges
-(void)checkAutoconnectChallenge:(Challenge*)challenge {
    if ([challenge.matchId isEqualToString:self.autoconnectToMatchId]) {
        [self joinMatch:challenge];
    }
}


#pragma mark - Firebase stuff

- (void)joinLobby
{
    [LobbyService.shared joinLobby:self.currentUser location:LocationService.shared.location];
}

- (void)leaveLobby {
    [LobbyService.shared leaveLobby:self.currentUser];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return [self.challenges count];
    } else if (section == 1){
        return [[self.localResults.sections objectAtIndex:0] numberOfObjects];
    } else if (section == 2) {
        return [[self.friendResults.sections objectAtIndex:0] numberOfObjects];
    } else {
        return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"Challenges";
    else if (section == 1) return @"Local Users (Online)";
    else if (section == 2) return @"Friends";
    return nil;
}

//- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
//    return 0;
//}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section == 0) {
        return [self tableView:tableView challengeCellForRowAtIndexPath:indexPath];
    } else {
        NSIndexPath * localIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];        
        User * user = nil;

        if (indexPath.section == 1) {
            user = [self.localResults objectAtIndexPath:localIndexPath];
        } else if (indexPath.section == 2) {
            user = [self.friendResults objectAtIndexPath:localIndexPath];
        } else {
            return nil;
        }
        return [self tableView:tableView userCellForUser:user];
    }
}

-(UITableViewCell*)tableView:(UITableView *)tableView userCellForUser:(User*)user {
    static NSString *CellIdentifier = @"UserCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    UIColor * backgroundColor = [UIColor colorWithWhite:0.784 alpha:1.000];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.contentView.backgroundColor = backgroundColor;
        cell.textLabel.textColor = [UIColor colorWithWhite:0.149 alpha:1.000];
    }
    
    cell.textLabel.text = user.name;
    
    if (user.isOnline)
        cell.textLabel.textColor = [UIColor greenColor];
    else
        cell.textLabel.textColor = [UIColor darkTextColor];
    
    cell.imageView.image = [UIImage imageNamed:@"user.jpg"];
    UILabel * accessory = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 43)];

    if (user.isFriend)
        accessory.text = @"FRIEND";
    else
        accessory.text = @"LOCAL";
    
    accessory.font = [UIFont boldSystemFontOfSize:14];
    accessory.backgroundColor = backgroundColor;
    accessory.textAlignment = NSTextAlignmentRight;
    cell.accessoryView = accessory;
    
    NSString * games = [NSString stringWithFormat:@"%i Games", user.friendPoints];

    NSString * distance = @"";
    
    if (user.isOnline) {
        CLLocationDistance dl = [LocationService.shared distanceFrom:user.location];
        distance = [NSString stringWithFormat:@"%@, ", [LocationService.shared distanceString:dl]];
    }
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%@", distance, games];
    return cell;
}

-(UITableViewCell*)tableView:(UITableView *)tableView challengeCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"InviteCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.contentView.backgroundColor = [UIColor colorWithRed:0.490 green:0.706 blue:0.275 alpha:1.000];
        cell.textLabel.textColor = [UIColor colorWithWhite:0.149 alpha:1.000];        
    }
    
    Challenge * challenge = self.challenges[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ vs %@", [self nameOrYou:challenge.main.name], [self nameOrYou:challenge.opponent.name]];
    
    return cell;
}

- (NSString*)nameOrYou:(NSString*)name {
    if ([name isEqualToString:self.currentUser.name]) return @"You";
    else return name;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath * localIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
    if (indexPath.section == 0)
        [self didSelectChallenge:self.challenges[indexPath.row]];
    else if (indexPath.section == 1)
        [self didSelectUser:[self.localResults objectAtIndexPath:localIndexPath]];
    else if (indexPath.section == 2)
        [self didSelectUser:[self.friendResults objectAtIndexPath:localIndexPath]];
    else {}
        
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didSelectUser:(User*)user {
    
    // Issue the challenge
    Challenge * challenge = [ChallengeService.shared user:self.currentUser challengeOpponent:user isRemote:!user.isOnline];
    [self joinMatch:challenge];
    [UserFriendService.shared user:UserService.shared.currentUser addChallenge:challenge];
}

- (void)didSelectChallenge:(Challenge*)challenge {
    [self joinMatch:challenge];
}

- (void)joinMatch:(Challenge*)challenge {
    NSLog(@"JOIN THE READY SCREEN %@", challenge.matchId);    
    MatchViewController * match = [MatchViewController new];
    [match startChallenge:challenge currentWizard:UserService.shared.currentWizard];
    [self.navigationController presentViewController:match animated:YES completion:nil];
}

- (void)dealloc {
    // don't worry about disconnecting. If you aren't THERE, it's ok
}

@end
