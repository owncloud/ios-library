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
#import "OCFrameworkConstants.h"
#import "OCCredentialsDto.h"
#import "OCTrustedCertificatesStore.h"


@interface OCOAuth2Manager : NSObject  <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>


@property (nonatomic, strong) id<OCTrustedCertificatesStore> trustedCertificatesStore;


- (NSURL *) getOAuth2URLToGetAuthCodeByOAuth2Configuration:(OCOAuth2Configuration *)oauth2Configuration
                                            withServerPath:(NSString *)serverPath;


/**
 * Method to get the auth data by the auth code
 *
 * @param baseURL -> NSString with the url of the path obteined from method getOAuth2URLToGetTokenByOAuth2Configuration:withServerPath:
 * @param oauth2Configuration -> OCOAuth2Configuration with all the oauth parameters
 * @param authCode -> NSString with the auth code
 * @param userAgent -> NSString with the custom user agent or nil
 *
 **/

- (void) authDataByOAuth2Configuration:(OCOAuth2Configuration *)oauth2Configuration
                           withBaseURL:(NSString *)baseURL
                              authCode:(NSString *)authCode
                             userAgent:(NSString *)userAgent
                        withCompletion:(void(^)(OCCredentialsDto *userCredDto, NSError *error))completion;

/**
 * Method to get the new auth data by the oauth refresh token
 *
 * @param baseURL -> NSString with the url of the path
 * Ex: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music
 *
 * @param refreshToken -> NSString with the refreshToken
 * @param oauth2Configuration -> OCOAuth2Configuration with all the oauth parameters
 * @param userAgent -> NSString with the custom user agent or nil
 *
**/

- (void) refreshAuthDataByOAuth2Configuration:(OCOAuth2Configuration *)oauth2Configuration
                          withBaseURL:(NSString *)baseURL
                             refreshToken:(NSString *)refreshToken
                                userAgent:(NSString *)userAgent
                                  success:(void(^)(OCCredentialsDto *userCredDto))success
                                  failure:(void(^)(NSError *error))failure;



@end
