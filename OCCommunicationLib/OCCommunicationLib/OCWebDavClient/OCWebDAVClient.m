//
//  OCWebDAVClient.m
//  OCWebDAVClient
//
//  This class is based in https://github.com/zwaldowski/DZWebDAVClient. Copyright (c) 2012 Zachary Waldowski, Troy Brant, Marcus Rohrmoser, and Sam Soffes.
//
// Copyright (C) 2016, ownCloud GmbH. ( http://www.owncloud.org/ )
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


#import "OCWebDAVClient.h"
#import "OCFrameworkConstants.h"
#import "OCCommunication.h"
#import "OCChunkDto.h"
#import "UtilsFramework.h"
#import "AFURLSessionManager.h"
#import "NSString+Encode.h"
#import "OCConstants.h"
#import "OCOAuth2Manager.h"

#define k_server_information_json @"status.php"
#define k_api_header_request @"OCS-APIREQUEST"

#define k_group_sharee_type 1
#define k_retry_ntimes 2  //Retry ntimes request

NSString const *OCWebDAVContentTypeKey		= @"getcontenttype";
NSString const *OCWebDAVETagKey				= @"getetag";
NSString const *OCWebDAVCTagKey				= @"getctag";
NSString const *OCWebDAVCreationDateKey		= @"creationdate";
NSString const *OCWebDAVModificationDateKey	= @"modificationdate";

@interface OCWebDAVClient()

- (void)mr_listPath:(NSString *)path depth:(NSUInteger)depth onCommunication:
(OCCommunication *)sharedOCCommunication
            success:(void(^)(NSHTTPURLResponse *, id))success
            failure:(void(^)(NSHTTPURLResponse *, id  _Nullable responseObject, NSError *))failure;

@end

@implementation OCWebDAVClient

- (id) init {
    
    self = [super init];
    
    if (self != nil) {
        self.defaultHeaders = [NSMutableDictionary new];
    }
    
    return self;
}

- (void)setAuthorizationHeaderWithUsername:(NSString *)username password:(NSString *)password {
	NSString *basicAuthCredentials = [NSString stringWithFormat:@"%@:%@", username, password];

    [self.defaultHeaders setObject:[NSString stringWithFormat:@"Basic %@", [UtilsFramework AFBase64EncodedStringFromString: basicAuthCredentials]] forKey:@"Authorization"];
}

- (void)setAuthorizationHeaderWithCookie:(NSString *) cookieString {
    [self.defaultHeaders setObject:cookieString forKey:@"Cookie"];
}

- (void)setAuthorizationHeaderWithToken:(NSString *)token {
    [self.defaultHeaders setObject:token forKey:@"Authorization"];
}

- (void)setDefaultHeader:(NSString *)header value:(NSString *)value {
    [self.defaultHeaders setObject:value forKey:header];
}

- (void)setUserAgent:(NSString *)userAgent{
    [self.defaultHeaders setObject:userAgent forKey:@"User-Agent"];
}

#pragma mark - Main network operation token

- (NSURLSessionDataTask *)mr_operationWithRequest:(NSMutableURLRequest *)request retryingNumberOfTimes:(NSInteger)ntimes onCommunication:(OCCommunication *)sharedOCCommunication withUserSessionToken:(NSString*)token success:(void(^)(NSHTTPURLResponse *operation, id response, NSString *token))success failure:(void(^)(NSHTTPURLResponse *operation, id  _Nullable responseObject, NSError *error, NSString *token))failure {
    
    //If is not nil is a redirection so we keep the original url server
    if (!self.originalUrlServer) {
        self.originalUrlServer = [request.URL absoluteString];
    }
    
    NSLog(@"Before adding cookies, Main Request with token");
//    NSLog(@"Before adding cookies, Main Request with token for userId:%@ username:%@ url:%@  headers-> %@ ",sharedOCCommunication.credDto.userId, sharedOCCommunication.credDto.userName,request.URL, request.allHTTPHeaderFields);

    if (sharedOCCommunication.isCookiesAvailable) {
        //We add the cookies of that URL
        request = [UtilsFramework getRequestWithCookiesByRequest:request andOriginalUrlServer:self.originalUrlServer];
    } else {
        [UtilsFramework deleteAllCookies];
    }
    
    //NSLog(@"Main Request with token for userId:%@ username:%@ url:%@  headers-> %@ ",sharedOCCommunication.credDto.userId, sharedOCCommunication.credDto.userName,request.URL, request.allHTTPHeaderFields);

    __block   NSURLSessionDataTask *sessionDataTask;
    
    sessionDataTask = [sharedOCCommunication.networkSessionManager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (!error) {
            success((NSHTTPURLResponse*)response,responseObject, token);
        } else {
            if (((NSHTTPURLResponse*)response).statusCode == 401
                && sharedOCCommunication.credDto.authenticationMethod == AuthenticationMethodBEARER_TOKEN
                && sharedOCCommunication.credDto.userId != nil) {
                if (ntimes <= 0) {
                    if (failure) {
                        failure((NSHTTPURLResponse*)response, responseObject, error, token);
                    }
                } else {
                    
                    //get refresh token
                    OCOAuth2Manager* oAuth2Manager = [OCOAuth2Manager new];
                    oAuth2Manager.trustedCertificatesStore = sharedOCCommunication.trustedCertificatesStore;
                    [oAuth2Manager refreshAuthDataByOAuth2Configuration:sharedOCCommunication.oauth2Configuration
                                                          withBaseURL:sharedOCCommunication.credDto.baseURL
                                                         refreshToken:sharedOCCommunication.credDto.refreshToken
                                                            userAgent:sharedOCCommunication.userAgent
                                              success:^(OCCredentialsDto *userCredDto) {
                                                  
                                                  //set and store new credentials
                                                  
                                                  userCredDto.userId = sharedOCCommunication.credDto.userId;
                                                  userCredDto.baseURL = sharedOCCommunication.credDto.baseURL;
                                                  userCredDto.userDisplayName = sharedOCCommunication.credDto.userDisplayName;
                                                  [sharedOCCommunication setCredentials:userCredDto];
                                                  
                                                  [request setValue:[NSString stringWithFormat:@"Bearer %@", userCredDto.accessToken] forHTTPHeaderField:@"Authorization"];

                                                  
                                                  if (sharedOCCommunication.credentialsStorage != nil) {
                                                      [sharedOCCommunication.credentialsStorage saveCredentials:sharedOCCommunication.credDto];
                                                  }
                                                
                                                  sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:(ntimes -1)
                                                                onCommunication:sharedOCCommunication
                                                           withUserSessionToken:token
                                                                        success:success
                                                                        failure:failure
                                                   ];
                                                  [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
                                                  [sessionDataTask resume];
                                                  
                                              } failure:^(NSError *error) {
                                                  failure(nil, nil, error, nil);
                                                  
                                              }];
                }
            } else {
                failure((NSHTTPURLResponse*)response, responseObject, error, token);
            }
        }
    }];
    
    return sessionDataTask;
}

#pragma mark - Main network operation
- (NSURLSessionDataTask *)mr_operationWithRequest:(NSMutableURLRequest *)request retryingNumberOfTimes:(NSInteger)ntimes onCommunication:(OCCommunication *)sharedOCCommunication success:(void(^)(NSHTTPURLResponse *, id))success failure:(void(^)(NSHTTPURLResponse *, id  _Nullable responseObject, NSError *))failure {
    
    //If is not nil is a redirection so we keep the original url server
    if (!self.originalUrlServer) {
        self.originalUrlServer = [request.URL absoluteString];
    }
    
    NSLog(@"Before adding cookies");
    //NSLog(@"Before adding cookies, Request for userId:%@ username:%@ url:%@ headers-> %@ ",sharedOCCommunication.credDto.userId, sharedOCCommunication.credDto.userName,request.URL, request.allHTTPHeaderFields);

    if (sharedOCCommunication.isCookiesAvailable) {
        //We add the cookies of that URL
        request = [UtilsFramework getRequestWithCookiesByRequest:request andOriginalUrlServer:self.originalUrlServer];
    } else {
        [UtilsFramework deleteAllCookies];
    }
    
   // NSLog(@"Request for userId:%@ username:%@ url:%@ headers-> %@ ",sharedOCCommunication.credDto.userId, sharedOCCommunication.credDto.userName,request.URL, request.allHTTPHeaderFields);

    __block NSURLSessionDataTask *sessionDataTask;
    
    sessionDataTask = [sharedOCCommunication.networkSessionManager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (!error) {
            success((NSHTTPURLResponse*)response,responseObject);
        } else {
            
            if (((NSHTTPURLResponse*)response).statusCode == 401
                && sharedOCCommunication.credDto.authenticationMethod == AuthenticationMethodBEARER_TOKEN
                && sharedOCCommunication.credDto.userId != nil) {
                if (ntimes <= 0) {
                    if (failure) {
                        failure((NSHTTPURLResponse*)response, responseObject, error);
                    }
                } else {
                    
                    //get refresh token
                    OCOAuth2Manager* oAuth2Manager = [OCOAuth2Manager new];
                    oAuth2Manager.trustedCertificatesStore = sharedOCCommunication.trustedCertificatesStore;
                    [oAuth2Manager refreshAuthDataByOAuth2Configuration:sharedOCCommunication.oauth2Configuration
                                                          withBaseURL:sharedOCCommunication.credDto.baseURL
                                                         refreshToken:sharedOCCommunication.credDto.refreshToken
                                                            userAgent:sharedOCCommunication.userAgent
                    success:^(OCCredentialsDto *userCredDto) {
                       
                        //set and store new credentials
                        
                        userCredDto.userId = sharedOCCommunication.credDto.userId;
                        userCredDto.baseURL = sharedOCCommunication.credDto.baseURL;
                        userCredDto.userDisplayName = sharedOCCommunication.credDto.userDisplayName;
                        [sharedOCCommunication setCredentials:userCredDto];
                        [request setValue:[NSString stringWithFormat:@"Bearer %@", userCredDto.accessToken] forHTTPHeaderField:@"Authorization"];
                        
                        if (sharedOCCommunication.credentialsStorage != nil) {
                            [sharedOCCommunication.credentialsStorage saveCredentials:sharedOCCommunication.credDto];
                        }
                        
                        sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:(ntimes - 1)
                                      onCommunication:sharedOCCommunication
                                              success:success
                                              failure:failure
                        ];
                        [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
                        [sessionDataTask resume];
                        
                    } failure:^(NSError *error) {
                        failure(nil,nil,error);
                    }];
                }
            } else {
                failure((NSHTTPURLResponse*)response, responseObject, error);
                
            }
        }
    }];
    
    return sessionDataTask;
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters {
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer new] requestWithMethod:method URLString:path parameters:nil error:nil];
    [request setAllHTTPHeaderFields:self.defaultHeaders];
    
    [request setCachePolicy: NSURLRequestReloadIgnoringLocalCacheData];
    [request setTimeoutInterval: k_timeout_webdav];
    
    return request;
}

- (NSMutableURLRequest *)sharedRequestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters {
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer new] requestWithMethod:method URLString:path parameters:nil error:nil];
    
    [request setAllHTTPHeaderFields:self.defaultHeaders];
    
    //NSMutableURLRequest *request = [super requestWithMethod:method path:path parameters:parameters];
    [request setCachePolicy: NSURLRequestReloadIgnoringLocalCacheData];
    [request setTimeoutInterval: k_timeout_webdav];
    //Header for use the OC API CALL
    NSString *ocs_apiquests = @"true";
    [request setValue:ocs_apiquests forHTTPHeaderField:k_api_header_request];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
    
    return request;
}


- (void)movePath:(NSString *)source toPath:(NSString *)destination
 onCommunication:(OCCommunication *)sharedOCCommunication
         success:(void(^)(NSHTTPURLResponse *, id))success
         failure:(void(^)(NSHTTPURLResponse *, id  _Nullable responseObject, NSError *))failure {
    _requestMethod = @"MOVE";
    NSMutableURLRequest *request = [self requestWithMethod:_requestMethod path:source parameters:nil];
    [request setValue:destination forHTTPHeaderField:@"Destination"];
	[request setValue:@"T" forHTTPHeaderField:@"Overwrite"];
	NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];
}

- (void)deletePath:(NSString *)path
   onCommunication:(OCCommunication *)sharedOCCommunication
           success:(void(^)(NSHTTPURLResponse *, id))success
           failure:(void(^)(NSHTTPURLResponse *, id  _Nullable responseObject, NSError *))failure {
    
    _requestMethod = @"DELETE";
    NSMutableURLRequest *request = [self requestWithMethod:_requestMethod path:path parameters:nil];
	NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];
}


- (void)mr_listPath:(NSString *)path depth:(NSUInteger)depth onCommunication:
(OCCommunication *)sharedOCCommunication
            success:(void(^)(NSHTTPURLResponse *, id))success
            failure:(void(^)(NSHTTPURLResponse *, id  _Nullable responseObject, NSError *))failure {
	NSParameterAssert(success);
    
    _requestMethod = @"PROPFIND";
	NSMutableURLRequest *request = [self requestWithMethod:_requestMethod path:path parameters:nil];
	NSString *depthHeader = nil;
	if (depth <= 0)
		depthHeader = @"0";
	else if (depth == 1)
		depthHeader = @"1";
	else
		depthHeader = @"infinity";
    [request setValue: depthHeader forHTTPHeaderField: @"Depth"];
    
    [request setHTTPBody:[@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><D:propfind xmlns:D=\"DAV:\"><D:prop><D:resourcetype/><D:getlastmodified/><size xmlns=\"http://owncloud.org/ns\"/><D:creationdate/><id xmlns=\"http://owncloud.org/ns\"/><D:getcontentlength/><D:displayname/><D:quota-available-bytes/><D:getetag/><permissions xmlns=\"http://owncloud.org/ns\"/><D:quota-used-bytes/><D:getcontenttype/></D:prop></D:propfind>" dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];
}

- (void)mr_listPath:(NSString *)path depth:(NSUInteger)depth withUserSessionToken:(NSString*)token onCommunication:
(OCCommunication *)sharedOCCommunication
            success:(void(^)(NSHTTPURLResponse *operation, id response, NSString *token))success
            failure:(void(^)(NSHTTPURLResponse *response, id  _Nullable responseObject, NSError *, NSString *token))failure {
    NSParameterAssert(success);
    
    _requestMethod = @"PROPFIND";
    NSMutableURLRequest *request = [self requestWithMethod:_requestMethod path:path parameters:nil];
    NSString *depthHeader = nil;
    if (depth <= 0)
        depthHeader = @"0";
    else if (depth == 1)
        depthHeader = @"1";
    else
        depthHeader = @"infinity";
    [request setValue: depthHeader forHTTPHeaderField: @"Depth"];
    
    [request setHTTPBody:[@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><D:propfind xmlns:D=\"DAV:\"><D:prop><D:resourcetype/><D:getlastmodified/><size xmlns=\"http://owncloud.org/ns\"/><D:creationdate/><id xmlns=\"http://owncloud.org/ns\"/><D:getcontentlength/><D:displayname/><D:quota-available-bytes/><D:getetag/><permissions xmlns=\"http://owncloud.org/ns\"/><D:quota-used-bytes/><D:getcontenttype/></D:prop></D:propfind>" dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication withUserSessionToken:token success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];
}

- (void)propertiesOfPath:(NSString *)path
         onCommunication: (OCCommunication *)sharedOCCommunication
                 success:(void(^)(NSHTTPURLResponse *, id ))success
                 failure:(void(^)(NSHTTPURLResponse *, id  _Nullable responseObject, NSError *))failure {
	[self mr_listPath:path depth:0 onCommunication:sharedOCCommunication success:success failure:failure];
}

- (void)listPath:(NSString *)path
 onCommunication:(OCCommunication *)sharedOCCommunication
         success:(void(^)(NSHTTPURLResponse *, id))success
         failure:(void(^)(NSHTTPURLResponse *, id  _Nullable responseObject, NSError *))failure {
	[self mr_listPath:path depth:1 onCommunication:sharedOCCommunication success:success failure:failure];
}

- (void)listPath:(NSString *)path
 onCommunication:(OCCommunication *)sharedOCCommunication withUserSessionToken:(NSString *)token
         success:(void(^)(NSHTTPURLResponse *, id, NSString *token))success
         failure:(void(^)(NSHTTPURLResponse *, id  _Nullable responseObject, NSError *, NSString *token))failure {
    [self mr_listPath:path depth:1 withUserSessionToken:token onCommunication:sharedOCCommunication success:success failure:failure];
}


#pragma mark - download requests

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSMutableURLRequest *)request
                                               toPath:(NSString *)localDestination
                                      defaultPriority:(BOOL)defaultPriority
                                retryingNumberOfTimes:(NSInteger)ntimes
                                      onCommunication:(OCCommunication *)sharedOCCommunication
                                             progress:(void(^)(NSProgress *progress))downloadProgress
                                              success:(void(^)(NSURLResponse *response, NSURL *filePath))success failure:(void(^)(NSURLResponse *response, NSError *error))failure {
    
    NSURL *localDestinationUrl = [NSURL fileURLWithPath:localDestination];

    __block NSURLSessionDownloadTask *downloadTask = [sharedOCCommunication.downloadSessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull progress) {
        downloadProgress(progress);
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        if (((NSHTTPURLResponse*)response).statusCode == 401) {
            return nil;
        } else {
            return localDestinationUrl;
        }
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        if (!error) {
            success(response,filePath);
        } else {
            if (((NSHTTPURLResponse*)response).statusCode == 401
                && sharedOCCommunication.credDto.authenticationMethod == AuthenticationMethodBEARER_TOKEN
                && sharedOCCommunication.credDto.userId != nil) {
                if (ntimes <= 0) {
                    if (failure) {
                        failure(response, error);
                    }
                } else {
                    //get refresh token
                    OCOAuth2Manager* oAuth2Manager = [OCOAuth2Manager new];
                    oAuth2Manager.trustedCertificatesStore = sharedOCCommunication.trustedCertificatesStore;
                    [oAuth2Manager refreshAuthDataByOAuth2Configuration:sharedOCCommunication.oauth2Configuration
                                                          withBaseURL:sharedOCCommunication.credDto.baseURL
                                                         refreshToken:sharedOCCommunication.credDto.refreshToken
                                                            userAgent:sharedOCCommunication.userAgent
                    success:^(OCCredentialsDto *userCredDto) {
                        
                        //set and store new credentials
                        
                        userCredDto.userId = sharedOCCommunication.credDto.userId;
                        userCredDto.baseURL = sharedOCCommunication.credDto.baseURL;
                        userCredDto.userDisplayName = sharedOCCommunication.credDto.userDisplayName;
                        [sharedOCCommunication setCredentials:userCredDto];
                        
                        [request setValue:[NSString stringWithFormat:@"Bearer %@", userCredDto.accessToken] forHTTPHeaderField:@"Authorization"];
                        
                        if (sharedOCCommunication.credentialsStorage != nil) {
                            [sharedOCCommunication.credentialsStorage saveCredentials:sharedOCCommunication.credDto];
                        }
                        
                        downloadTask = [self downloadTaskWithRequest:request
                                                              toPath:localDestination
                                                     defaultPriority:defaultPriority
                                               retryingNumberOfTimes:(ntimes -1)
                                                     onCommunication:sharedOCCommunication
                                                            progress:downloadProgress
                                                             success:success
                                                             failure:failure];
                        
                        [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.downloadSessionManager];
                        [downloadTask resume];
                        
                    } failure:^(NSError *error) {
                        failure(response, error);
                    }];
                }
                
                
            } else {
                failure(response, error);
            }
        }
    }];
    
    return downloadTask;
}



- (NSURLSessionDownloadTask *)downloadWithSessionPath:(NSString *)remoteSource
                                               toPath:(NSString *)localDestination
                                      defaultPriority:(BOOL)defaultPriority
                                      onCommunication:(OCCommunication *)sharedOCCommunication
                                             progress:(void(^)(NSProgress *progress))downloadProgress
                                              success:(void(^)(NSURLResponse *response, NSURL *filePath))success
                                              failure:(void(^)(NSURLResponse *response, NSError *error))failure {
    
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" path:remoteSource parameters:nil];
    
    //If is not nil is a redirection so we keep the original url server
    if (!self.originalUrlServer) {
        self.originalUrlServer = [request.URL absoluteString];
    }
    
    //We add the cookies of that URL
    request = [UtilsFramework getRequestWithCookiesByRequest:request andOriginalUrlServer:self.originalUrlServer];
    
    NSURLSessionDownloadTask *downloadTask = [self downloadTaskWithRequest:request
                                                                    toPath:localDestination
                                                           defaultPriority:defaultPriority
                                                     retryingNumberOfTimes:k_retry_ntimes
                                                           onCommunication:sharedOCCommunication
                                                                  progress:downloadProgress
                                                                   success:success
                                                                   failure:failure];

    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.downloadSessionManager];
    
    if (defaultPriority) {
         [downloadTask resume];
    }

    return downloadTask;
}

- (void)makeCollection:(NSString *)path onCommunication:
(OCCommunication *)sharedOCCommunication
               success:(void(^)(NSHTTPURLResponse *, id))success
               failure:(void(^)(NSHTTPURLResponse *, id  _Nullable responseObject, NSError *))failure {
    _requestMethod = @"MKCOL";
	NSMutableURLRequest *request = [self requestWithMethod:_requestMethod path:path parameters:nil];
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];
}

#pragma mark - upload requests

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSMutableURLRequest *)request
                                      fromFileURL:(NSURL *)fileURL
                            retryingNumberOfTimes:(NSInteger)ntimes
                                  onCommunication:(OCCommunication *)sharedOCCommunication
                                         progress:(void(^)(NSProgress *progress))uploadProgress
                                          success:(void(^)(NSURLResponse *, NSString *))success
                                          failure:(void(^)(NSURLResponse *, id, NSError *))failure {
 
    __block NSURLSessionUploadTask *uploadTask = [sharedOCCommunication.uploadSessionManager uploadTaskWithRequest:request fromFile:fileURL progress:^(NSProgress * _Nonnull progress) {
        uploadProgress(progress);
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (!error) {
            success(response,responseObject);
        } else {
            if ( ((NSHTTPURLResponse*)response).statusCode == 401
                && sharedOCCommunication.credDto.authenticationMethod == AuthenticationMethodBEARER_TOKEN
                && sharedOCCommunication.credDto.userId != nil){
                if (ntimes <= 0) {
                    if (failure) {
                        failure(response, responseObject, error);
                    }
                } else {
                    //get refresh token
                    OCOAuth2Manager* oAuth2Manager = [OCOAuth2Manager new];
                    oAuth2Manager.trustedCertificatesStore = sharedOCCommunication.trustedCertificatesStore;
                    [oAuth2Manager refreshAuthDataByOAuth2Configuration:sharedOCCommunication.oauth2Configuration
                                                          withBaseURL:sharedOCCommunication.credDto.baseURL
                                                         refreshToken:sharedOCCommunication.credDto.refreshToken
                                                            userAgent:sharedOCCommunication.userAgent
                                                              success:^(OCCredentialsDto *userCredDto) {
                                                                  
                                                                  //set and store new credentials
                                                
                                                                  userCredDto.userId = sharedOCCommunication.credDto.userId;
                                                                  userCredDto.baseURL = sharedOCCommunication.credDto.baseURL;
                                                                  userCredDto.userDisplayName = sharedOCCommunication.credDto.userDisplayName;
                                                                  [sharedOCCommunication setCredentials:userCredDto];
                                                                  
                                                                  [request setValue:[NSString stringWithFormat:@"Bearer %@", userCredDto.accessToken] forHTTPHeaderField:@"Authorization"];
                                                                  
                                                                  if (sharedOCCommunication.credentialsStorage != nil) {
                                                                      [sharedOCCommunication.credentialsStorage saveCredentials:sharedOCCommunication.credDto];
                                                                  }
                                                                  
                                                                  uploadTask = [self uploadTaskWithRequest:request
                                                                                               fromFileURL:fileURL
                                                                                     retryingNumberOfTimes:(ntimes -1)
                                                                                           onCommunication:sharedOCCommunication
                                                                                                  progress:uploadProgress
                                                                                                   success:success
                                                                                                   failure:failure];
                                                                  [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.uploadSessionManager];
                                                                  [uploadTask resume];
                                                                  
                                                              } failure:^(NSError *error) {
                                                                  failure(response, responseObject, error);
                                                              }];
                }
            } else {
                failure(response, responseObject, error);
            }
        }
    }];

    return uploadTask;
}

- (NSURLSessionUploadTask *)putWithSessionLocalPath:(NSString *)localSource
                                       atRemotePath:(NSString *)remoteDestination
                                    onCommunication:(OCCommunication *)sharedOCCommunication
                                           progress:(void(^)(NSProgress *progress))uploadProgress
                                            success:(void(^)(NSURLResponse *, NSString *))success
                                            failure:(void(^)(NSURLResponse *, id, NSError *))failure
                               failureBeforeRequest:(void(^)(NSError *)) failureBeforeRequest {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (localSource == nil || ![fileManager fileExistsAtPath:localSource]) {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"You are trying upload a file that does not exist" forKey:NSLocalizedDescriptionKey];
        
        NSError *error = [NSError errorWithDomain:k_domain_error_code code:OCErrorFileToUploadDoesNotExist userInfo:details];
        
        failureBeforeRequest(error);
        
        return nil;
    } else {
    
        NSMutableURLRequest *request = [self requestWithMethod:@"PUT" path:remoteDestination parameters:nil];
        [request setTimeoutInterval:k_timeout_upload];
        [request setValue:[NSString stringWithFormat:@"%lld", [UtilsFramework getSizeInBytesByPath:localSource]] forHTTPHeaderField:@"Content-Length"];
        [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        
        //If is not nil is a redirection so we keep the original url server
        if (!self.originalUrlServer) {
            self.originalUrlServer = [request.URL absoluteString];
        }
        
        NSLog(@"Before adding cookies, Request put");
//        NSLog(@"Before adding cookies, Request put for userId:%@ username:%@ url:%@ headers-> %@ ",sharedOCCommunication.credDto.userId, sharedOCCommunication.credDto.userName,request.URL, request.allHTTPHeaderFields);

        if (sharedOCCommunication.isCookiesAvailable) {
            //We add the cookies of that URL
            request = [UtilsFramework getRequestWithCookiesByRequest:request andOriginalUrlServer:self.originalUrlServer];
        } else {
            [UtilsFramework deleteAllCookies];
        }
        
       // NSLog(@"Request put for userId:%@ username:%@ url:%@ headers-> %@ ",sharedOCCommunication.credDto.userId, sharedOCCommunication.credDto.userName,request.URL, request.allHTTPHeaderFields);

        NSURL *file = [NSURL fileURLWithPath:localSource];
        
        sharedOCCommunication.uploadSessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        NSURLSessionUploadTask *uploadTask = [self uploadTaskWithRequest:request
                                                             fromFileURL:file
                                                   retryingNumberOfTimes:k_retry_ntimes
                                                         onCommunication:sharedOCCommunication
                                                                progress:uploadProgress
                                                                 success:success
                                                                 failure:failure];
        
        [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.uploadSessionManager];
        [uploadTask resume];
        
        return uploadTask;
    }
}


- (void) requestUserDataOfServer:(NSString * _Nonnull) path
                  onCommunication:(OCCommunication * _Nonnull)sharedOCCommunication
                          success:(void(^ _Nonnull)(NSHTTPURLResponse * _Nonnull, id _Nonnull))success
                          failure:(void(^ _Nonnull)(NSHTTPURLResponse * _Nonnull, id  _Nullable responseObject, NSError * _Nonnull))failure {
    
    NSString *apiUserUrl = nil;
    apiUserUrl = [NSString stringWithFormat:@"%@%@", path, k_api_user_url_json];
    
    _requestMethod = @"GET";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path: apiUserUrl parameters: nil];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];
}


- (void) requestUserNameOfServer:(NSString * _Nonnull) path
                        byCookie:(NSString * _Nonnull) cookieString
                 onCommunication:(OCCommunication * _Nonnull)sharedOCCommunication
                         success:(void(^ _Nonnull)(NSHTTPURLResponse * _Nonnull, id _Nonnull))success
                         failure:(void(^ _Nonnull)(NSHTTPURLResponse * _Nonnull, id  _Nullable responseObject, NSError * _Nonnull))failure {
    
    NSString *apiUserUrl = nil;
    apiUserUrl = [NSString stringWithFormat:@"%@%@", path, k_api_user_url_json];
    
    _requestMethod = @"GET";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path: apiUserUrl parameters: nil];
	[request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];
}


- (void) simpleGetRequest: (NSURL *)path
                  onCommunication:(OCCommunication *)sharedOCCommunication
                  success:(void(^)(NSHTTPURLResponse *operation, id responseObject))success
                  failure:(void(^)(NSHTTPURLResponse *operation, id  _Nullable responseObject, NSError *error))failure {

    _requestMethod = @"GET";
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path: path.absoluteString parameters: nil];
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
//    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];

    
}


- (void) getStatusOfTheServer:(NSString *)serverPath onCommunication:
(OCCommunication *)sharedOCCommunication success:(void(^)(NSHTTPURLResponse *operation, id responseObject))success
                            failure:(void(^)(NSHTTPURLResponse *operation, id  _Nullable responseObject, NSError *error))failure  {
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@", serverPath, k_server_information_json];
    
    _requestMethod = @"GET";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path: urlString parameters: nil];
    
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];
}

- (void)listSharedByServer:(NSString *)serverPath
 onCommunication:(OCCommunication *)sharedOCCommunication
         success:(void(^)(NSHTTPURLResponse *, id))success
         failure:(void(^)(NSHTTPURLResponse *, id  _Nullable responseObject, NSError *))failure {
    
    NSParameterAssert(success);
    
    _requestMethod = @"GET";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];
}

- (void)listSharedByServer:(NSString *)serverPath andPath:(NSString *) path
           onCommunication:(OCCommunication *)sharedOCCommunication
                   success:(void(^)(NSHTTPURLResponse *, id))success
                   failure:(void(^)(NSHTTPURLResponse *, id  _Nullable responseObject, NSError *))failure {
    
    NSParameterAssert(success);
	
    NSString *postString = [NSString stringWithFormat: @"?path=%@&subfiles=true",path];
    serverPath = [serverPath stringByAppendingString:postString];
    _requestMethod = @"GET";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];
}


- (void)shareByLinkFileOrFolderByServer:(NSString * _Nonnull)serverPath
                                andPath:(NSString * _Nonnull)filePath
                               password:(NSString * _Nullable)password
                         expirationTime:(NSString * _Nullable)expirationTime
                            publicUpload:(NSString * _Nullable)publicUpload
                               linkName:(NSString * _Nullable)linkName
                            permissions:(NSInteger)permissions
                        onCommunication:(OCCommunication * _Nonnull)sharedOCCommunication
                                success:(void(^ _Nonnull)(NSHTTPURLResponse * _Nonnull, id _Nonnull))success
                                failure:(void(^ _Nonnull)(NSHTTPURLResponse * _Nonnull, id  _Nullable responseObject, NSError * _Nonnull))failure {
   
    NSParameterAssert(success);
    
    self.requestMethod = @"POST";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:self.requestMethod path:serverPath parameters:nil];
    self.postStringForShare = [NSString stringWithFormat: @"path=%@&shareType=3",filePath];
    
    if (password) {
        self.postStringForShare = [NSString stringWithFormat:@"%@&password=%@",self.postStringForShare,password];
    }
    if (expirationTime) {
        self.postStringForShare = [NSString stringWithFormat:@"%@&expireDate=%@",self.postStringForShare,expirationTime];
    }
    if (linkName) {
        self.postStringForShare = [NSString stringWithFormat:@"%@&name=%@",self.postStringForShare,linkName];
    }
    
    if (permissions != 0) {
        self.postStringForShare = [NSString stringWithFormat:@"%@&permissions=%d",self.postStringForShare,(int)permissions];
    } else if ([publicUpload isEqualToString:@"true"]) {
        self.postStringForShare = [NSString stringWithFormat:@"%@&publicUpload=%@",self.postStringForShare,@"true"];
    } else if ([publicUpload isEqualToString:@"false"]) {
        self.postStringForShare = [NSString stringWithFormat:@"%@&publicUpload=%@",self.postStringForShare,@"false"];
    }
    
    [request setHTTPBody:[self.postStringForShare dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];
}

- (void)shareByLinkFileOrFolderByServer:(NSString *)serverPath andPath:(NSString *) filePath andPassword:(NSString *)password
                        onCommunication:(OCCommunication *)sharedOCCommunication
                                success:(void(^)(NSHTTPURLResponse *, id))success
                                failure:(void(^)(NSHTTPURLResponse *, id  _Nullable responseObject, NSError *))failure {
    NSParameterAssert(success);
    
    _requestMethod = @"POST";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    _postStringForShare = [NSString stringWithFormat: @"path=%@&shareType=3&password=%@",filePath,password];
    [request setHTTPBody:[_postStringForShare dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];
}

- (void)shareByLinkFileOrFolderByServer:(NSString *)serverPath andPath:(NSString *) filePath
                  onCommunication:(OCCommunication *)sharedOCCommunication
                          success:(void(^)(NSHTTPURLResponse *, id))success
                          failure:(void(^)(NSHTTPURLResponse *, id  _Nullable responseObject, NSError *))failure {
    NSParameterAssert(success);
    
    _requestMethod = @"POST";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    _postStringForShare = [NSString stringWithFormat: @"path=%@&shareType=3",filePath];
    [request setHTTPBody:[_postStringForShare dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];
}

- (void)shareWith:(NSString *)userOrGroup shareeType:(NSInteger)shareeType inServer:(NSString *) serverPath andPath:(NSString *) filePath andPermissions:(NSInteger) permissions onCommunication:(OCCommunication *)sharedOCCommunication
                                success:(void(^)(NSHTTPURLResponse *, id))success
                                failure:(void(^)(NSHTTPURLResponse *, id  _Nullable responseObject, NSError *))failure {
    NSParameterAssert(success);
    
    _requestMethod = @"POST";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    
    self.postStringForShare = [NSString stringWithFormat: @"path=%@&shareType=%ld&shareWith=%@&permissions=%ld",filePath, (long)shareeType, userOrGroup, (long)permissions];
    [request setHTTPBody:[_postStringForShare dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];
}


- (void)unShareFileOrFolderByServer:(NSString *)serverPath
                        onCommunication:(OCCommunication *)sharedOCCommunication
                                success:(void(^)(NSHTTPURLResponse *, id))success
                                failure:(void(^)(NSHTTPURLResponse *, id  _Nullable responseObject, NSError *))failure {
    NSParameterAssert(success);
    
    _requestMethod = @"DELETE";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];
}


- (void)isShareFileOrFolderByServer:(NSString *)serverPath
                    onCommunication:(OCCommunication *)sharedOCCommunication
                            success:(void(^)(NSHTTPURLResponse *, id))success
                            failure:(void(^)(NSHTTPURLResponse *, id  _Nullable responseObject, NSError *))failure {
    NSParameterAssert(success);
    
    _requestMethod = @"GET";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];
}

- (void) updateShareItem:(NSInteger)shareId
            ofServerPath:(NSString * _Nonnull)serverPath
     withPasswordProtect:(NSString * _Nullable)password
       andExpirationTime:(NSString * _Nullable)expirationTime
         andPublicUpload:(NSString * _Nullable)publicUpload
             andLinkName:(NSString * _Nullable)linkName
          andPermissions:(NSInteger)permissions
         onCommunication:(OCCommunication * _Nonnull)sharedOCCommunication
                 success:(void(^ _Nonnull)(NSHTTPURLResponse * _Nonnull operation, id _Nonnull response))success
                 failure:(void(^ _Nonnull)(NSHTTPURLResponse * _Nonnull operation, id  _Nullable responseObject, NSError * _Nonnull error))failure {
    
    NSParameterAssert(success);
    
    _requestMethod = @"PUT"; 
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    
    self.postStringForShare = @"";
    
    if (password) {
        self.postStringForShare = [NSString stringWithFormat:@"password=%@",password];
    } else if (expirationTime) {
        self.postStringForShare = [NSString stringWithFormat:@"expireDate=%@",expirationTime];
    }else if (linkName) {
        self.postStringForShare = [NSString stringWithFormat:@"name=%@",linkName];
    } if (permissions != 0) {
        self.postStringForShare = [NSString stringWithFormat:@"permissions=%d",(int)permissions];
    } else if ([publicUpload isEqualToString:@"true"]) {
        self.postStringForShare = [NSString stringWithFormat:@"publicUpload=%@",@"true"];
    } else if ([publicUpload isEqualToString:@"false"]) {
        self.postStringForShare = [NSString stringWithFormat:@"publicUpload=%@",@"false"];
    }
    
    [request setHTTPBody:[_postStringForShare dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];
}

- (void) updateShareItem:(NSInteger)shareId
            ofServerPath:(NSString*)serverPath
     withPasswordProtect:(NSString*)password
       andExpirationTime:(NSString*)expirationTime
          andPermissions:(NSInteger)permissions
         onCommunication:(OCCommunication *)sharedOCCommunication
                 success:(void(^)(NSHTTPURLResponse *, id response))success
                 failure:(void(^)(NSHTTPURLResponse *, id  _Nullable responseObject, NSError *error))failure{
    
    NSParameterAssert(success);
    
    _requestMethod = @"PUT";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    
    if (password) {
        self.postStringForShare = [NSString stringWithFormat:@"password=%@",password];
    } else if (expirationTime) {
        self.postStringForShare = [NSString stringWithFormat:@"expireDate=%@",expirationTime];
    }else if (permissions > 0) {
        self.postStringForShare = [NSString stringWithFormat:@"permissions=%d",(int)permissions];
    }
    
    [request setHTTPBody:[_postStringForShare dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];
}

- (void) searchUsersAndGroupsWith:(NSString *)searchString forPage:(NSInteger)page with:(NSInteger)resultsPerPage ofServer:(NSString*)serverPath onCommunication:(OCCommunication *)sharedOCCommunication success:(void(^)(NSHTTPURLResponse *operation, id response))success
    failure:(void(^)(NSHTTPURLResponse *operation, id  _Nullable responseObject, NSError *error))failure {
    
    NSParameterAssert(success);
    
    _requestMethod = @"GET";
    
    NSString *searchQuery = [NSString stringWithFormat: @"&search=%@",searchString];
    NSString *jsonQuery = [NSString stringWithFormat:@"?format=json"];
    NSString *queryType = [NSString stringWithFormat:@"&itemType=file"];
    NSString *pagination = [NSString stringWithFormat:@"&page=%ld&perPage=%ld", (long)page, (long)resultsPerPage];
    serverPath = [serverPath stringByAppendingString:jsonQuery];
    serverPath = [serverPath stringByAppendingString:queryType];
    serverPath = [serverPath stringByAppendingString:searchQuery];
    serverPath = [serverPath stringByAppendingString:pagination];

    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];
}

- (void) getCapabilitiesOfServer:(NSString*)serverPath onCommunication:(OCCommunication *)sharedOCCommunication success:(void(^)(NSHTTPURLResponse *operation, id response))success
                         failure:(void(^)(NSHTTPURLResponse *operation, id  _Nullable responseObject, NSError *error))failure{
    _requestMethod = @"GET";
    
    NSString *jsonQuery = [NSString stringWithFormat:@"?format=json"];
    serverPath = [serverPath stringByAppendingString:jsonQuery];
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    [sessionDataTask resume];

    
}


#pragma mark - Remote thumbnails

- (NSURLSessionDataTask *) getRemoteThumbnailByServer:(NSString*)serverPath ofFilePath:(NSString*)filePath  withWidth:(NSInteger)fileWidth andHeight:(NSInteger)fileHeight onCommunication:(OCCommunication *)sharedOCCommunication
                            success:(void(^)(NSHTTPURLResponse *operation, id response))success
                            failure:(void(^)(NSHTTPURLResponse *operation, id  _Nullable responseObject, NSError *error))failure{
    _requestMethod = @"GET";
    
    NSString *query = [NSString stringWithFormat:@"/%i/%i/%@", (int)fileWidth, (int)fileHeight, filePath];
    serverPath = [serverPath stringByAppendingString:query];
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    
    NSURLSessionDataTask *sessionDataTask = [self mr_operationWithRequest:request retryingNumberOfTimes:k_retry_ntimes onCommunication:sharedOCCommunication success:success failure:failure];
    [self setRedirectionBlockOnDatataskWithOCCommunication:sharedOCCommunication andSessionManager:sharedOCCommunication.networkSessionManager];
    
    return sessionDataTask;
}


#pragma mark - Manage Redirections

- (void) setRedirectionBlockOnDatataskWithOCCommunication: (OCCommunication *) sharedOCCommunication andSessionManager:(AFURLSessionManager *) sessionManager{
    
    [sessionManager setTaskWillPerformHTTPRedirectionBlock:^NSURLRequest * _Nonnull(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSURLResponse * _Nonnull response, NSURLRequest * _Nonnull request) {
        
        if (response == nil) {
            // needed to handle fake redirects to canonical addresses, as explained in https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/URLLoadingSystem/Articles/RequestChanges.html
            return request;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        NSDictionary *dict = [httpResponse allHeaderFields];
        //Server path of redirected server
        NSString *responseURLString = [dict objectForKey:@"Location"];
        
        if (responseURLString) {
            
            if ([UtilsFramework isURLWithSamlFragment:responseURLString] || httpResponse.statusCode == k_redirected_code_1) {
                //We set the redirectedServer in case SAML or is a permanent redirection
                self.redirectedServer = responseURLString;
                
                if ([UtilsFramework isURLWithSamlFragment:responseURLString]) {
                    // if SAML request, we don't want to follow it; WebView takes care, not here -> nil to NO FOLLOW
                    return nil;
                }
            }
            
            NSMutableURLRequest *requestRedirect = [request mutableCopy];
            [requestRedirect setURL: [NSURL URLWithString:responseURLString]];
            
            requestRedirect = [sharedOCCommunication getRequestWithCredentials:requestRedirect];
            requestRedirect.HTTPMethod = _requestMethod;
            
            if (_postStringForShare) {
                //It is a request to share a file by link
                requestRedirect = [self sharedRequestWithMethod:_requestMethod path:responseURLString parameters:nil];
                [requestRedirect setHTTPBody:[_postStringForShare dataUsingEncoding:NSUTF8StringEncoding]];
            }
            
            return requestRedirect;
            
        } else {
            // no location to redirect -> nil to NO FOLLOW
            return nil;
        }
        
    }];
}


@end
