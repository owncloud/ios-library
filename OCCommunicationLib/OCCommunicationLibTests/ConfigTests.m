//
//  ConfigTests.m
//  ownCloud iOS library
//
//  Created by Javier Gonzalez on 14/04/14.
//  Copyright (c) 2014 ownCloud. All rights reserved.
//

#import "ConfigTests.h"

@implementation ConfigTests

///-----------------------------------
/// @name initWithVariables
///-----------------------------------

/**
 * Method init this object with the tests variables filled
 *
 * @return -> self object
 */
- (id) initWithVariables {
    
    self = [super init];
    
    if (!self) {
		return nil;
    }
    
    //If you want execute the test on your own server fill this variables:
    NSString *baseUrlOwn = @""; //Your entire server url. ex:https://example.owncloud.com/owncloud/
    NSString *webdavBaseUrlOwn = @""; //Server with webdav url. ex: https://example.owncloud.com/owncloud/remote.php/webdav/
    NSString *userOwn = @""; //Server user
    NSString *passwordOwn = @""; //Server password
    //Folder for the unit test on the server. This folder has the current date since a reference for avoid problems with duplicates building
    NSString *pathTestFolderOwn = [NSString stringWithFormat:@"UnitTest%f",[[NSDate new] timeIntervalSince1970]];
    NSString *userToShareOwn = @""; //name user to share with
    NSString *groupToShareOwn = @""; //name group to share with
    
    
    //We set the baseUrl
    if ([[[NSProcessInfo processInfo] environment] objectForKey:@"baseUrlTravis"]) {
        _baseUrl = [[[NSProcessInfo processInfo] environment] objectForKey:@"baseUrlTravis"];
    } else {
        _baseUrl = baseUrlOwn;
    }
    
    //We set the webdavBaseUrl
    if ([[[NSProcessInfo processInfo] environment] objectForKey:@"webdavBaseUrlTravis"]) {
        _webdavBaseUrl = [[[NSProcessInfo processInfo] environment] objectForKey:@"webdavBaseUrlTravis"];
    } else {
        _webdavBaseUrl = webdavBaseUrlOwn;
    }
    
    //We set the user
    if ([[[NSProcessInfo processInfo] environment] objectForKey:@"userTravis"]) {
        _user = [[[NSProcessInfo processInfo] environment] objectForKey:@"userTravis"];
    } else {
        _user = userOwn;
    }
    
    //We set the password
    if ([[[NSProcessInfo processInfo] environment] objectForKey:@"passwordTravis"]) {
        _password = [[[NSProcessInfo processInfo] environment] objectForKey:@"passwordTravis"];
    } else {
        _password = passwordOwn;
    }
    
    //We set the pathTestFolder
    _pathTestFolder = pathTestFolderOwn;
    
    //We set the user to share
    if ([[[NSProcessInfo processInfo] environment] objectForKey:@"userToShareTravis"]) {
        _userToShare = [[[NSProcessInfo processInfo] environment] objectForKey:@"userToShareTravis"];
    } else {
        _userToShare = userToShareOwn;
    }
    
    //We set the group to share
    if ([[[NSProcessInfo processInfo] environment] objectForKey:@"groupToShareTravis"]) {
        _groupToShare = [[[NSProcessInfo processInfo] environment] objectForKey:@"groupToShareTravis"];
    } else {
        _groupToShare = groupToShareOwn;
    }
    
    return self;
}

@end
