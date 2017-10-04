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



- (NSURL *) getOAuth2URLToGetAuthCodeByOAuth2Configuration:(OCOAuth2Configuration *)oauth2Configuration
                                            withServerPath:(NSString *)serverPath {
    
    NSString *baseURL = [NSString stringWithFormat:@"%@%@",serverPath,oauth2Configuration.authorizationEndpoint];
    
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:baseURL];
    NSDictionary *queryDictionary = @{
                                      @"response_type"  : @"code",
                                      @"redirect_uri" : oauth2Configuration.redirectUri,
                                      @"client_id" : oauth2Configuration.clientId
                                      };
    NSMutableArray *queryItems = [NSMutableArray array];
    for (NSString *key in queryDictionary) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:queryDictionary[key]]];
    }
    urlComponents.queryItems = queryItems;
    NSURL *fullOauthURL = urlComponents.URL;
    
    return fullOauthURL;
}

+ (NSURL *) getOAuth2URLToGetTokenByOAuth2Configuration:(OCOAuth2Configuration *)oauth2Configuration
                                         withServerPath:(NSString *)serverPath {
    
    NSURL *serverPathURL = [[NSURL URLWithString:serverPath] URLByAppendingPathComponent:oauth2Configuration.tokenEndpoint];
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:serverPathURL.absoluteString];
    
    NSURL *fullOAuthURL = urlComponents.URL;
    
    return fullOAuthURL;
}


#pragma mark - access token

- (void) authDataByOAuth2Configuration:(OCOAuth2Configuration *)oauth2Configuration
                           withBaseURL:(NSString *)baseURL
                              authCode:(NSString *)authCode
                             userAgent:(NSString *)userAgent
                        withCompletion:(void(^)(OCCredentialsDto *userCredDto, NSError *error))completion {
    
    NSURL *urlToGetAuthData = [OCOAuth2Manager getOAuth2URLToGetTokenByOAuth2Configuration:oauth2Configuration withServerPath:baseURL];

    [self authDataRequestByOAuth2Configuration:oauth2Configuration withURL:urlToGetAuthData authCode:authCode userAgent:userAgent withCompletion:^(NSData *data, NSHTTPURLResponse *httpResponse, NSError *error) {
        
        OCCredentialsDto *returnUserCredentials = nil;
        NSError *returnError = nil;
        
        if (error  != nil) {
            returnError = error;
        } else if (httpResponse != nil && (httpResponse.statusCode <200 || httpResponse.statusCode >= 300)) {
            // errored HTTP response from server
            returnError = [UtilsFramework getErrorByCodeId:OCErrorOAuth2Error]; //TODO: custom error message
        } else if (httpResponse == nil || data == nil) {
            // generic OAuth2 error, who knows what happened...
            returnError =  [UtilsFramework getErrorByCodeId:OCErrorOAuth2Error];

        } else {
            NSDictionary *dictJSON =  [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            if (dictJSON != nil ) {
                NSString *errorInJSON = [dictJSON objectForKey:@"error"];
                if (errorInJSON) {
                    if ([errorInJSON isEqualToString:@"access_denied"]) {
                        returnError = [UtilsFramework getErrorByCodeId:OCErrorOAuth2ErrorAccessDenied];
                    } else {
                        returnError = [UtilsFramework getErrorByCodeId:OCErrorOAuth2Error];
                    }
                } else {
                    returnUserCredentials = [[OCCredentialsDto alloc] init];
                    returnUserCredentials.userName = [dictJSON objectForKey:@"user_id"];
                    returnUserCredentials.accessToken = [dictJSON objectForKey:@"access_token"];
                    returnUserCredentials.refreshToken = [dictJSON objectForKey:@"refresh_token"];
                    returnUserCredentials.expiresIn = [dictJSON objectForKey:@"expires_in"];
                    returnUserCredentials.tokenType = [dictJSON objectForKey:@"token_type"];
                    returnUserCredentials.authenticationMethod = AuthenticationMethodBEARER_TOKEN;
                }
            } else {
                returnError = [UtilsFramework getErrorByCodeId:OCErrorOAuth2Error];
            }
        }
        
        completion(returnUserCredentials,returnError);
        
    }];

}

- (void) authDataRequestByOAuth2Configuration:(OCOAuth2Configuration *)oauth2Configuration
                                      withURL:(NSURL *)url
                                     authCode:(NSString *)authCode
                                    userAgent:(NSString *)userAgent
                               withCompletion:(void(^)(NSData *data,NSHTTPURLResponse *httpResponse, NSError *error))completion {
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    if (userAgent != nil) {
        [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }
    
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSString *authId = [NSString stringWithFormat:@"%@:%@",oauth2Configuration.clientId,oauth2Configuration.clientSecret];
    NSString *base64EncodedAuthId = [UtilsFramework AFBase64EncodedStringFromString:authId];
    NSString *authorizationValue = [NSString stringWithFormat:@"Basic %@",base64EncodedAuthId];
    [request setValue:authorizationValue forHTTPHeaderField:@"Authorization"];
    
    
    NSString *body = [NSString stringWithFormat:@"grant_type=authorization_code&code=%@&redirect_uri=%@&client_id=%@",
                      authCode,
                      oauth2Configuration.redirectUri,
                      oauth2Configuration.clientId
                      ];
    
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSession *session = nil;
    
    session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error != nil) {
            NSLog(@"Error %@",error.localizedDescription);
            completion(data, nil, error);
            
        } else {
            completion(data, (NSHTTPURLResponse*)response, error);
        }
    }];
    
    [task resume];

}


#pragma mark - Refresh token

- (void) refreshAuthDataByOAuth2Configuration:(OCOAuth2Configuration *)oauth2Configuration
                          withBaseURL:(NSString *)baseURL
                             refreshToken:(NSString *)refreshToken
                                userAgent:(NSString *)userAgent
                                  success:(void(^)(OCCredentialsDto *userCredDto))success
                                  failure:(void(^)(NSError *error))failure {
    
    [UtilsFramework deleteAllCookies];
    
    [self refreshAuthDataRequestByOAuth2Configuration:oauth2Configuration withBaseURL:baseURL refreshToken:refreshToken userAgent:userAgent
     
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
                    
                    NSError *error = [UtilsFramework getErrorByCodeId:OCErrorOAuth2Error];

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

- (void) refreshAuthDataRequestByOAuth2Configuration:(OCOAuth2Configuration *)oauth2Configuration
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


#pragma mark - methods from NSURLSessionDelegate

// Delegate method called when the server responded with an authentication challenge.
// Since iOS is so great, it is also called when the server certificate is not trusted, so that the client
// can decide what to do about it.
//
// In this case we only expect to receive an authentication challenge if the server holds a certificate signed
// by an authority that is not trusted by iOS system. In this case, we need to check the list of certificates
// that were explicitly accepted by the user before, and allow the request to go on if the current one matches
// one of them (and not in other case).
//

- (void) URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    // For the case that the call is due to server certificate not trusted by iOS, we compare the certificate in the
    // authentication challenge with the certificates that were previously accepted by the user in the OC app. If
    // it match any of them, we allow to go on.

    if (self.trustedCertificatesStore != nil && [self.trustedCertificatesStore isTrustedServerCertificateIn:challenge]) {
        // trusted
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    } else {
        // If this method was called due to untrusted server certificate and this was not accepted by the user before,
        // or if it was called due to a different authentication challenge, default handling will lead the task to fail.
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling,nil);
    }
}


/// MARK : methods from NSURLSessionTaskDelegate

// Delegate method called when the server responsed with a redirection
//
// In this case we need to grant that redirections are just followed, but not with the request proposed by the system.
// The requests to access token endpoint are POSTs, and iOS proposes GETs for the redirections
//

- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
            willPerformHTTPRedirection:(NSHTTPURLResponse *)response
                            newRequest:(NSURLRequest *)request
  completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    
    NSLog(@"DetectAuthenticationMethod: redirect detected in URLSessionTaskDelegate implementation");
    
    if (task.currentRequest) {
        NSMutableURLRequest *newRequest = [task.currentRequest mutableCopy];    // let's resuse the last request performed by the task (it's a POST) ...
        newRequest.URL = request.URL;                                           // ... and then override the URL with the redirected one proposed by the system
        
        completionHandler(newRequest); //follow
    } else {
        completionHandler(nil); // we don't know where to redirect, something was really wrong -> stop
    }
}


@end
