//
//  OCOAuth2Manager.m
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

#import "OCOAuth2Manager.h"

@implementation OCOAuth2Manager

+ (void) getAuthDataByOAuth2Configuration:(OCOAuth2Configuration *)oauth2Configuration
                          withBaseURL:(NSString *)baseURL
                             refreshToken:(NSString *)refreshToken
                                userAgent:(NSString *)userAgent
                                  success:(void(^)(OCCredentialsDto *userCredDto))success
                                  failure:(void(^)(NSError *error))failure {
    
    [UtilsFramework deleteAllCookies];
    
    [self refreshTokenAuthRequestByOAuth2Configuration:oauth2Configuration withBaseURL:baseURL refreshToken:refreshToken userAgent:userAgent
     
    success:^(NSHTTPURLResponse *response, NSError *error, NSData *data) {
        
        NSDictionary *dictJSON;
        OCCredentialsDto *userCredDto = [OCCredentialsDto new];
        
        if (data != nil) {
            
            NSError *errorJSON = nil;
            NSLog(@"data = %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            dictJSON = [NSJSONSerialization JSONObjectWithData:data
                                                       options:kNilOptions
                                                         error:&errorJSON];
            if (errorJSON == nil) {
                if (dictJSON[@"error"] != nil && ![dictJSON[@"error"] isEqual:[NSNull null]] ) {
                    
                    NSString *message = (NSString*)[dictJSON objectForKey:@"error"];
                    
                    if ([message isKindOfClass:[NSNull class]]) {
                        message = @"";
                    }
                    
                    NSError *error = [UtilsFramework getErrorWithCode:response.statusCode andCustomMessageFromTheServer:message];
                    
                    failure(error);
                } else {
                    userCredDto.userName = dictJSON[@"user_id"];
                    userCredDto.accessToken = dictJSON[@"access_token"];
                    userCredDto.refreshToken = dictJSON[@"refresh_token"];
                    userCredDto.expiresIn = dictJSON[@"expires_in"];
                    userCredDto.tokenType = dictJSON[@"token_type"];
                    userCredDto.authenticationMethod = AuthenticationMethodBEARER_TOKEN;
                    
                    success(userCredDto);
                }
            }
            
        } else {
            failure(error);
        }
        
    } failure:^(NSHTTPURLResponse *response, NSError *error) {
        failure(error);
    }];
    
}

+ (void) refreshTokenAuthRequestByOAuth2Configuration:(OCOAuth2Configuration *)oauth2Configuration
                                      withBaseURL:(NSString *)baseURL
                                         refreshToken:(NSString *)refreshToken
                                            userAgent:(NSString *)userAgent
                                              success:(void(^)(NSHTTPURLResponse *response, NSError *error, NSData *data))success
                                              failure:(void(^)(NSHTTPURLResponse *response, NSError *error))failure {

    
    NSURL *urlToGetToken = [[NSURL URLWithString:baseURL] URLByAppendingPathComponent:oauth2Configuration.tokenEndpoint];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlToGetToken];
    
    [request setHTTPMethod:@"POST"];
    if (userAgent != nil) {
        [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }
    
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSString *authId = [NSString stringWithFormat:@"%@:%@",oauth2Configuration.clientId,oauth2Configuration.clientSecret];
    NSString *base64EncodedAuthId = [UtilsFramework AFBase64EncodedStringFromString:authId];
    NSString *authorizationValue = [NSString stringWithFormat:@"Basic %@",base64EncodedAuthId];
    [request setValue:authorizationValue forHTTPHeaderField:@"Authorization"];
    
    NSString *body = [NSString stringWithFormat:@"grant_type=refresh_token&client_id=%@&refresh_token=%@",oauth2Configuration.clientId,refreshToken];
    
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSession *session = nil;
    
    session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (data != nil) {
            success((NSHTTPURLResponse*)response, error, data);
        } else {
            NSLog(@"Error %@",error.localizedDescription);
            failure((NSHTTPURLResponse*)response, error);
        }
    }];
    
    [task resume];
}

@end
