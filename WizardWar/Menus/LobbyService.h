//
//  LocalUserService.h
//  WizardWar
//
//  Created by Sean Hess on 6/21/13.
//  Copyright (c) 2013 The LAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa.h>
#import "User.h"
#import <CoreLocation/CoreLocation.h>

// Maintains the connection to the lobby
// Let's you know whenever users join/quit
// Also lets you know local users

@interface LobbyService : NSObject

@property (nonatomic, strong) RACSubject * updated;
@property (nonatomic) BOOL joined;

+ (LobbyService *)shared;

// You can't call connect on this. Call joinLobby when you have the user and the location
- (void)joinLobby:(User*)user location:(CLLocation*)location;
- (void)leaveLobby:(User*)user;

- (NSFetchRequest*)requestCloseUsers;

//-(BOOL)userIsLocal:(User*)user;

// AppID 3hsi88WR19iXGN11miDSH8B031uqyoBYBXHQe9bo
// ClientKey CjkxlkZw0YOMdzdjJzhHfQm4vkPrA2ZWhY9n2Nfo
// Rest API A9kgNN3UKkYDHyUebFe16StpKWVHQZrjCBJyI5Sk
// Master ruR8hExEHPI3Gk9P8lsgNcbYOOP2j7TbkaCwACt4

@end
