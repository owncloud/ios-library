//
//  ConfigTests.h
//  ownCloud iOS library
//
//  Created by Javier Gonzalez on 14/04/14.
//  Copyright (c) 2014 ownCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConfigTests : NSObject

///-----------------------------------
/// @name initWithVariables
///-----------------------------------

/**
 * Method init this object with the tests variables filled
 *
 * @return -> self object
 */
- (id) initWithVariables;


//Your entire server url. ex:https://example.owncloud.com/owncloud/
@property (nonatomic, strong) NSString *baseUrl;
//Server with webdav url. ex: https://example.owncloud.com/owncloud/remote.php/webdav/
@property (nonatomic, strong) NSString *webdavBaseUrl;
//Server user
@property (nonatomic, strong) NSString *user;
//Server password
@property (nonatomic, strong) NSString *password;
//Optional. You can change the folder of tests.
@property (nonatomic, strong) NSString *pathTestFolder;
//User to share
@property (nonatomic, strong) NSString *userToShare;
//Group to share
@property (nonatomic, strong) NSString *groupToShare;

@end
