//
//  OCCommunication.m
//  Owncloud iOs Client
//
// Copyright (C) 2015 ownCloud Inc. (http://www.owncloud.org/)
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
#import "OCUploadOperation.h"
#import "OCWebDAVClient.h"
#import "OCXMLShareByLinkParser.h"
#import "OCErrorMsg.h"
#import "AFURLSessionManager.h"
#import "OCShareUser.h"
#import "OCCapabilities.h"

@interface OCCommunication ()

@property (nonatomic, strong) NSString *currentServerVersion;

@end

@implementation OCCommunication


-(id) init {
    
    self = [super init];
    
    if (self) {
        
        //Init the Queue Array
        _uploadOperationQueueArray = [NSMutableArray new];
        
        //Init the Donwload queue array
        _downloadOperationQueueArray = [NSMutableArray new];
        
        //Credentials not set yet
        _kindOfCredential = credentialNotSet;
        
        //Network Queue
        _networkOperationsQueue =[NSOperationQueue new];
        [_networkOperationsQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
        
        [self setSecurityPolicy:[self createSecurityPolicy]];
        
        _isCookiesAvailable = NO;
        _isForbiddenCharactersAvailable = NO;

#ifdef UNIT_TEST
        _uploadSessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:nil];
        _downloadSessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:nil];

#else
        //Network Upload queue for NSURLSession (iOS 7)
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:k_session_name];
        configuration.HTTPMaximumConnectionsPerHost = 1;
        configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        _uploadSessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        [_uploadSessionManager.operationQueue setMaxConcurrentOperationCount:1];
        
        //Network Download queue for NSURLSession (iOS 7)
        NSURLSessionConfiguration *downConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:k_download_session_name];
        downConfiguration.HTTPShouldUsePipelining = YES;
        downConfiguration.HTTPMaximumConnectionsPerHost = 1;
        downConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        _downloadSessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:downConfiguration];
        [_downloadSessionManager.operationQueue setMaxConcurrentOperationCount:1];
 
#endif
        
        
    }
    
    return self;
}

-(id) initWithUploadSessionManager:(AFURLSessionManager *) uploadSessionManager {

    self = [super init];
    
    if (self) {
        
        //Init the Queue Array
        _uploadOperationQueueArray = [NSMutableArray new];
        
        //Init the Donwload queue array
        _downloadOperationQueueArray = [NSMutableArray new];
        
        _isCookiesAvailable = NO;
        _isForbiddenCharactersAvailable = NO;
        
        //Credentials not set yet
        _kindOfCredential = credentialNotSet;
        
        //Network Queue
        _networkOperationsQueue =[NSOperationQueue new];
        [_networkOperationsQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
       
        [self setSecurityPolicy:[self createSecurityPolicy]];
        
        _uploadSessionManager = uploadSessionManager;
    }
    
    return self;
}

-(id) initWithUploadSessionManager:(AFURLSessionManager *) uploadSessionManager andDownloadSessionManager:(AFURLSessionManager *) downloadSessionManager {
    
    self = [super init];
    
    if (self) {
        
        //Init the Queue Array
        _uploadOperationQueueArray = [NSMutableArray new];
        
        //Init the Donwload queue array
        _downloadOperationQueueArray = [NSMutableArray new];
        
        //Credentials not set yet
        _kindOfCredential = credentialNotSet;
        
        //Network Queue
        _networkOperationsQueue =[NSOperationQueue new];
        [_networkOperationsQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
        
        [self setSecurityPolicy:[self createSecurityPolicy]];
        
        _uploadSessionManager = uploadSessionManager;
        _downloadSessionManager = downloadSessionManager;
    }
    
    return self;
}


- (AFSecurityPolicy *) createSecurityPolicy {
    return [AFSecurityPolicy defaultPolicy];
}

- (void)setSecurityPolicy:(AFSecurityPolicy *)securityPolicy {
    _securityPolicy = securityPolicy;
    _uploadSessionManager.securityPolicy = securityPolicy;
    _downloadSessionManager.securityPolicy = securityPolicy;
}

#pragma mark - Setting Credentials

- (void) setCredentialsWithUser:(NSString*) user andPassword:(NSString*) password  {
    _kindOfCredential = credentialNormal;
    _user = user;
    _password = password;
}

- (void) setCredentialsWithCookie:(NSString*) cookie {
    _kindOfCredential = credentialCookie;
    _password = cookie;
}

- (void) setCredentialsOauthWithToken:(NSString*) token {
    _kindOfCredential = credentialOauth;
    _password = token;
}

- (void) setUserAgent:(NSString *)userAgent{
    _userAgent = userAgent;
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
        
        switch (_kindOfCredential) {
            case credentialNotSet:
                //Without credentials
                break;
            case credentialNormal:
            {
                NSString *basicAuthCredentials = [NSString stringWithFormat:@"%@:%@", _user, _password];
                [myRequest addValue:[NSString stringWithFormat:@"Basic %@", [UtilsFramework AFBase64EncodedStringFromString:basicAuthCredentials]] forHTTPHeaderField:@"Authorization"];
                break;
            }
            case credentialCookie:
                [myRequest addValue:_password forHTTPHeaderField:@"Cookie"];
                break;
            case credentialOauth:
                [myRequest addValue:[NSString stringWithFormat:@"Bearer %@", _password] forHTTPHeaderField:@"Authorization"];
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
        
        switch (_kindOfCredential) {
            case credentialNotSet:
                //Without credentials
                break;
            case credentialNormal:
                [myRequest setAuthorizationHeaderWithUsername:_user password:_password];
                break;
            case credentialCookie:
                [myRequest setAuthorizationHeaderWithCookie:_password];
                break;
            case credentialOauth:
                [myRequest setAuthorizationHeaderWithToken:[NSString stringWithFormat:@"Bearer %@", _password]];
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

    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    
    if (self.userAgent) {
        [request setUserAgent:self.userAgent];
    }
    
    path = [path encodeString:NSUTF8StringEncoding];
    
    [request checkServer:path onCommunication:sharedOCCommunication
                    success:^(OCHTTPRequestOperation *operation, id responseObject) {
                        if (successRequest) {
                            successRequest(operation.response, request.redirectedServer);
                        }
                    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
                        failureRequest(operation.response, error, request.redirectedServer);
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
        NSError *error = [UtilsFramework getErrorByCodeId:OCErrorForbidenCharacters];
        errorBeforeRequest(error);
    } else {
        OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
        request = [self getRequestWithCredentials:request];
        request.securityPolicy = _securityPolicy;
        
        path = [path encodeString:NSUTF8StringEncoding];
        
        [request makeCollection:path onCommunication:sharedOCCommunication
                        success:^(OCHTTPRequestOperation *operation, id responseObject) {
                            if (successRequest) {
                                successRequest(operation.response, request.redirectedServer);
                            }
                        } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
                            
                            OCXMLServerErrorsParser *serverErrorParser = [OCXMLServerErrorsParser new];
                            
                            [serverErrorParser startToParseWithData:operation.responseData withCompleteBlock:^(NSError *err) {
                                
                                if (err) {
                                    failureRequest(operation.response, err, request.redirectedServer);
                                }else{
                                    failureRequest(operation.response, error, request.redirectedServer);
                                }
                                
                                
                            }];
                            
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
        NSError *error = [UtilsFramework getErrorByCodeId:OCErrorMovingFolderInsideHimself];
        errorBeforeRequest(error);
    } else if ([UtilsFramework isForbiddenCharactersInFileName:[UtilsFramework getFileNameOrFolderByPath:destinyPath] withForbiddenCharactersSupported:isFCSupported]) {
        //We check that we are making a move not a rename to prevent special characters problems
        NSError *error = [UtilsFramework getErrorByCodeId:OCErrorMovingDestinyNameHaveForbiddenCharacters];
        errorBeforeRequest(error);
    } else {
        
        sourcePath = [sourcePath encodeString:NSUTF8StringEncoding];
        destinyPath = [destinyPath encodeString:NSUTF8StringEncoding];
        
        OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
        request = [self getRequestWithCredentials:request];
        request.securityPolicy = _securityPolicy;
        
        [request movePath:sourcePath toPath:destinyPath onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
            if (successRequest) {
                successRequest(operation.response, request.redirectedServer);
            }
        } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
            
            OCXMLServerErrorsParser *serverErrorParser = [OCXMLServerErrorsParser new];
            
            [serverErrorParser startToParseWithData:operation.responseData withCompleteBlock:^(NSError *err) {
                
                if (err) {
                    failureRequest(operation.response, err, request.redirectedServer);
                }else{
                    failureRequest(operation.response, error, request.redirectedServer);
                }
                
            }];
            
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
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request deletePath:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        if (successRequest) {
            successRequest(operation.response, request.redirectedServer);
        }
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error, request.redirectedServer);
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
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request listPath:path onCommunication:sharedOCCommunication withUserSessionToken:token success:^(OCHTTPRequestOperation *operation, id responseObject, NSString *token) {
        if (successRequest) {
            NSData *response = (NSData*) responseObject;
            
//            NSString* newStr = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
//            NSLog(@"newStr: %@", newStr);
            
            OCXMLParser *parser = [[OCXMLParser alloc]init];
            [parser initParserWithData:response];
            NSMutableArray *directoryList = [parser.directoryList mutableCopy];
            
            //Return success
            successRequest(operation.response, directoryList, request.redirectedServer, token);
        }
        
    } failure:^(OCHTTPRequestOperation *operation, NSError *error, NSString *token) {
        failureRequest(operation.response, error, token, request.redirectedServer);
    }];
}

///-----------------------------------
/// @name Download File
///-----------------------------------

- (NSOperation *) downloadFile:(NSString *)remotePath toDestiny:(NSString *)localPath withLIFOSystem:(BOOL)isLIFO onCommunication:(OCCommunication *)sharedOCCommunication progressDownload:(void(^)(NSUInteger bytesRead,long long totalBytesRead,long long totalBytesExpectedToRead))progressDownload successRequest:(void(^)(NSHTTPURLResponse *response, NSString *redirectedServer)) successRequest failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest shouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    
    remotePath = [remotePath encodeString:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    NSLog(@"Remote File Path: %@", remotePath);
    NSLog(@"Local File Path: %@", localPath);
    
    NSOperation *operation = [request downloadPath:remotePath toPath:localPath withLIFOSystem:isLIFO onCommunication:sharedOCCommunication progress:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        progressDownload(bytesRead,totalBytesRead,totalBytesExpectedToRead);
    } success:^(OCHTTPRequestOperation *operation, id responseObject) {
        successRequest(operation.response, request.redirectedServer);
        if (operation.typeOfOperation == DownloadLIFOQueue)
            [self resumeNextDownload];
        
        
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error, request.redirectedServer);
        if (operation.typeOfOperation == DownloadLIFOQueue)
            [self resumeNextDownload];
        
    } shouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        handler();
    }];
    
    return operation;
}


///-----------------------------------
/// @name Download File Session
///-----------------------------------



- (NSURLSessionDownloadTask *) downloadFileSession:(NSString *)remotePath toDestiny:(NSString *)localPath defaultPriority:(BOOL)defaultPriority onCommunication:(OCCommunication *)sharedOCCommunication withProgress:(NSProgress * __autoreleasing *) progressValue successRequest:(void(^)(NSURLResponse *response, NSURL *filePath)) successRequest failureRequest:(void(^)(NSURLResponse *response, NSError *error)) failureRequest {
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    
    remotePath = [remotePath encodeString:NSUTF8StringEncoding];
    
    NSURLSessionDownloadTask *downloadTask = [request downloadWithSessionPath:remotePath toPath:localPath defaultPriority:defaultPriority onCommunication:sharedOCCommunication withProgress:progressValue
                                                                      success:^(NSURLResponse *response, NSURL *filePath) {
        
                                                                          [UtilsFramework addCookiesToStorageFromResponse:(NSHTTPURLResponse *) response andPath:[NSURL URLWithString:remotePath]];
                                                                          successRequest(response,filePath);
        
                                                                      } failure:^(NSURLResponse *response, NSError *error) {
                                                                          [UtilsFramework addCookiesToStorageFromResponse:(NSHTTPURLResponse *) response andPath:[NSURL URLWithString:remotePath]];
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
/// @name Upload File
///-----------------------------------

- (NSOperation *) uploadFile:(NSString *) localPath toDestiny:(NSString *) remotePath onCommunication:(OCCommunication *)sharedOCCommunication progressUpload:(void(^)(NSUInteger bytesWrote,long long totalBytesWrote, long long totalBytesExpectedToWrote))progressUpload successRequest:(void(^)(NSHTTPURLResponse *response, NSString *redirectedServer)) successRequest failureRequest:(void(^)(NSHTTPURLResponse *response, NSString *redirectedServer, NSError *error)) failureRequest  failureBeforeRequest:(void(^)(NSError *error)) failureBeforeRequest shouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler{
    
    remotePath = [remotePath encodeString:NSUTF8StringEncoding];
    
    OCUploadOperation *operation = [OCUploadOperation new];
    
    [operation createOperationWith:localPath toDestiny:remotePath onCommunication:sharedOCCommunication progressUpload:^(NSUInteger bytesWrote, long long totalBytesWrote, long long totalBytesExpectedToWrote) {
        progressUpload(bytesWrote, totalBytesWrote, totalBytesExpectedToWrote);
    } successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        successRequest(response, redirectedServer);
    } failureRequest:^(NSHTTPURLResponse *response, NSData *responseData, NSString *redirectedServer, NSError *error) {
        
        OCXMLServerErrorsParser *serverErrorParser = [OCXMLServerErrorsParser new];
        
        [serverErrorParser startToParseWithData:responseData withCompleteBlock:^(NSError *err) {
            
            if (err) {
                failureRequest(response, redirectedServer, err);
            }else{
                failureRequest(response, redirectedServer, error);
            }
            
        }];
        
        
    } failureBeforeRequest:^(NSError *error) {
        failureBeforeRequest(error);
    } shouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        handler();
    }];
    
    return operation;
}

///-----------------------------------
/// @name Upload File Session
///-----------------------------------

- (NSURLSessionUploadTask *) uploadFileSession:(NSString *) localPath toDestiny:(NSString *) remotePath onCommunication:(OCCommunication *)sharedOCCommunication withProgress:(NSProgress * __autoreleasing *) progressValue successRequest:(void(^)(NSURLResponse *response, NSString *redirectedServer)) successRequest failureRequest:(void(^)(NSURLResponse *response, NSString *redirectedServer, NSError *error)) failureRequest failureBeforeRequest:(void(^)(NSError *error)) failureBeforeRequest {
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    remotePath = [remotePath encodeString:NSUTF8StringEncoding];
    
    NSURLSessionUploadTask *uploadTask = [request putWithSessionLocalPath:localPath atRemotePath:remotePath onCommunication:sharedOCCommunication withProgress:progressValue
        success:^(NSURLResponse *response, id responseObjec){
            [UtilsFramework addCookiesToStorageFromResponse:(NSHTTPURLResponse *) response andPath:[NSURL URLWithString:remotePath]];
            //TODO: The second parameter is the redirected server
            successRequest(response, @"");
        } failure:^(NSURLResponse *response, id responseObject, NSError *error) {
            [UtilsFramework addCookiesToStorageFromResponse:(NSHTTPURLResponse *) response andPath:[NSURL URLWithString:remotePath]];
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
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request propertiesOfPath:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        
        if (successRequest) {
            NSData *response = (NSData*) responseObject;
            
//            NSString* newStr = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
//            NSLog(@"newStrReadFile: %@", newStr);

            OCXMLParser *parser = [[OCXMLParser alloc]init];
            [parser initParserWithData:response];
            NSMutableArray *directoryList = [parser.directoryList mutableCopy];
            
            //Return success
            successRequest(operation.response, directoryList, request.redirectedServer);
        }
        
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error, request.redirectedServer);
        
    }];
    
}

#pragma mark - OC API Calls

- (NSString *) getCurrentServerVersion {
    return self.currentServerVersion;
}

- (void) getServerVersionWithPath:(NSString*) path onCommunication:(OCCommunication *)sharedOCCommunication
                   successRequest:(void(^)(NSHTTPURLResponse *response, NSString *serverVersion, NSString *redirectedServer)) success
                   failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failure{
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:path]];
    request.securityPolicy = _securityPolicy;
    
    if (self.userAgent) {
        [request setUserAgent:self.userAgent];
    }
    
    [request getStatusOfTheServer:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        
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
        success(operation.response, versionString, request.redirectedServer);
        
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failure(operation.response, error, request.redirectedServer);
    }];
    
}

///-----------------------------------
/// @name Get UserName by cookie
///-----------------------------------

- (void) getUserNameByCookie:(NSString *) cookieString ofServerPath:(NSString *)path onCommunication:
(OCCommunication *)sharedOCCommunication success:(void(^)(NSHTTPURLResponse *response, NSData *responseData, NSString *redirectedServer))success
                     failure:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer))failure{
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:path]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request requestUserNameByCookie:cookieString onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        success(operation.response, operation.responseData, request.redirectedServer);
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failure(operation.response, error, request.redirectedServer);
    }];
}

- (void) getFeaturesSupportedByServer:(NSString*) path onCommunication:(OCCommunication *)sharedOCCommunication
                     successRequest:(void(^)(NSHTTPURLResponse *response, BOOL hasShareSupport, BOOL hasShareeSupport, BOOL hasCookiesSupport, BOOL hasForbiddenCharactersSupport, BOOL hasCapabilitiesSupport, NSString *redirectedServer)) success
                     failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failure{
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:path]];
    request.securityPolicy = _securityPolicy;
    
    if (self.userAgent) {
        [request setUserAgent:self.userAgent];
    }
    
    [request getStatusOfTheServer:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        
        if (responseObject) {
            
            NSError* error = nil;
            NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData: (NSData*) responseObject options: NSJSONReadingMutableContainers error: &error];
            
            if(error) {
                // NSLog(@"Error parsing JSON: %@", error);
                failure(operation.response, operation.error, request.redirectedServer);
            }else{
                
                self.currentServerVersion = [jsonArray valueForKey:@"version"];
                
                BOOL hasShareSupport = [UtilsFramework isServerVersion:self.currentServerVersion higherThanLimitVersion:k_version_support_shared];
                BOOL hasShareeSupport = [UtilsFramework isServerVersion:self.currentServerVersion higherThanLimitVersion:k_version_support_sharee_api];
                BOOL hasCookiesSupport = [UtilsFramework isServerVersion:self.currentServerVersion higherThanLimitVersion:k_version_support_cookies];
                BOOL hasForbiddenCharactersSupport = [UtilsFramework isServerVersion:self.currentServerVersion higherThanLimitVersion:k_version_support_forbidden_characters];
                BOOL hasCapabilitiesSupport = [UtilsFramework isServerVersion:self.currentServerVersion higherThanLimitVersion:k_version_support_capabilities];
                
                success(operation.response, hasShareSupport, hasShareeSupport, hasCookiesSupport, hasForbiddenCharactersSupport, hasCapabilitiesSupport, request.redirectedServer);
            }
            
        } else {
            // NSLog(@"Error parsing JSON: data is null");
            failure(operation.response, operation.error, request.redirectedServer);
        }
        
        
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failure(operation.response, error, request.redirectedServer);
    }];

    
    
    
}


- (void) readSharedByServer: (NSString *) path
            onCommunication:(OCCommunication *)sharedOCCommunication
             successRequest:(void(^)(NSHTTPURLResponse *response, NSArray *listOfShared, NSString *redirectedServer)) successRequest
             failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest {
    
    path = [path encodeString:NSUTF8StringEncoding];
    path = [path stringByAppendingString:k_url_acces_shared_api];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request listSharedByServer:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        if (successRequest) {
            NSData *response = (NSData*) responseObject;
            OCXMLSharedParser *parser = [[OCXMLSharedParser alloc]init];
            
           // NSLog(@"response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
            
            [parser initParserWithData:response];
            NSMutableArray *sharedList = [parser.shareList mutableCopy];
            
            //Return success
            successRequest(operation.response, sharedList, request.redirectedServer);
        }
        
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error, request.redirectedServer);
    }];
}

- (void) readSharedByServer: (NSString *) serverPath andPath: (NSString *) path
            onCommunication:(OCCommunication *)sharedOCCommunication
             successRequest:(void(^)(NSHTTPURLResponse *response, NSArray *listOfShared, NSString *redirectedServer)) successRequest
             failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest {
    
   serverPath = [serverPath encodeString:NSUTF8StringEncoding];
   serverPath = [serverPath stringByAppendingString:k_url_acces_shared_api];
    
   path = [path encodeString:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request listSharedByServer:serverPath andPath:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        if (successRequest) {
            NSData *response = (NSData*) responseObject;
            OCXMLSharedParser *parser = [[OCXMLSharedParser alloc]init];
            
           // NSString *str = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
            
            [parser initParserWithData:response];
            NSMutableArray *sharedList = [parser.shareList mutableCopy];
            
            //Return success
            successRequest(operation.response, sharedList, request.redirectedServer);
        }
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error, request.redirectedServer);
    }];
}

- (void) shareFileOrFolderByServer: (NSString *) serverPath andFileOrFolderPath: (NSString *) filePath andPassword:(NSString *)password
                   onCommunication:(OCCommunication *)sharedOCCommunication
                    successRequest:(void(^)(NSHTTPURLResponse *response, NSString *token, NSString *redirectedServer)) successRequest
                    failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest {
    
    serverPath = [serverPath encodeString:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_acces_shared_api];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request shareByLinkFileOrFolderByServer:serverPath andPath:filePath andPassword:password onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        
        NSData *response = (NSData*) responseObject;
        
        OCXMLShareByLinkParser *parser = [[OCXMLShareByLinkParser alloc]init];
        
      //  NSLog(@"response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
        
        [parser initParserWithData:response];
        
        switch (parser.statusCode) {
            case kOCSharedAPISuccessful:
            {
                NSString *url = parser.url;
                NSString *token = parser.token;
                
                if (url != nil) {
                    
                    successRequest(operation.response, url, request.redirectedServer);
                    
                }else if (token != nil){
                    //We remove the \n and the empty spaces " "
                    token = [token stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
                    
                    successRequest(operation.response, token, request.redirectedServer);
                    
                }else{
                    
                    NSError *error = [UtilsFramework getErrorWithCode:parser.statusCode andCustomMessageFromTheServer:parser.message];
                    failureRequest(operation.response, error, request.redirectedServer);
                }
                
                break;
            }
                
            default:
            {
                NSError *error = [UtilsFramework getErrorWithCode:parser.statusCode andCustomMessageFromTheServer:parser.message];
                failureRequest(operation.response, error, request.redirectedServer);
            }
        }
        
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error, request.redirectedServer);
    }];
}


- (void) shareFileOrFolderByServer: (NSString *) serverPath andFileOrFolderPath: (NSString *) filePath
                   onCommunication:(OCCommunication *)sharedOCCommunication
                    successRequest:(void(^)(NSHTTPURLResponse *response, NSString *shareLink, NSString *redirectedServer)) successRequest
                    failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest {
    
    serverPath = [serverPath encodeString:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_acces_shared_api];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request shareByLinkFileOrFolderByServer:serverPath andPath:filePath onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        
        NSData *response = (NSData*) responseObject;
        
        OCXMLShareByLinkParser *parser = [[OCXMLShareByLinkParser alloc]init];
        
      //  NSLog(@"response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
        
        [parser initParserWithData:response];
        
        switch (parser.statusCode) {
            case kOCSharedAPISuccessful:
            {
                NSString *url = parser.url;
                NSString *token = parser.token;
                
                if (url != nil) {
                    
                    successRequest(operation.response, url, request.redirectedServer);
                    
                }else if (token != nil){
                    //We remove the \n and the empty spaces " "
                    token = [token stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
                    
                    successRequest(operation.response, token, request.redirectedServer);
                    
                }else{
                    
                    NSError *error = [UtilsFramework getErrorWithCode:parser.statusCode andCustomMessageFromTheServer:parser.message];
                    failureRequest(operation.response, error, request.redirectedServer);
                }

                break;
            }
                
            default:
            {
                NSError *error = [UtilsFramework getErrorWithCode:parser.statusCode andCustomMessageFromTheServer:parser.message];
                failureRequest(operation.response, error, request.redirectedServer);
            }
        }

    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error, request.redirectedServer);
    }];
}

- (void)shareWith:(NSString *)userOrGroup shareeType:(NSInteger)shareeType inServer:(NSString *) serverPath andFileOrFolderPath:(NSString *) filePath andPermissions:(NSInteger) permissions onCommunication:(OCCommunication *)sharedOCCommunication
          successRequest:(void(^)(NSHTTPURLResponse *response, NSString *redirectedServer))successRequest
          failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer))failureRequest{
    
    serverPath = [serverPath encodeString:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_acces_shared_api];
    userOrGroup = [userOrGroup encodeString:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request shareWith:userOrGroup shareeType:shareeType inServer:serverPath andPath:filePath andPermissions:permissions onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        NSData *response = (NSData*) responseObject;
        
        OCXMLShareByLinkParser *parser = [[OCXMLShareByLinkParser alloc]init];
        
        //  NSLog(@"response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
        
        [parser initParserWithData:response];
        
        switch (parser.statusCode) {
            case kOCSharedAPISuccessful:
            {
                successRequest(operation.response, request.redirectedServer);                
                break;
            }
                
            default:
            {
                NSError *error = [UtilsFramework getErrorWithCode:parser.statusCode andCustomMessageFromTheServer:parser.message];
                failureRequest(operation.response, error, request.redirectedServer);
            }
        }
        
        
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        
        failureRequest(operation.response, error, request.redirectedServer);
        
        
    }];
    
}

- (void) unShareFileOrFolderByServer: (NSString *) path andIdRemoteShared: (NSInteger) idRemoteShared
                     onCommunication:(OCCommunication *)sharedOCCommunication
                      successRequest:(void(^)(NSHTTPURLResponse *response, NSString *redirectedServer)) successRequest
                      failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest{
    
    path = [path encodeString:NSUTF8StringEncoding];
    path = [path stringByAppendingString:k_url_acces_shared_api];
    path = [path stringByAppendingString:[NSString stringWithFormat:@"/%ld",(long)idRemoteShared]];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request unShareFileOrFolderByServer:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        if (successRequest) {
            //Return success
            successRequest(operation.response, request.redirectedServer);
        }
        
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error, request.redirectedServer);
    }];
}

- (void) isShareFileOrFolderByServer: (NSString *) path andIdRemoteShared: (NSInteger) idRemoteShared
                     onCommunication:(OCCommunication *)sharedOCCommunication
                      successRequest:(void(^)(NSHTTPURLResponse *response, NSString *redirectedServer, BOOL isShared, id shareDto)) successRequest
                      failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest {
    
    path = [path encodeString:NSUTF8StringEncoding];
    path = [path stringByAppendingString:k_url_acces_shared_api];
    path = [path stringByAppendingString:[NSString stringWithFormat:@"/%ld",(long)idRemoteShared]];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request isShareFileOrFolderByServer:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        if (successRequest) {
        
            NSData *response = (NSData*) responseObject;
            OCXMLSharedParser *parser = [[OCXMLSharedParser alloc]init];
            
            // NSLog(@"response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
            
            [parser initParserWithData:response];
            
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
            successRequest(operation.response, request.redirectedServer, isShared, shareDto);
        }
        
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error, request.redirectedServer);
    }];
}

- (void) updateShare:(NSInteger)shareId ofServerPath:(NSString *)serverPath withPasswordProtect:(NSString*)password andExpirationTime:(NSString*)expirationTime andPermissions:(NSInteger)permissions
                   onCommunication:(OCCommunication *)sharedOCCommunication
                    successRequest:(void(^)(NSHTTPURLResponse *response, NSString *redirectedServer)) successRequest
      failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest{
    
    
    serverPath = [serverPath encodeString:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_acces_shared_api];
    serverPath = [serverPath stringByAppendingString:[NSString stringWithFormat:@"/%ld",(long)shareId]];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request updateShareItem:shareId ofServerPath:serverPath withPasswordProtect:password andExpirationTime:expirationTime andPermissions:permissions onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        
        NSData *response = (NSData*) responseObject;
        
        OCXMLShareByLinkParser *parser = [[OCXMLShareByLinkParser alloc]init];
        
     //   NSLog(@"response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
        
        [parser initParserWithData:response];
        
        
        switch (parser.statusCode) {
            case kOCSharedAPISuccessful:
            {
                successRequest(operation.response, request.redirectedServer);
                break;
            }
            
            default:
            {
                NSError *error = [UtilsFramework getErrorWithCode:parser.statusCode andCustomMessageFromTheServer:parser.message];
                failureRequest(operation.response, error, request.redirectedServer);
            }
        }

    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
         failureRequest(operation.response, error, request.redirectedServer);
    }];
    
}

- (void) searchUsersAndGroupsWith:(NSString *)searchString forPage:(NSInteger)page with:(NSInteger)resultsPerPage ofServer:(NSString*)serverPath onCommunication:(OCCommunication *)sharedOCComunication successRequest:(void(^)(NSHTTPURLResponse *response, NSArray *itemList, NSString *redirectedServer)) successRequest failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest{
    
    serverPath = [serverPath encodeString:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_access_sharee_api];
    
    searchString = [searchString encodeString:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    
    [request searchUsersAndGroupsWith:searchString forPage:page with:resultsPerPage ofServer:serverPath onCommunication:sharedOCComunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        
        NSData *response = (NSData*) responseObject;
        
        NSMutableArray *itemList = [NSMutableArray new];
        
        //Parse
        NSError *error;
        NSDictionary *jsongParsed = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingMutableContainers error:&error];
        
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
                
                [self addUserItemOfType:shareTypeUser fromArray:usersFounded ToList:itemList];
                [self addUserItemOfType:shareTypeUser fromArray:usersExact ToList:itemList];
                [self addUserItemOfType:shareTypeRemote fromArray:usersRemote ToList:itemList];
                [self addUserItemOfType:shareTypeRemote fromArray:remotesExact ToList:itemList];
                [self addGroupItemFromArray:groupsFounded ToList:itemList];
                [self addGroupItemFromArray:groupsExact ToList:itemList];
            
            }else{
                
                NSString *message = (NSString*)[metaDict objectForKey:@"message"];
                
                if ([message isKindOfClass:[NSNull class]]) {
                    message = @"";
                }
                
                NSError *error = [UtilsFramework getErrorWithCode:statusCode andCustomMessageFromTheServer:message];
                failureRequest(operation.response, error, request.redirectedServer);
                
            }
            
            //Return success
            successRequest(operation.response, itemList, request.redirectedServer);
            
        }
        
        
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error, request.redirectedServer);
    }];
}

- (void) getCapabilitiesOfServer:(NSString*)serverPath onCommunication:(OCCommunication *)sharedOCComunication successRequest:(void(^)(NSHTTPURLResponse *response, OCCapabilities *capabilities, NSString *redirectedServer)) successRequest failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest{
    
    serverPath = [serverPath encodeString:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_capabilities];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request getCapabilitiesOfServer:serverPath onCommunication:sharedOCComunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        
        NSData *response = (NSData*) responseObject;
        
        NSLog(@"response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
        
        //Parse
        NSError *error;
        NSDictionary *jsongParsed = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingMutableContainers error:&error];
        NSLog(@"dic: %@",jsongParsed);
        
        OCCapabilities *capabilities = [OCCapabilities new];
        
        if (jsongParsed.allKeys > 0 ) {
            
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
            NSNumber *filesSharingAllowUserSendMailNotificationAboutShareLinkEnabledNumber = (NSNumber*)[fileSharingPublic valueForKey:@"send_mail"];
            
            capabilities.isFilesSharingShareLinkEnabled = filesSharingShareLinkEnabledNumber.boolValue;
            capabilities.isFilesSharingAllowPublicUploadsEnabled = filesSharingAllowPublicUploadsEnabledNumber.boolValue;
            capabilities.isFilesSharingAllowUserSendMailNotificationAboutShareLinkEnabled = filesSharingAllowUserSendMailNotificationAboutShareLinkEnabledNumber.boolValue;
            
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
        
        successRequest(operation.response, capabilities, request.redirectedServer);
        
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        
        failureRequest(operation.response, error, request.redirectedServer);
        
    }];
    
}


#pragma mark - Remote thumbnails

- (NSOperation *) getRemoteThumbnailByServer:(NSString*)serverPath ofFilePath:(NSString *)filePath withWidth:(NSInteger)fileWidth andHeight:(NSInteger)fileHeight onCommunication:(OCCommunication *)sharedOCComunication
                     successRequest:(void(^)(NSHTTPURLResponse *response, NSData *thumbnail, NSString *redirectedServer)) successRequest
                     failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer)) failureRequest {
    
    serverPath = [serverPath encodeString:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_thumbnails];
    filePath = [filePath encodeString:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    NSOperation *operation = [request getRemoteThumbnailByServer:serverPath ofFilePath:filePath withWidth:fileWidth andHeight:fileHeight onCommunication:sharedOCComunication
            success:^(OCHTTPRequestOperation *operation, id responseObject) {
                NSData *response = (NSData*) responseObject;
                                    
                //NSLog(@"response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);

                successRequest(operation.response, response, request.redirectedServer);
                                    
            }
            failure:^(OCHTTPRequestOperation *operation, NSError *error) {
                failureRequest(operation.response, error, request.redirectedServer);
            }];

    return operation;
}


#pragma mark - Queue System

- (void) addOperationToTheNetworkQueue:(OCHTTPRequestOperation *) operation {
    
    [self eraseURLCache];
    
    //Suspended the queue while is added a new operation
    [_networkOperationsQueue setSuspended:YES];
    
    NSArray *operationArray = [_networkOperationsQueue operations];
    
    //NSLog(@"operations array has: %d operations", operationArray.count);
    //NSLog(@"current operation description: %@", operation.description);
    
    OCHTTPRequestOperation *lastOperationDownload;
    OCHTTPRequestOperation *firstOperationDownload;
    OCHTTPRequestOperation *lastOperationUpload;
    OCHTTPRequestOperation *lastOperationNavigation;
    
    
    //We get the last operation for each type
    for (int i = 0 ; i < [operationArray count] ; i++) {
        OCHTTPRequestOperation *currentOperation = [operationArray objectAtIndex:i];
        
        
        switch (operation.typeOfOperation) {
            case DownloadLIFOQueue:
                if(currentOperation.typeOfOperation == DownloadLIFOQueue) {
                    //Get first download operation in progress, for LIFO option
                    if (currentOperation.isExecuting)
                        firstOperationDownload = currentOperation;
                }
                 break;
            
            case DownloadFIFOQueue:
                if(currentOperation.typeOfOperation == DownloadFIFOQueue) {
                    lastOperationDownload = currentOperation;
                }
                break;
            case UploadQueue:
                if(currentOperation.typeOfOperation == UploadQueue)
                    lastOperationUpload = currentOperation;
                
                break;
            case NavigationQueue:
                if(currentOperation.typeOfOperation == NavigationQueue)
                    lastOperationNavigation = currentOperation;
                
                break;
                
            default:
                break;
        }
    }
    
    //We add the dependency
    switch (operation.typeOfOperation) {
        case DownloadLIFOQueue:
            //If there are download in progress, pause and store in download array
            if (firstOperationDownload) {
                [firstOperationDownload pause];
                [_downloadOperationQueueArray addObject:firstOperationDownload];
            }
            break;
        case DownloadFIFOQueue:
            if(lastOperationDownload)
                [operation addDependency:lastOperationDownload];
            
            break;
        case UploadQueue:
            if(lastOperationUpload)
                [operation addDependency:lastOperationUpload];
            
            break;
        case NavigationQueue:
            if(lastOperationNavigation)
                [operation addDependency:lastOperationNavigation];
            
            break;
            
        default:
            break;
    }
    
    //Finally we add the new operation to the queue
    [self.networkOperationsQueue addOperation:operation];
    
    //Relaunch the queue again
    [_networkOperationsQueue setSuspended:NO];
    
}

///-----------------------------------
/// @name Resume Next Download
///-----------------------------------

/**
 * This method is called when the download is finished (success or failure).
 * Here we check if exist download operation in LIFO queue array and begin with the next
 *
 * @warning Only we use this method when we are using LIFO queue system
 */
- (void) resumeNextDownload{
    
    //Check if there are donwloads in array
    if (_downloadOperationQueueArray.count > 0) {
        
        OCHTTPRequestOperation *nextPausedDownload = [_downloadOperationQueueArray lastObject];
        //Check if the download operation was cancelled previously
        if (nextPausedDownload.isCancelled) {
            [nextPausedDownload cancel];
            [_downloadOperationQueueArray removeLastObject];
            //Call again this method to the next download
            [self resumeNextDownload];
        } else {
           
            [nextPausedDownload resume];
            [_downloadOperationQueueArray removeLastObject];
        }
    }
}


#pragma mark - Clear Cache

- (void)eraseURLCache
{
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
}


#pragma mark - Utils

- (void) addUserItemOfType:(NSInteger) shareeType fromArray:(NSArray*) usersArray ToList: (NSMutableArray *) itemList
{

    for (NSDictionary *userFound in usersArray) {
        OCShareUser *user = [OCShareUser new];
        
        if ([[userFound valueForKey:@"label"] isKindOfClass:[NSNumber class]]) {
            NSNumber *number = [userFound valueForKey:@"label"];
            user.displayName = [NSString stringWithFormat:@"%ld", number.longValue];
        }else{
            user.displayName = [userFound valueForKey:@"label"];
        }
        
        NSDictionary *userValues = [userFound valueForKey:@"value"];
        
        if ([[userValues valueForKey:@"shareWith"] isKindOfClass:[NSNumber class]]) {
            NSNumber *number = [userValues valueForKey:@"shareWith"];
            user.name = [NSString stringWithFormat:@"%ld", number.longValue];
        }else{
            user.name = [userValues valueForKey:@"shareWith"];
        }
        user.shareeType = shareeType;
        user.server = [userValues valueForKey:@"server"];
        
        [itemList addObject:user];
    }
}

- (void) addGroupItemFromArray:(NSArray*) groupsArray ToList: (NSMutableArray *) itemList
{
    for (NSDictionary *groupFound in groupsArray) {
        
        OCShareUser *group = [OCShareUser new];
        
        NSDictionary *groupValues = [groupFound valueForKey:@"value"];
        if ([[groupValues valueForKey:@"shareWith"] isKindOfClass:[NSNumber class]]) {
            NSNumber *number = [groupValues valueForKey:@"shareWith"];
            group.name = [NSString stringWithFormat:@"%ld", number.longValue];
        }else{
            group.name = [groupValues valueForKey:@"shareWith"];
        }
        group.shareeType = shareTypeGroup;
        
        [itemList addObject:group];
        
    }
}

@end
