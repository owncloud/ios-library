//
//  OCOAuth2Manager.h
//  ownCloud iOS library
//
//  Created by Noelia Alvarez on 28/08/2017.
//
// Copyright (C) 2017, ownCloud GmbH.  ( http://www.owncloud.org/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import "OCCredentialsDto.h"
#import "OCCommunication.h"
#import "OCOAuth2Configuration.h"
#import "UtilsFramework.h"

@interface OCOAuth2Manager : NSObject  <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>


/**
 * Method to get the new auth data by the oauth refresh token
 *
 * @param url -> NSURL with the url of the path
 * Ex: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music
 *
 * @param oauth2Configuration -> OCOAuth2Configuration with all the oauth parameters
 * @param refreshToken -> NSString with the refreshToken
 * @param userAgent -> NSString with the custom user agent or nil
 *
**/

+ (void) getAuthDataByOAuth2Configuration:(OCOAuth2Configuration *)oauth2Configuration
             refreshToken:(NSString *)refreshToken
                userAgent:(NSString *)userAgent
                  success:(void(^)(OCCredentialsDto *userCredDto))success
                  failure:(void(^)(NSError *error))failure;


@end
