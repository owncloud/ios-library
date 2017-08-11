//
//  OCCommunication.m
//  Owncloud iOs Client
//
// Copyright (C) 2016, ownCloud GmbH.  ( http://www.owncloud.org/ )
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

#import "OCCommunication.h"
#import "OCHTTPRequestOperation.h"
#import "UtilsFramework.h"
#import "OCXMLParser.h"
#import "OCXMLSharedParser.h"
#import "OCXMLServerErrorsParser.h"
#import "NSString+Encode.h"
#import "OCFrameworkConstants.h"
#import "OCWebDAVClient.h"
#import "OCXMLShareByLinkParser.h"
#import "OCErrorMsg.h"
#import "AFURLSessionManager.h"
#import "OCShareUser.h"
#import "OCCapabilities.h"
#import "OCServerFeatures.h"

@interface OCCommunication ()

@property (nonatomic, strong) NSString *currentServerVersion;

@end

@implementation OCCommunication


-(id) init {
    
    self = [super init];
    
    if (self) {
        
        //Init the Donwload queue array
        self.downloadTaskNetworkQueueArray = [NSMutableArray new];
        
        //Credentials not set yet
        self.kindOfCredential = credentialNotSet;
        
        [self setSecurityPolicyManagers:[self createSecurityPolicy]];
        
        self.isCookiesAvailable = YES;
        self.isForbiddenCharactersAvailable = NO;
        
#ifdef UNIT_TEST
        
        self.uploadSessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        self.downloadSessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        self.networkSessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        self.networkSessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
#else
        //Network Upload queue for NSURLSession (iOS 7)
        NSURLSessionConfiguration *uploadConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:k_session_name];
        uploadConfiguration.HTTPShouldUsePipelining = YES;
        uploadConfiguration.HTTPMaximumConnectionsPerHost = 1;
        uploadConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        self.uploadSessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:uploadConfiguration];
        [self.uploadSessionManager.operationQueue setMaxConcurrentOperationCount:1];
        
        //Network Download queue for NSURLSession (iOS 7)
        NSURLSessionConfiguration *downConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:k_download_session_name];
        downConfiguration.HTTPShouldUsePipelining = YES;
        downConfiguration.HTTPMaximumConnectionsPerHost = 1;
        downConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        self.downloadSessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:downConfiguration];
        [self.downloadSessionManager.operationQueue setMaxConcurrentOperationCount:1];
        
        //Network Download queue for NSURLSession (iOS 7)
        NSURLSessionConfiguration *networkConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        networkConfiguration.HTTPShouldUsePipelining = YES;
        networkConfiguration.HTTPMaximumConnectionsPerHost = 1;
        networkConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        self.networkSessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:networkConfiguration];
        [self.networkSessionManager.operationQueue setMaxConcurrentOperationCount:1];
        self.networkSessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
#endif
        
    }
    
    return self;
}

-(id) initWithUploadSessionManager:(AFURLSessionManager *) uploadSessionManager {

    self = [super init];
    
    if (self) {
        
        //Init the Donwload queue array
        self.downloadTaskNetworkQueueArray = [NSMutableArray new];
        
        self.isCookiesAvailable = YES;
        self.isForbiddenCharactersAvailable = NO;
        
        //Credentials not set yet
        self.kindOfCredential = credentialNotSet;
        
        [self setSecurityPolicyManagers:[self createSecurityPolicy]];
        
        self.uploadSessionManager = uploadSessionManager;
    }
    
    return self;
}

-(id) initWithUploadSessionManager:(AFURLSessionManager *) uploadSessionManager andDownloadSessionManager:(AFURLSessionManager *) downloadSessionManager andNetworkSessionManager:(AFURLSessionManager *) networkSessionManager {
    
    self = [super init];
    
    if (self) {
    
        //Init the Donwload queue array
        self.downloadTaskNetworkQueueArray = [NSMutableArray new];
        
        //Credentials not set yet
        self.kindOfCredential = credentialNotSet;
        
        [self setSecurityPolicyManagers:[self createSecurityPolicy]];
        
        self.uploadSessionManager = uploadSessionManager;
        self.downloadSessionManager = downloadSessionManager;
        self.networkSessionManager = networkSessionManager;
    }
    
    return self;
}

- (AFSecurityPolicy *) createSecurityPolicy {
    return [AFSecurityPolicy defaultPolicy];
}

- (void)setSecurityPolicyManagers:(AFSecurityPolicy *)securityPolicy {
    self.securityPolicy = securityPolicy;
    self.uploadSessionManager.securityPolicy = securityPolicy;
    self.downloadSessionManager.securityPolicy = securityPolicy;
}

#pragma mark - Setting Credentials


- (void) setCredentials:(OCCredentialsDto *) credentials {

    switch (credentials.authenticationMethod) {
        case AuthenticationMethodSAML_WEB_SSO:
            
            [self setCredentialsWithCookie:credentials.accessToken];
            break;
            
        case AuthenticationMethodBEARER_TOKEN:
            
            [self setCredentialsOauthWithToken:credentials.accessToken refreshToken:credentials.refreshToken expiresIn:credentials.expiresIn];
            break;
            
        default:
            [self setCredentialsWithUser:credentials.userName andPassword:credentials.accessToken];
            break;
    }
}

- (void) setCredentialsWithUser:(NSString*) user andPassword:(NSString*) password  {
    self.kindOfCredential = credentialNormal;
    self.user = user;
    self.password = password;
}

- (void) setCredentialsWithCookie:(NSString*) cookie {
    self.kindOfCredential = credentialCookie;
    self.password = cookie;
}

- (void) setCredentialsOauthWithToken:(NSString*)token  refreshToken:(NSString *)refreshToken expiresIn:(NSString *)expiresIn {
    self.kindOfCredential = credentialOauth;
    self.password = token;
}

- (void) setValueOfUserAgent:(NSString *) userAgent {
    self.userAgent = userAgent;
}

///-----------------------------------
/// @name getRequestWithCredentials
///-----------------------------------

/**
 * Method to return the request with the right credential
 *
 * @param OCWebDAVClient like a dinamic typed
 *
 * @return OCWebDAVClient like a dinamic typed
 *
 */
- (id) getRequestWithCredentials:(id) request {
    
    if ([request isKindOfClass:[NSMutableURLRequest class]]) {
        NSMutableURLRequest *myRequest = (NSMutableURLRequest *)request;
        
        switch (self.kindOfCredential) {
            case credentialNotSet:
                //Without credentials
                break;
            case credentialNormal:
            {
                NSString *basicAuthCredentials = [NSString stringWithFormat:@"%@:%@", self.user, self.password];
                [myRequest addValue:[NSString stringWithFormat:@"Basic %@", [UtilsFramework AFBase64EncodedStringFromString:basicAuthCredentials]] forHTTPHeaderField:@"Authorization"];
                break;
            }
            case credentialCookie:
                //NSLog(@"Cookie: %@", self.password);
                [myRequest addValue:self.password forHTTPHeaderField:@"Cookie"];
                break;
            case credentialOauth:
                [myRequest addValue:[NSString stringWithFormat:@"Bearer %@", self.password] forHTTPHeaderField:@"Authorization"];
                break;
            default:
                break;
        }
        
        if (self.userAgent) {
            [myRequest addValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
        }
        
        return myRequest;
        
    } else if([request isKindOfClass:[OCWebDAVClient class]]) {
        OCWebDAVClient *myRequest = (OCWebDAVClient *)request;
        
        switch (self.kindOfCredential) {
            case credentialNotSet:
                //Without credentials
                break;
            case credentialNormal:
                [myRequest setAuthorizationHeaderWithUsername:self.user password:self.password];
                break;
            case credentialCookie:
                [myRequest setAuthorizationHeaderWithCookie:self.password];
                break;
            case credentialOauth:
                [myRequest setAuthorizationHeaderWithToken:[NSString stringWithFormat:@"Bearer %@", self.password]];
                break;
            default:
                break;
        }
        
        if (self.userAgent) {
           [myRequest setUserAgent:self.userAgent];
        }
    
        return request;
        
    } else {
        NSLog(@"We do not know witch kind of object is");
        return  request;
    }
}


#pragma mark - WebDav network Operations

///-----------------------------------
/// @name Check Server
///-----------------------------------
- (void) checkServer: (NSString *) path
      onCommunication:(OCCommunication *)sharedOCCommunication
       successRequest:(void(^)(NSHTTPURLResponse *response, NSString *redirectedServer)) successRequest
       failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest {

    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    
    if (self.userAgent) {
        [request setUserAgent:self.userAgent];
    }
    
    path = [path encodeString:NSUTF8StringEncoding];
    
    [request propertiesOfPath:path onCommunication:sharedOCCommunication success:^(NSHTTPURLResponse *response, id responseObject) {
        if (successRequest) {
            successRequest(response, request.redirectedServer);
        }
    } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        [self returnErrorWithResponse:response andResponseData:responseData andError:error failureRequest:failureRequest andRequest:request];
    }];
}

///-----------------------------------
/// @name Create a folder
///-----------------------------------
- (void) createFolder: (NSString *) path
      onCommunication:(OCCommunication *)sharedOCCommunication withForbiddenCharactersSupported:(BOOL)isFCSupported
       successRequest:(void(^)(NSHTTPURLResponse *response, NSString *redirectedServer)) successRequest
       failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest
   errorBeforeRequest:(void(^)(NSError *error)) errorBeforeRequest {
    
    
    if ([UtilsFramework isForbiddenCharactersInFileName:[UtilsFramework getFileNameOrFolderByPath:path] withForbiddenCharactersSupported:isFCSupported]) {
        NSError *error = [UtilsFramework getErrorByCodeId:OCErrorForbiddenCharacters];
        errorBeforeRequest(error);
    } else {
        OCWebDAVClient *request = [OCWebDAVClient new];
        request = [self getRequestWithCredentials:request];
        
        
        path = [path encodeString:NSUTF8StringEncoding];
        
        [request makeCollection:path onCommunication:sharedOCCommunication
                        success:^(NSHTTPURLResponse *response, id responseObject) {
                            if (successRequest) {
                                successRequest(response, request.redirectedServer);
                            }
                        } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
                            [self returnErrorWithResponse:response andResponseData:responseData andError:error failureRequest:failureRequest andRequest:request];
                        }];
    }
}

///-----------------------------------
/// @name Move a file or a folder
///-----------------------------------
- (void) moveFileOrFolder:(NSString *)sourcePath
                toDestiny:(NSString *)destinyPath
          onCommunication:(OCCommunication *)sharedOCCommunication withForbiddenCharactersSupported:(BOOL)isFCSupported
           successRequest:(void (^)(NSHTTPURLResponse *response, NSString *redirectServer))successRequest
           failureRequest:(void (^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer))failureRequest
       errorBeforeRequest:(void (^)(NSError *error))errorBeforeRequest {
    
    if ([UtilsFramework isTheSameFileOrFolderByNewURLString:destinyPath andOriginURLString:sourcePath]) {
        //We check that we are not trying to move the file to the same place
        NSError *error = [UtilsFramework getErrorByCodeId:OCErrorMovingTheDestinyAndOriginAreTheSame];
        errorBeforeRequest(error);
    } else if ([UtilsFramework isAFolderUnderItByNewURLString:destinyPath andOriginURLString:sourcePath]) {
        //We check we are not trying to move a folder inside himself
        NSError *error = [UtilsFramework getErrorByCodeId:OCErrorMovingFolderInsideItself];
        errorBeforeRequest(error);
    } else if ([UtilsFramework isForbiddenCharactersInFileName:[UtilsFramework getFileNameOrFolderByPath:destinyPath] withForbiddenCharactersSupported:isFCSupported]) {
        //We check that we are making a move not a rename to prevent special characters problems
        NSError *error = [UtilsFramework getErrorByCodeId:OCErrorMovingDestinyNameHaveForbiddenCharacters];
        errorBeforeRequest(error);
    } else {
        
        sourcePath = [sourcePath encodeString:NSUTF8StringEncoding];
        destinyPath = [destinyPath encodeString:NSUTF8StringEncoding];
        
        OCWebDAVClient *request = [OCWebDAVClient new];
        request = [self getRequestWithCredentials:request];
        
        
        [request movePath:sourcePath toPath:destinyPath onCommunication:sharedOCCommunication success:^(NSHTTPURLResponse *response, id responseObject) {
            if (successRequest) {
                successRequest(response, request.redirectedServer);
            }
        } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
            [self returnErrorWithResponse:response andResponseData:responseData andError:error failureRequest:failureRequest andRequest:request];
        }];
    }
}

///-----------------------------------
/// @name Delete a file or a folder
///-----------------------------------
- (void) deleteFileOrFolder:(NSString *)path
            onCommunication:(OCCommunication *)sharedOCCommunication
             successRequest:(void (^)(NSHTTPURLResponse *response, NSString *redirectedServer))successRequest
              failureRquest:(void (^)(NSHTTPURLResponse *resposne, NSError *error, NSString *redirectedServer))failureRequest {
    
    path = [path encodeString:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    
    
    [request deletePath:path onCommunication:sharedOCCommunication success:^(NSHTTPURLResponse *response, id responseObject) {
        if (successRequest) {
            successRequest(response, request.redirectedServer);
        }
    } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        [self returnErrorWithResponse:response andResponseData:responseData andError:error failureRequest:failureRequest andRequest:request];
    }];
}


///-----------------------------------
/// @name Read folder
///-----------------------------------
- (void) readFolder: (NSString *) path withUserSessionToken:(NSString *)token
    onCommunication:(OCCommunication *)sharedOCCommunication
     successRequest:(void(^)(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer, NSString *token)) successRequest
     failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *token, NSString *redirectedServer)) failureRequest{
    
    if (!token){
        token = @"no token";
    }
    
    path = [path encodeString:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    
    
    [request listPath:path onCommunication:sharedOCCommunication withUserSessionToken:token success:^(NSHTTPURLResponse *response, id responseObject, NSString *token) {
        if (successRequest) {
            NSData *responseData = (NSData*) responseObject;
            
//            NSString* newStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
//            NSLog(@"newStrReadFolder: %@", newStr);
            
            OCXMLParser *parser = [[OCXMLParser alloc]init];
            [parser initParserWithData:responseData];
            NSMutableArray *directoryList = [parser.directoryList mutableCopy];
            
            //Return success
            successRequest(response, directoryList, request.redirectedServer, token);
        }
        
    } failure:^(NSHTTPURLResponse *response, id responseData, NSError *error, NSString *token) {
        
        OCXMLServerErrorsParser *serverErrorParser = [OCXMLServerErrorsParser new];
        
        [serverErrorParser startToParseWithData:responseData withCompleteBlock:^(NSError *err) {
            
            if (err) {
                failureRequest(response, err,token, request.redirectedServer);
            }else{
                failureRequest(response, error, token, request.redirectedServer);
            }
            
        }];
    }];
}

///-----------------------------------
/// @name Download File Session
///-----------------------------------



- (NSURLSessionDownloadTask *) downloadFileSession:(NSString *)remotePath toDestiny:(NSString *)localPath defaultPriority:(BOOL)defaultPriority onCommunication:(OCCommunication *)sharedOCCommunication progress:(void(^)(NSProgress *progress))downloadProgress successRequest:(void(^)(NSURLResponse *response, NSURL *filePath)) successRequest failureRequest:(void(^)(NSURLResponse *response, NSError *error)) failureRequest {
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    remotePath = [remotePath encodeString:NSUTF8StringEncoding];
    
    NSURLSessionDownloadTask *downloadTask = [request downloadWithSessionPath:remotePath toPath:localPath defaultPriority:defaultPriority onCommunication:sharedOCCommunication progress:^(NSProgress *progress) {
        downloadProgress(progress);
    } success:^(NSURLResponse *response, NSURL *filePath) {
        
        [UtilsFramework addCookiesToStorageFromResponse:(NSURLResponse *) response andPath:[NSURL URLWithString:remotePath]];
        successRequest(response,filePath);
        
    } failure:^(NSURLResponse *response, NSError *error) {
        [UtilsFramework addCookiesToStorageFromResponse:(NSURLResponse *) response andPath:[NSURL URLWithString:remotePath]];
        failureRequest(response,error);
    }];
    
    return downloadTask;
}


///-----------------------------------
/// @name Set Download Task Complete Block
///-----------------------------------


- (void)setDownloadTaskComleteBlock: (NSURL * (^)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location))block{
    
    [self.downloadSessionManager setDownloadTaskDidFinishDownloadingBlock:block];

    
}


///-----------------------------------
/// @name Set Download Task Did Get Body Data Block
///-----------------------------------


- (void) setDownloadTaskDidGetBodyDataBlock: (void(^)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite)) block{
    
    [self.downloadSessionManager setDownloadTaskDidWriteDataBlock:^(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        block(session,downloadTask,bytesWritten,totalBytesWritten,totalBytesExpectedToWrite);
    }];
    
}

///-----------------------------------
/// @name Upload File Session
///-----------------------------------

- (NSURLSessionUploadTask *) uploadFileSession:(NSString *) localPath toDestiny:(NSString *) remotePath onCommunication:(OCCommunication *)sharedOCCommunication progress:(void(^)(NSProgress *progress))uploadProgress successRequest:(void(^)(NSURLResponse *response, NSString *redirectedServer)) successRequest failureRequest:(void(^)(NSURLResponse *response, NSString *redirectedServer, NSError *error)) failureRequest failureBeforeRequest:(void(^)(NSError *error)) failureBeforeRequest {
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    
    
    remotePath = [remotePath encodeString:NSUTF8StringEncoding];
    
    NSURLSessionUploadTask *uploadTask = [request putWithSessionLocalPath:localPath atRemotePath:remotePath onCommunication:sharedOCCommunication progress:^(NSProgress *progress) {
            uploadProgress(progress);
        } success:^(NSURLResponse *response, id responseObjec){
            [UtilsFramework addCookiesToStorageFromResponse:(NSURLResponse *) response andPath:[NSURL URLWithString:remotePath]];
            //TODO: The second parameter is the redirected server
            successRequest(response, @"");
        } failure:^(NSURLResponse *response, id responseObject, NSError *error) {
            [UtilsFramework addCookiesToStorageFromResponse:(NSURLResponse *) response andPath:[NSURL URLWithString:remotePath]];
            //TODO: The second parameter is the redirected server

            NSData *responseData = (NSData*) responseObject;
            
            OCXMLServerErrorsParser *serverErrorParser = [OCXMLServerErrorsParser new];
            
            [serverErrorParser startToParseWithData:responseData withCompleteBlock:^(NSError *err) {
                
                if (err) {
                    failureRequest(response, @"", err);
                }else{
                    failureRequest(response, @"", error);
                }
                
            }];
            
        } failureBeforeRequest:^(NSError *error) {
            failureBeforeRequest(error);
        }];
    
    return uploadTask;
}

///-----------------------------------
/// @name Set Task Did Complete Block
///-----------------------------------

- (void) setTaskDidCompleteBlock: (void(^)(NSURLSession *session, NSURLSessionTask *task, NSError *error)) block{
    
    [self.uploadSessionManager setTaskDidCompleteBlock:^(NSURLSession *session, NSURLSessionTask *task, NSError *error) {

        block(session, task, error);
    }];
    
}


///-----------------------------------
/// @name Set Task Did Send Body Data Block
///-----------------------------------


- (void) setTaskDidSendBodyDataBlock: (void(^)(NSURLSession *session, NSURLSessionTask *task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend)) block{
    
   [self.uploadSessionManager setTaskDidSendBodyDataBlock:^(NSURLSession *session, NSURLSessionTask *task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
       block(session, task, bytesSent, totalBytesSent, totalBytesExpectedToSend);
   }];
}


///-----------------------------------
/// @name Read File
///-----------------------------------
- (void) readFile: (NSString *) path
  onCommunication:(OCCommunication *)sharedOCCommunication
   successRequest:(void(^)(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer)) successRequest
   failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest {
    
    path = [path encodeString:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    
    
    [request propertiesOfPath:path onCommunication:sharedOCCommunication success:^(NSHTTPURLResponse *response, id responseObject) {
        
        if (successRequest) {
            NSData *responseData = (NSData*) responseObject;
            
//            NSString* newStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
//            NSLog(@"newStrReadFile: %@", newStr);

            OCXMLParser *parser = [[OCXMLParser alloc]init];
            [parser initParserWithData:responseData];
            NSMutableArray *directoryList = [parser.directoryList mutableCopy];
            
            //Return success
            successRequest(response, directoryList, request.redirectedServer);
        }
        
    } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        [self returnErrorWithResponse:response andResponseData:responseData andError:error failureRequest:failureRequest andRequest:request];
    }];
    
}

#pragma mark - OC API Calls

- (NSString *) getCurrentServerVersion {
    return self.currentServerVersion;
}

- (void) getServerVersionWithPath:(NSString*) path onCommunication:(OCCommunication *)sharedOCCommunication
                   successRequest:(void(^)(NSHTTPURLResponse *response, NSString *serverVersion, NSString *redirectedServer)) success
                   failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest {
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    
    if (self.userAgent) {
        [request setUserAgent:self.userAgent];
    }
    
    [request getStatusOfTheServer:path onCommunication:sharedOCCommunication success:^(NSHTTPURLResponse *response, id responseObject) {
        
        NSData *data = (NSData*) responseObject;
        NSString *versionString = [NSString new];
        NSError* error=nil;
        
        if (data) {
            NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &error];
            if(error) {
                NSLog(@"Error parsing JSON: %@", error);
            } else {
                //Obtain the server version from the version field
                versionString = [jsonArray valueForKey:@"version"];
                self.currentServerVersion = versionString;
            }
        } else {
            NSLog(@"Error parsing JSON: data is null");
        }
        success(response, versionString, request.redirectedServer);
        
    } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        [self returnErrorWithResponse:response andResponseData:responseData andError:error failureRequest:failureRequest andRequest:request];
    }];
    
}

///-----------------------------------
/// @name Get UserName by cookie
///-----------------------------------

- (void) getUserNameByCookie:(NSString *) cookieString ofServerPath:(NSString *)path onCommunication:
(OCCommunication *)sharedOCCommunication success:(void(^)(NSHTTPURLResponse *response, NSData *responseData, NSString *redirectedServer))success
                     failure:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer))failureRequest {
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    
    
    [request requestUserNameOfServer: path byCookie:cookieString onCommunication:sharedOCCommunication success:^(NSHTTPURLResponse *response, id responseObject) {
        success(response, responseObject, request.redirectedServer);
    } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        [self returnErrorWithResponse:response andResponseData:responseData andError:error failureRequest:failureRequest andRequest:request];
    }];
}

- (void) getFeaturesSupportedByServer:(NSString*) path onCommunication:(OCCommunication *)sharedOCCommunication
                     successRequest:(void(^)(NSHTTPURLResponse *response, BOOL hasShareSupport, BOOL hasShareeSupport, BOOL hasCookiesSupport, BOOL hasForbiddenCharactersSupport, BOOL hasCapabilitiesSupport, BOOL hasFedSharesOptionShareSupport, NSString *redirectedServer)) success
                     failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest {
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    
    if (self.userAgent) {
        [request setUserAgent:self.userAgent];
    }
    
    [request getStatusOfTheServer:path onCommunication:sharedOCCommunication success:^(NSHTTPURLResponse *response, id responseObject) {
        
        if (responseObject) {
            
            NSError* error = nil;
            NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData: (NSData*) responseObject options: NSJSONReadingMutableContainers error: &error];
            
            if(error) {
                // NSLog(@"Error parsing JSON: %@", error);
                failureRequest(response, error, request.redirectedServer);
            }else{
                
                self.currentServerVersion = [jsonArray valueForKey:@"version"];
                
                BOOL hasShareSupport = [UtilsFramework isServerVersion:self.currentServerVersion higherThanLimitVersion:k_version_support_shared];
                BOOL hasShareeSupport = [UtilsFramework isServerVersion:self.currentServerVersion higherThanLimitVersion:k_version_support_sharee_api];
                BOOL hasCookiesSupport = [UtilsFramework isServerVersion:self.currentServerVersion higherThanLimitVersion:k_version_support_cookies];
                BOOL hasForbiddenCharactersSupport = [UtilsFramework isServerVersion:self.currentServerVersion higherThanLimitVersion:k_version_support_forbidden_characters];
                BOOL hasCapabilitiesSupport = [UtilsFramework isServerVersion:self.currentServerVersion higherThanLimitVersion:k_version_support_capabilities];
                BOOL hasFedSharesOptionShareSupport = [UtilsFramework isServerVersion:self.currentServerVersion higherThanLimitVersion:k_version_support_share_option_fed_share];

                success(response, hasShareSupport, hasShareeSupport, hasCookiesSupport, hasForbiddenCharactersSupport, hasCapabilitiesSupport, hasFedSharesOptionShareSupport, request.redirectedServer);
            }
            
        } else {
            // NSLog(@"Error parsing JSON: data is null");
            failureRequest(response, nil, request.redirectedServer);
        }
        
        
    } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        [self returnErrorWithResponse:response andResponseData:responseData andError:error failureRequest:failureRequest andRequest:request];
    }];

}

- (OCServerFeatures *) getFeaturesSupportedByServerForVersion:(NSString *)version {
    
    BOOL hasShareSupport = [UtilsFramework isServerVersion:version higherThanLimitVersion:k_version_support_shared];
    BOOL hasShareeSupport = [UtilsFramework isServerVersion:version higherThanLimitVersion:k_version_support_sharee_api];
    BOOL hasCookiesSupport = [UtilsFramework isServerVersion:version higherThanLimitVersion:k_version_support_cookies];
    BOOL hasForbiddenCharactersSupport = [UtilsFramework isServerVersion:version higherThanLimitVersion:k_version_support_forbidden_characters];
    BOOL hasCapabilitiesSupport = [UtilsFramework isServerVersion:version higherThanLimitVersion:k_version_support_capabilities];
    BOOL hasFedSharesOptionShareSupport = [UtilsFramework isServerVersion:version higherThanLimitVersion:k_version_support_share_option_fed_share];
    BOOL hasPublicShareLinkOptionNameSupport = [UtilsFramework isServerVersion:version higherThanLimitVersion:k_version_support_public_share_link_option_name];
    BOOL hasPublicShareLinkOptionUploadOnlySupport = [UtilsFramework isServerVersion:version higherThanLimitVersion:k_version_support_public_share_link_option_upload_only];
    
    OCServerFeatures *supportedFeatures = [[OCServerFeatures alloc] initWithSupportForShare:hasShareSupport sharee:hasShareeSupport cookies:hasCookiesSupport forbiddenCharacters:hasForbiddenCharactersSupport capabilities:hasCapabilitiesSupport fedSharesOptionShare:hasFedSharesOptionShareSupport publicShareLinkOptionName:hasPublicShareLinkOptionNameSupport publicShareLinkOptionUploadOnlySupport:hasPublicShareLinkOptionUploadOnlySupport];
    
    return supportedFeatures;
}

- (void) readSharedByServer: (NSString *) path
            onCommunication:(OCCommunication *)sharedOCCommunication
             successRequest:(void(^)(NSHTTPURLResponse *response, NSArray *listOfShared, NSString *redirectedServer)) successRequest
             failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest {
    
    path = [path encodeString:NSUTF8StringEncoding];
    path = [path stringByAppendingString:k_url_acces_shared_api];
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    
    
    [request listSharedByServer:path onCommunication:sharedOCCommunication success:^(NSHTTPURLResponse *response, id responseObject) {
        if (successRequest) {
            NSData *responseData = (NSData*) responseObject;
            OCXMLSharedParser *parser = [[OCXMLSharedParser alloc]init];
            
          //NSLog(@"response: %@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
            
            [parser initParserWithData:responseData];
            NSMutableArray *sharedList = [parser.shareList mutableCopy];
            
            //Return success
            successRequest(response, sharedList, request.redirectedServer);
        }
        
    } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        [self returnErrorWithResponse:response andResponseData:responseData andError:error failureRequest:failureRequest andRequest:request];
    }];
}

- (void) readSharedByServer: (NSString *) serverPath andPath: (NSString *) path
            onCommunication:(OCCommunication *)sharedOCCommunication
             successRequest:(void(^)(NSHTTPURLResponse *response, NSArray *listOfShared, NSString *redirectedServer)) successRequest
             failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest {
    
   serverPath = [serverPath encodeString:NSUTF8StringEncoding];
   serverPath = [serverPath stringByAppendingString:k_url_acces_shared_api];
    
   path = [path encodeString:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    
    
    [request listSharedByServer:serverPath andPath:path onCommunication:sharedOCCommunication success:^(NSHTTPURLResponse *response, id responseObject) {
        if (successRequest) {
            NSData *responseData = (NSData*) responseObject;
            OCXMLSharedParser *parser = [[OCXMLSharedParser alloc]init];
            
//            NSString *str = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
//            NSLog(@"responseDataReadSharedByServer:andPath: %@", str);
//            NSLog(@"pathFolders: %@", path);
//            NSLog(@"serverPath: %@", serverPath);
            
            [parser initParserWithData:responseData];
            NSMutableArray *sharedList = [parser.shareList mutableCopy];
            
            //Return success
            successRequest(response, sharedList, request.redirectedServer);
        }
    } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        [self returnErrorWithResponse:response andResponseData:responseData andError:error failureRequest:failureRequest andRequest:request];
    }];
}

- (void) shareFileOrFolderByServerPath:(NSString *)serverPath
                  withFileOrFolderPath:(NSString *)filePath
                              password:(NSString *)password
                        expirationTime:(NSString *)expirationTime
                          publicUpload:(NSString *)publicUpload
                              linkName:(NSString *)linkName
                           permissions:(NSInteger)permissions
                       onCommunication:(OCCommunication *)sharedOCCommunication
                        successRequest:(void(^)(NSHTTPURLResponse *response, NSString *token, NSString *redirectedServer)) successRequest
                        failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest {
    
    serverPath = [serverPath encodeString:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_acces_shared_api];
    linkName = [linkName encodeString:NSUTF8StringEncoding];
    password = [password encodeString:NSUTF8StringEncoding];

    
    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    
    
    [request shareByLinkFileOrFolderByServer:serverPath andPath:filePath
                                    password:password
                              expirationTime:expirationTime
                                publicUpload:publicUpload
                                    linkName:linkName
                                 permissions:permissions
                             onCommunication:sharedOCCommunication success:^(NSHTTPURLResponse *response, id responseObject) {
        NSData *responseData = (NSData*) responseObject;
        
        OCXMLShareByLinkParser *parser = [[OCXMLShareByLinkParser alloc]init];
        
        //  NSLog(@"response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
        
        [parser initParserWithData:responseData];
        
        switch (parser.statusCode) {
            case kOCSharedAPISuccessful:
            {
                NSString *url = parser.url;
                NSString *token = parser.token;
                
                if (url != nil) {
                    
                    successRequest(response, url, request.redirectedServer);
                    
                }else if (token != nil){
                    //We remove the \n and the empty spaces " "
                    token = [token stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
                    
                    successRequest(response, token, request.redirectedServer);
                    
                }else{
                    
                    NSError *error = [UtilsFramework getErrorWithCode:parser.statusCode andCustomMessageFromTheServer:parser.message];
                    failureRequest(response, error, request.redirectedServer);
                }
                
                break;
            }
                
            default:
            {
                NSError *error = [UtilsFramework getErrorWithCode:parser.statusCode andCustomMessageFromTheServer:parser.message];
                failureRequest(response, error, request.redirectedServer);
            }
        }
        
    } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        failureRequest(response, error, request.redirectedServer);
    }];
    
}


- (void) shareFileOrFolderByServer: (NSString *) serverPath andFileOrFolderPath: (NSString *) filePath andPassword:(NSString *)password
                   onCommunication:(OCCommunication *)sharedOCCommunication
                    successRequest:(void(^)(NSHTTPURLResponse *response, NSString *token, NSString *redirectedServer)) successRequest
                    failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest {
    
    serverPath = [serverPath encodeString:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_acces_shared_api];
    password = [password encodeString:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    
    
    [request shareByLinkFileOrFolderByServer:serverPath andPath:filePath andPassword:password onCommunication:sharedOCCommunication success:^(NSHTTPURLResponse *response, id responseObject) {
        
        NSData *responseData = (NSData*) responseObject;
        
        OCXMLShareByLinkParser *parser = [[OCXMLShareByLinkParser alloc]init];
        
      //  NSLog(@"response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
        
        [parser initParserWithData:responseData];
        
        switch (parser.statusCode) {
            case kOCSharedAPISuccessful:
            {
                NSString *url = parser.url;
                NSString *token = parser.token;
                
                if (url != nil) {
                    
                    successRequest(response, url, request.redirectedServer);
                    
                }else if (token != nil){
                    //We remove the \n and the empty spaces " "
                    token = [token stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
                    
                    successRequest(response, token, request.redirectedServer);
                    
                }else{
                    
                    NSError *error = [UtilsFramework getErrorWithCode:parser.statusCode andCustomMessageFromTheServer:parser.message];
                    failureRequest(response, error, request.redirectedServer);
                }
                
                break;
            }
                
            default:
            {
                NSError *error = [UtilsFramework getErrorWithCode:parser.statusCode andCustomMessageFromTheServer:parser.message];
                failureRequest(response, error, request.redirectedServer);
            }
        }
        
    } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        [self returnErrorWithResponse:response andResponseData:responseData andError:error failureRequest:failureRequest andRequest:request];
    }];
}


- (void) shareFileOrFolderByServer: (NSString *) serverPath andFileOrFolderPath: (NSString *) filePath
                   onCommunication:(OCCommunication *)sharedOCCommunication
                    successRequest:(void(^)(NSHTTPURLResponse *response, NSString *shareLink, NSInteger remoteShareId, NSString *redirectedServer)) successRequest
                    failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest {
    
    serverPath = [serverPath encodeString:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_acces_shared_api];
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    
    
    [request shareByLinkFileOrFolderByServer:serverPath andPath:filePath onCommunication:sharedOCCommunication success:^(NSHTTPURLResponse *response, id responseObject) {
        
        NSData *responseData = (NSData*) responseObject;
        
        OCXMLShareByLinkParser *parser = [[OCXMLShareByLinkParser alloc]init];
        
      //  NSLog(@"response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
        
        [parser initParserWithData:responseData];
        
        switch (parser.statusCode) {
            case kOCSharedAPISuccessful:
            {
                NSString *url = parser.url;
                NSString *token = parser.token;
                NSInteger remoteShareId = parser.remoteShareId;
                
                if (url != nil) {
                    
                    successRequest(response, url, remoteShareId, request.redirectedServer);
                    
                }else if (token != nil){
                    //We remove the \n and the empty spaces " "
                    token = [token stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
                    
                    successRequest(response, token, remoteShareId, request.redirectedServer);
                    
                }else{
                    
                    NSError *error = [UtilsFramework getErrorWithCode:parser.statusCode andCustomMessageFromTheServer:parser.message];
                    failureRequest(response, error, request.redirectedServer);
                }

                break;
            }
                
            default:
            {
                NSError *error = [UtilsFramework getErrorWithCode:parser.statusCode andCustomMessageFromTheServer:parser.message];
                failureRequest(response, error, request.redirectedServer);
            }
        }

    } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        [self returnErrorWithResponse:response andResponseData:responseData andError:error failureRequest:failureRequest andRequest:request];
    }];
}

- (void)shareWith:(NSString *)userOrGroup shareeType:(NSInteger)shareeType inServer:(NSString *) serverPath andFileOrFolderPath:(NSString *) filePath andPermissions:(NSInteger) permissions onCommunication:(OCCommunication *)sharedOCCommunication
          successRequest:(void(^)(NSHTTPURLResponse *response, NSString *redirectedServer))successRequest
          failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer))failureRequest{
    
    serverPath = [serverPath encodeString:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_acces_shared_api];
    userOrGroup = [userOrGroup encodeString:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    
    
    [request shareWith:userOrGroup shareeType:shareeType inServer:serverPath andPath:filePath andPermissions:permissions onCommunication:sharedOCCommunication success:^(NSHTTPURLResponse *response, id responseObject) {
        NSData *responseData = (NSData*) responseObject;
        
        OCXMLShareByLinkParser *parser = [[OCXMLShareByLinkParser alloc]init];
        
        //  NSLog(@"response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
        
        [parser initParserWithData:responseData];
        
        switch (parser.statusCode) {
            case kOCSharedAPISuccessful:
            {
                successRequest(response, request.redirectedServer);
                break;
            }
                
            default:
            {
                NSError *error = [UtilsFramework getErrorWithCode:parser.statusCode andCustomMessageFromTheServer:parser.message];
                failureRequest(response, error, request.redirectedServer);
            }
        }
        
        
    } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        [self returnErrorWithResponse:response andResponseData:responseData andError:error failureRequest:failureRequest andRequest:request];
    }];
    
}

- (void) unShareFileOrFolderByServer: (NSString *) path andIdRemoteShared: (NSInteger) idRemoteShared
                     onCommunication:(OCCommunication *)sharedOCCommunication
                      successRequest:(void(^)(NSHTTPURLResponse *response, NSString *redirectedServer)) successRequest
                      failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest{
    
    path = [path encodeString:NSUTF8StringEncoding];
    path = [path stringByAppendingString:k_url_acces_shared_api];
    path = [path stringByAppendingString:[NSString stringWithFormat:@"/%ld",(long)idRemoteShared]];
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    
    
    [request unShareFileOrFolderByServer:path onCommunication:sharedOCCommunication success:^(NSHTTPURLResponse *response, id responseObject) {
        if (successRequest) {
            //Return success
            successRequest(response, request.redirectedServer);
        }
        
    } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        [self returnErrorWithResponse:response andResponseData:responseData andError:error failureRequest:failureRequest andRequest:request];
    }];
}

- (void) isShareFileOrFolderByServer: (NSString *) path andIdRemoteShared: (NSInteger) idRemoteShared
                     onCommunication:(OCCommunication *)sharedOCCommunication
                      successRequest:(void(^)(NSHTTPURLResponse *response, NSString *redirectedServer, BOOL isShared, id shareDto)) successRequest
                      failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest {
    
    path = [path encodeString:NSUTF8StringEncoding];
    path = [path stringByAppendingString:k_url_acces_shared_api];
    path = [path stringByAppendingString:[NSString stringWithFormat:@"/%ld",(long)idRemoteShared]];
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    

    [request isShareFileOrFolderByServer:path onCommunication:sharedOCCommunication success:^(NSHTTPURLResponse *response, id responseObject) {
        if (successRequest) {
        
            NSData *responseData = (NSData*) responseObject;
            OCXMLSharedParser *parser = [[OCXMLSharedParser alloc]init];
            
            // NSLog(@"response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
            
            [parser initParserWithData:responseData];
            
             BOOL isShared = NO;
            
             OCSharedDto *shareDto = nil;
            
            if (parser.shareList) {
                
                NSMutableArray *sharedList = [parser.shareList mutableCopy];
                
                if ([sharedList count] > 0) {
                    isShared = YES;
                    shareDto = [sharedList objectAtIndex:0];
                }
            }
     
            //Return success
            successRequest(response, request.redirectedServer, isShared, shareDto);
        }
        
    } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        [self returnErrorWithResponse:response andResponseData:responseData andError:error failureRequest:failureRequest andRequest:request];
    }];
}

- (void) updateShare:(NSInteger)shareId
        ofServerPath:(NSString *)serverPath
 withPasswordProtect:(NSString*)password
   andExpirationTime:(NSString*)expirationTime
     andPublicUpload:(NSString *)publicUpload
         andLinkName:(NSString *)linkName
      andPermissions:(NSInteger)permissions
     onCommunication:(OCCommunication *)sharedOCCommunication
      successRequest:(void(^)(NSHTTPURLResponse *response, NSData *responseData, NSString *redirectedServer)) successRequest
      failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest {

    serverPath = [serverPath encodeString:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_acces_shared_api];
    serverPath = [serverPath stringByAppendingString:[NSString stringWithFormat:@"/%ld",(long)shareId]];
    linkName = [linkName encodeString:NSUTF8StringEncoding];
    password = [password encodeString:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    
    
    [request updateShareItem:shareId ofServerPath:serverPath withPasswordProtect:password
           andExpirationTime:expirationTime andPublicUpload:publicUpload andLinkName:linkName
              andPermissions:permissions
             onCommunication:sharedOCCommunication
    success:^(NSHTTPURLResponse *response, id responseObject) {
        
        NSData *responseData = (NSData*) responseObject;
        
        OCXMLShareByLinkParser *parser = [[OCXMLShareByLinkParser alloc]init];
        
//        NSLog(@"responseData: %@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        
        [parser initParserWithData:responseData];
        
        switch (parser.statusCode) {
            case kOCSharedAPISuccessful:
            {
                //OCXMLSharedParser *parserSharedDto = [[OCXMLSharedParser alloc] init];
                //[parserSharedDto initParserWithData:[NSKeyedArchiver archivedDataWithRootObject:parser.data]];
                
                //TODO: update parser to get new OCSharedDto and return it instead of NSData responseData

                successRequest(response, responseData, request.redirectedServer);
                break;
            }
                
            default:
            {
                NSError *error = [UtilsFramework getErrorWithCode:parser.statusCode andCustomMessageFromTheServer:parser.message];
                failureRequest(response, error, request.redirectedServer);
            }
        }
        
    } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        failureRequest(response, error, request.redirectedServer);
    }];
    
}

- (void) updateShare:(NSInteger)shareId
        ofServerPath:(NSString *)serverPath
 withPasswordProtect:(NSString*)password
   andExpirationTime:(NSString*)expirationTime
      andPermissions:(NSInteger)permissions
     onCommunication:(OCCommunication *)sharedOCCommunication
      successRequest:(void(^)(NSHTTPURLResponse *response, NSString *redirectedServer)) successRequest
      failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest{
    
    
    serverPath = [serverPath encodeString:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_acces_shared_api];
    serverPath = [serverPath stringByAppendingString:[NSString stringWithFormat:@"/%ld",(long)shareId]];
    password = [password encodeString:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    
    
    [request updateShareItem:shareId ofServerPath:serverPath withPasswordProtect:password
           andExpirationTime:expirationTime andPermissions:permissions
             onCommunication:sharedOCCommunication
    success:^(NSHTTPURLResponse *response, id responseObject) {
        
        NSData *responseData = (NSData*) responseObject;
        
        OCXMLShareByLinkParser *parser = [[OCXMLShareByLinkParser alloc]init];
        
     //   NSLog(@"response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
        
        [parser initParserWithData:responseData];
        
        
        switch (parser.statusCode) {
            case kOCSharedAPISuccessful:
            {
                successRequest(response, request.redirectedServer);
                break;
            }
            
            default:
            {
                NSError *error = [UtilsFramework getErrorWithCode:parser.statusCode andCustomMessageFromTheServer:parser.message];
                failureRequest(response, error, request.redirectedServer);
            }
        }

    } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        [self returnErrorWithResponse:response andResponseData:responseData andError:error failureRequest:failureRequest andRequest:request];
    }];
    
}

- (void) searchUsersAndGroupsWith:(NSString *)searchString forPage:(NSInteger)page with:(NSInteger)resultsPerPage ofServer:(NSString*)serverPath onCommunication:(OCCommunication *)sharedOCComunication successRequest:(void(^)(NSHTTPURLResponse *response, NSArray *itemList, NSString *redirectedServer)) successRequest failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest{
    
    serverPath = [serverPath encodeString:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_access_sharee_api];
    
    searchString = [searchString encodeString:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    
    
    
    [request searchUsersAndGroupsWith:searchString forPage:page with:resultsPerPage ofServer:serverPath onCommunication:sharedOCComunication success:^(NSHTTPURLResponse *response, id responseObject) {
        
        NSData *responseData = (NSData*) responseObject;
        
        NSMutableArray *itemList = [NSMutableArray new];
        
        //Parse
        NSError *error;
        NSDictionary *jsongParsed = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
        
        if (error == nil) {
            
            NSDictionary *ocsDict = [jsongParsed valueForKey:@"ocs"];
            
            NSDictionary *metaDict = [ocsDict valueForKey:@"meta"];
            NSInteger statusCode = [[metaDict valueForKey:@"statuscode"] integerValue];
            
            if (statusCode == kOCShareeAPISuccessful || statusCode == kOCSharedAPISuccessful) {
                
                NSDictionary *dataDict = [ocsDict valueForKey:@"data"];
                NSArray *exactDict = [dataDict valueForKey:@"exact"];
                NSArray *usersFounded = [dataDict valueForKey:@"users"];
                NSArray *groupsFounded = [dataDict valueForKey:@"groups"];
                NSArray *usersRemote = [dataDict valueForKey:@"remotes"];
                NSArray *usersExact = [exactDict valueForKey:@"users"];
                NSArray *groupsExact = [exactDict valueForKey:@"groups"];
                NSArray *remotesExact = [exactDict valueForKey:@"remotes"];
                
                [self addShareeItemOfType:shareTypeUser fromArray:usersFounded ToList:itemList];
                [self addShareeItemOfType:shareTypeUser fromArray:usersExact ToList:itemList];
                [self addShareeItemOfType:shareTypeRemote fromArray:usersRemote ToList:itemList];
                [self addShareeItemOfType:shareTypeRemote fromArray:remotesExact ToList:itemList];
                [self addShareeItemOfType:shareTypeGroup fromArray:groupsFounded ToList:itemList];
                [self addShareeItemOfType:shareTypeGroup fromArray:groupsExact ToList:itemList];
            
            }else{
                
                NSString *message = (NSString*)[metaDict objectForKey:@"message"];
                
                if ([message isKindOfClass:[NSNull class]]) {
                    message = @"";
                }
                
                NSError *error = [UtilsFramework getErrorWithCode:statusCode andCustomMessageFromTheServer:message];
                failureRequest(response, error, request.redirectedServer);
                
            }
            
            //Return success
            successRequest(response, itemList, request.redirectedServer);
            
        }
        
        
    } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        [self returnErrorWithResponse:response andResponseData:responseData andError:error failureRequest:failureRequest andRequest:request];
    }];
}

- (void) getCapabilitiesOfServer:(NSString*)serverPath onCommunication:(OCCommunication *)sharedOCComunication successRequest:(void(^)(NSHTTPURLResponse *response, OCCapabilities *capabilities, NSString *redirectedServer)) successRequest failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest{
    
    serverPath = [serverPath encodeString:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_capabilities];
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    
    
    [request getCapabilitiesOfServer:serverPath onCommunication:sharedOCComunication success:^(NSHTTPURLResponse *response, id responseObject) {
        
        NSData *responseData = (NSData*) responseObject;
        
        //Parse
        NSError *error;
        NSDictionary *jsongParsed = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
        //NSLog(@"dic: %@",jsongParsed);
        
        OCCapabilities *capabilities = [OCCapabilities new];
        
        if (jsongParsed.allKeys > 0) {
            
            NSDictionary *ocs = [jsongParsed valueForKey:@"ocs"];
            NSDictionary *data = [ocs valueForKey:@"data"];
            NSDictionary *version = [data valueForKey:@"version"];
            
            //VERSION
            
            NSNumber *versionMajorNumber = (NSNumber*) [version valueForKey:@"major"];
            NSNumber *versionMinorNumber = (NSNumber*) [version valueForKey:@"minor"];
            NSNumber *versionMicroNumber = (NSNumber*) [version valueForKey:@"micro"];
            
            capabilities.versionMajor = versionMajorNumber.integerValue;
            capabilities.versionMinor = versionMinorNumber.integerValue;
            capabilities.versionMicro = versionMicroNumber.integerValue;
            
            capabilities.versionString = (NSString*)[version valueForKey:@"string"];
            capabilities.versionEdition = (NSString*)[version valueForKey:@"edition"];
            
            NSDictionary *capabilitiesDict = [data valueForKey:@"capabilities"];
            NSDictionary *core = [capabilitiesDict valueForKey:@"core"];
            
            //CORE
            
            NSNumber *corePollIntervalNumber = (NSNumber*)[core valueForKey:@"pollinterval"];
            capabilities.corePollInterval = corePollIntervalNumber.integerValue;
            
            NSDictionary *fileSharing = [capabilitiesDict valueForKey:@"files_sharing"];
            
            //FILE SHARING
            
            NSNumber *fileSharingAPIEnabledNumber = (NSNumber*)[fileSharing valueForKey:@"api_enabled"];
            NSNumber *filesSharingReSharingEnabledNumber = (NSNumber*)[fileSharing valueForKey:@"resharing"];
      
            
            capabilities.isFilesSharingAPIEnabled = fileSharingAPIEnabledNumber.boolValue;
            capabilities.isFilesSharingReSharingEnabled = filesSharingReSharingEnabledNumber.boolValue;
            
            NSDictionary *fileSharingPublic = [fileSharing valueForKey:@"public"];
            
            NSNumber *filesSharingShareLinkEnabledNumber = (NSNumber*)[fileSharingPublic valueForKey:@"enabled"];
            NSNumber *filesSharingAllowPublicUploadsEnabledNumber = (NSNumber*)[fileSharingPublic valueForKey:@"upload"];
            NSNumber *filesSharingSupportsUploadOnlyEnabledNumber = (NSNumber*)[fileSharingPublic valueForKey:@"supports_upload_only"];
            NSNumber *filesSharingAllowUserSendMailNotificationAboutShareLinkEnabledNumber = (NSNumber*)[fileSharingPublic valueForKey:@"send_mail"];
            NSNumber *filesSharingAllowUserCreateMultiplePublicLinksEnabledNumber= (NSNumber*)[fileSharingPublic valueForKey:@"multiple"];
            
            capabilities.isFilesSharingShareLinkEnabled = filesSharingShareLinkEnabledNumber.boolValue;
            capabilities.isFilesSharingAllowPublicUploadsEnabled = filesSharingAllowPublicUploadsEnabledNumber.boolValue;
            capabilities.isFilesSharingSupportsUploadOnlyEnabled = filesSharingSupportsUploadOnlyEnabledNumber.boolValue;
            capabilities.isFilesSharingAllowUserSendMailNotificationAboutShareLinkEnabled = filesSharingAllowUserSendMailNotificationAboutShareLinkEnabledNumber.boolValue;
            capabilities.isFilesSharingAllowUserCreateMultiplePublicLinksEnabled = filesSharingAllowUserCreateMultiplePublicLinksEnabledNumber.boolValue;
            
            NSDictionary *fileSharingPublicExpireDate = [fileSharingPublic valueForKey:@"expire_date"];
            
            NSNumber *filesSharingExpireDateByDefaultEnabledNumber = (NSNumber*)[fileSharingPublicExpireDate valueForKey:@"enabled"];
            NSNumber *filesSharingExpireDateEnforceEnabledNumber = (NSNumber*)[fileSharingPublicExpireDate valueForKey:@"enforced"];
            NSNumber *filesSharingExpireDateDaysNumber = (NSNumber*)[fileSharingPublicExpireDate valueForKey:@"days"];
            
    
            capabilities.isFilesSharingExpireDateByDefaultEnabled = filesSharingExpireDateByDefaultEnabledNumber.boolValue;
            capabilities.isFilesSharingExpireDateEnforceEnabled = filesSharingExpireDateEnforceEnabledNumber.boolValue;
            capabilities.filesSharingExpireDateDaysNumber = filesSharingExpireDateDaysNumber.integerValue;
            
            NSDictionary *fileSharingPublicPassword = [fileSharingPublic valueForKey:@"password"];
            
            NSNumber *filesSharingPasswordEnforcedEnabledNumber = (NSNumber*)[fileSharingPublicPassword valueForKey:@"enforced"];
            
            capabilities.isFilesSharingPasswordEnforcedEnabled = filesSharingPasswordEnforcedEnabledNumber.boolValue;;
            
            NSDictionary *fileSharingUser = [fileSharing valueForKey:@"user"];
            
            NSNumber *filesSharingAllowUserSendMailNotificationAboutOtherUsersEnabledNumber = (NSNumber*)[fileSharingUser valueForKey:@"send_mail"];
            
            capabilities.isFilesSharingAllowUserSendMailNotificationAboutOtherUsersEnabled = filesSharingAllowUserSendMailNotificationAboutOtherUsersEnabledNumber.boolValue;
            
            
            //FEDERATION
            
            NSDictionary *fileSharingFederation = [fileSharing valueForKey:@"federation"];
            
            NSNumber *filesSharingAllowUserSendSharesToOtherServersEnabledNumber = (NSNumber*)[fileSharingFederation valueForKey:@"outgoing"];
            NSNumber *filesSharingAllowUserReceiveSharesToOtherServersEnabledNumber = (NSNumber*)[fileSharingFederation valueForKey:@"incoming"];
            
            capabilities.isFilesSharingAllowUserSendSharesToOtherServersEnabled = filesSharingAllowUserSendSharesToOtherServersEnabledNumber.boolValue;
            capabilities.isFilesSharingAllowUserReceiveSharesToOtherServersEnabled = filesSharingAllowUserReceiveSharesToOtherServersEnabledNumber.boolValue;
            
            //FILES
            
            NSDictionary *files = [capabilitiesDict valueForKey:@"files"];
            
            NSNumber *fileBigFileChunkingEnabledNumber = (NSNumber*)[files valueForKey:@"bigfilechunking"];
            NSNumber *fileUndeleteEnabledNumber = (NSNumber*)[files valueForKey:@"undelete"];
            NSNumber *fileVersioningEnabledNumber = (NSNumber*)[files valueForKey:@"versioning"];
            
            capabilities.isFileBigFileChunkingEnabled = fileBigFileChunkingEnabledNumber.boolValue;
            capabilities.isFileUndeleteEnabled = fileUndeleteEnabledNumber.boolValue;
            capabilities.isFileVersioningEnabled = fileVersioningEnabledNumber.boolValue;
            
        }
        
        successRequest(response, capabilities, request.redirectedServer);
        
    } failure:^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        [self returnErrorWithResponse:response andResponseData:responseData andError:error failureRequest:failureRequest andRequest:request];
    }];
    
}


#pragma mark - Remote thumbnails

- (NSURLSessionTask *) getRemoteThumbnailByServer:(NSString*)serverPath ofFilePath:(NSString *)filePath withWidth:(NSInteger)fileWidth andHeight:(NSInteger)fileHeight onCommunication:(OCCommunication *)sharedOCComunication
                     successRequest:(void(^)(NSHTTPURLResponse *response, NSData *thumbnail, NSString *redirectedServer)) successRequest
                     failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest {
    
    serverPath = [serverPath encodeString:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_thumbnails];
    filePath = [filePath encodeString:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [OCWebDAVClient new];
    request = [self getRequestWithCredentials:request];
    
    
    OCHTTPRequestOperation *operation = [request getRemoteThumbnailByServer:serverPath ofFilePath:filePath withWidth:fileWidth andHeight:fileHeight onCommunication:sharedOCComunication
            success:^(NSHTTPURLResponse *response, id responseObject) {
                NSData *responseData = (NSData*) responseObject;
                
                successRequest(response, responseData, request.redirectedServer);
                                    
            } failure:^(NSHTTPURLResponse *response, id  _Nullable responseObject, NSError * _Nonnull error) {
                failureRequest(response, error, request.redirectedServer);
            }];
    
    [operation resume];

    return operation;
}

#pragma mark - Clear Cache

- (void)eraseURLCache
{
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
}


#pragma mark - Utils

- (void) addShareeItemOfType:(NSInteger) shareeType fromArray:(NSArray*) shareesArray ToList: (NSMutableArray *) itemList
{

    for (NSDictionary *shareeFound in shareesArray) {
        OCShareUser *sharee = [OCShareUser new];
        
        if ([[shareeFound valueForKey:@"label"] isKindOfClass:[NSNumber class]]) {
            NSNumber *number = [shareeFound valueForKey:@"label"];
            sharee.displayName = [NSString stringWithFormat:@"%ld", number.longValue];
        }else{
            sharee.displayName = [shareeFound valueForKey:@"label"];
        }
        
        NSDictionary *shareeValues = [shareeFound valueForKey:@"value"];
        
        if ([[shareeValues valueForKey:@"shareWith"] isKindOfClass:[NSNumber class]]) {
            NSNumber *number = [shareeValues valueForKey:@"shareWith"];
            sharee.name = [NSString stringWithFormat:@"%ld", number.longValue];
        }else{
            sharee.name = [shareeValues valueForKey:@"shareWith"];
        }
        sharee.shareeType = shareeType;
        sharee.server = [shareeValues valueForKey:@"server"];
        
        [itemList addObject:sharee];
    }
}

- (void) returnErrorWithResponse:(NSHTTPURLResponse *) response andResponseData:(NSData *) responseData andError:(NSError *) error failureRequest:(void (^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer))failureRequest andRequest:(OCWebDAVClient *) request {
    OCXMLServerErrorsParser *serverErrorParser = [OCXMLServerErrorsParser new];
       
    [serverErrorParser startToParseWithData:responseData withCompleteBlock:^(NSError *err) {
        
        if (err) {
            failureRequest(response, err, request.redirectedServer);
        }else{
            failureRequest(response, error, request.redirectedServer);
        }
        
    }];
}

@end
