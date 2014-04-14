//
//  ConfigTests.h
//  ownCloud iOS library
//
//  Created by javi on 4/3/14.
//  Copyright (c) 2014 ownCloud. All rights reserved.
//

//Your entire server url. ex:https://example.owncloud.com/owncloud/
#define baseUrl @""
//Server with webdav url
#define webdavBaseUrl @""
//Your user
#define user @"" //@"username"
//Your password
#define password [[[NSProcessInfo processInfo] environment] objectForKey:@"password"] //@"password"

//Optional. You can change the folder of tests.
#define pathTestFolder @""