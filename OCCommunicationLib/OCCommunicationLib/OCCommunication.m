//
//  OCCommunication.m
//  Owncloud iOs Client
//
// Copyright (C) 2014 ownCloud Inc. (http://www.owncloud.org/)
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
#import "NSString+Encode.h"
#import "OCFrameworkConstants.h"
#import "OCUploadOperation.h"
#import "OCWebDAVClient.h"
#import "OCXMLShareByLinkParser.h"
#import "OCErrorMsg.h"
#import "AFURLSessionManager.h"

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
        
        [self setSecurityPolicy:[AFSecurityPolicy defaultPolicy]];
        _isCookiesAvailable = NO;

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
        
        //Credentials not set yet
        _kindOfCredential = credentialNotSet;
        
        //Network Queue
        _networkOperationsQueue =[NSOperationQueue new];
        [_networkOperationsQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
        [self setSecurityPolicy:[AFSecurityPolicy defaultPolicy]];
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
        
        [self setSecurityPolicy:[AFSecurityPolicy defaultPolicy]];
        
        _uploadSessionManager = uploadSessionManager;
        _downloadSessionManager = downloadSessionManager;
    }
    
    return self;
}

- (void)setSecurityPolicy:(AFSecurityPolicy *)securityPolicy {
    _securityPolicy = securityPolicy;
    _uploadSessionManager.securityPolicy = securityPolicy;
    _downloadSessionManager.securityPolicy = securityPolicy;
}

#pragma mark - Setting Credentials

- (void) setCredentialsWithUser:(NSString*) user andPassword:(NSString*) password {
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
        
        return request;
    } else {
        NSLog(@"We do not know witch kind of object is");
        return  request;
    }
}

#pragma mark - Network Operations

///-----------------------------------
/// @name Create a folder
///-----------------------------------
- (void) createFolder: (NSString *) path
      onCommunication:(OCCommunication *)sharedOCCommunication
       successRequest:(void(^)(NSHTTPURLResponse *response, NSString *redirectedServer)) successRequest
       failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error)) failureRequest
   errorBeforeRequest:(void(^)(NSError *error)) errorBeforeRequest {
    
    if ([UtilsFramework isForbidenCharactersInFileName:[UtilsFramework getFileNameOrFolderByPath:path]]) {
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
                            failureRequest(operation.response, error);
                        }];
    }
}

///-----------------------------------
/// @name Move a file or a folder
///-----------------------------------
- (void) moveFileOrFolder:(NSString *)sourcePath
                toDestiny:(NSString *)destinyPath
          onCommunication:(OCCommunication *)sharedOCCommunication
           successRequest:(void (^)(NSHTTPURLResponse *response, NSString *redirectServer))successRequest
           failureRequest:(void (^)(NSHTTPURLResponse *response, NSError *error))failureRequest
       errorBeforeRequest:(void (^)(NSError *error))errorBeforeRequest {
    
    if ([UtilsFramework isTheSameFileOrFolderByNewURLString:destinyPath andOriginURLString:sourcePath]) {
        //We check that we are not trying to move the file to the same place
        NSError *error = [UtilsFramework getErrorByCodeId:OCErrorMovingTheDestinyAndOriginAreTheSame];
        errorBeforeRequest(error);
    } else if ([UtilsFramework isAFolderUnderItByNewURLString:destinyPath andOriginURLString:sourcePath]) {
        //We check we are not trying to move a folder inside himself
        NSError *error = [UtilsFramework getErrorByCodeId:OCErrorMovingFolderInsideHimself];
        errorBeforeRequest(error);
    } else if ([UtilsFramework isForbidenCharactersInFileName:[UtilsFramework getFileNameOrFolderByPath:destinyPath]]) {
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
            failureRequest(operation.response, error);
        }];
    }
}


///-----------------------------------
/// @name Delete a file or a folder
///-----------------------------------
- (void) deleteFileOrFolder:(NSString *)path
            onCommunication:(OCCommunication *)sharedOCCommunication
             successRequest:(void (^)(NSHTTPURLResponse *response, NSString *redirectedServer))successRequest
              failureRquest:(void (^)(NSHTTPURLResponse *resposne, NSError *error))failureRequest {
    
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request deletePath:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        if (successRequest) {
            successRequest(operation.response, request.redirectedServer);
        }
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error);
    }];
}


///-----------------------------------
/// @name Read folder
///-----------------------------------
- (void) readFolder: (NSString *) path
    onCommunication:(OCCommunication *)sharedOCCommunication
     successRequest:(void(^)(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer)) successRequest
     failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error)) failureRequest{
    
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request listPath:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        if (successRequest) {
            NSData *response = (NSData*) responseObject;
            
            //NSString* newStr = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
            //NSLog(@"newStr: %@", newStr);
            
            OCXMLParser *parser = [[OCXMLParser alloc]init];
            [parser initParserWithData:response];
            NSMutableArray *directoryList = [parser.directoryList mutableCopy];
            
            //Return success
            successRequest(operation.response, directoryList, request.redirectedServer);
        }
        
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error);
    }];
}

///-----------------------------------
/// @name Download File
///-----------------------------------

- (NSOperation *) downloadFile:(NSString *)remotePath toDestiny:(NSString *)localPath withLIFOSystem:(BOOL)isLIFO onCommunication:(OCCommunication *)sharedOCCommunication progressDownload:(void(^)(NSUInteger bytesRead,long long totalBytesRead,long long totalBytesExpectedToRead))progressDownload successRequest:(void(^)(NSHTTPURLResponse *response, NSString *redirectedServer)) successRequest failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error)) failureRequest shouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    
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
        failureRequest(operation.response, error);
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
    
    remotePath = [remotePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
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
    } failureRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer, NSError *error) {
        failureRequest(response, redirectedServer, error);
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
    
    remotePath = [remotePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURLSessionUploadTask *uploadTask = [request putWithSessionLocalPath:localPath atRemotePath:remotePath onCommunication:sharedOCCommunication withProgress:progressValue
        success:^(NSURLResponse *response, id responseObjec){
            [UtilsFramework addCookiesToStorageFromResponse:(NSHTTPURLResponse *) response andPath:[NSURL URLWithString:remotePath]];
            //TODO: The second parameter is the redirected server
            successRequest(response, @"");
        } failure:^(NSURLResponse *response, NSError *error) {
            [UtilsFramework addCookiesToStorageFromResponse:(NSHTTPURLResponse *) response andPath:[NSURL URLWithString:remotePath]];
            //TODO: The second parameter is the redirected server
            failureRequest(response, @"", error);
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
   failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error)) failureRequest {
    
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request propertiesOfPath:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        
        if (successRequest) {
            NSData *response = (NSData*) responseObject;
            OCXMLParser *parser = [[OCXMLParser alloc]init];
            [parser initParserWithData:response];
            NSMutableArray *directoryList = [parser.directoryList mutableCopy];
            
            //Return success
            successRequest(operation.response, directoryList, request.redirectedServer);
        }
        
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error);
        
    }];
    
}

#pragma mark - OC API Calls

///-----------------------------------
/// @name Get UserName by cookie
///-----------------------------------

- (void) getUserNameByCookie:(NSString *) cookieString ofServerPath:(NSString *)path onCommunication:
(OCCommunication *)sharedOCCommunication success:(void(^)(NSHTTPURLResponse *response, NSData *responseData, NSString *redirectedServer))success
                     failure:(void(^)(NSHTTPURLResponse *response, NSError *error))failure{
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:path]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request requestUserNameByCookie:cookieString onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        success(operation.response, operation.responseData, request.redirectedServer);
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failure(operation.response, error);
    }];
}

///-----------------------------------
/// @name Get if the server support share
///-----------------------------------
- (void) hasServerShareSupport:(NSString*) path onCommunication:(OCCommunication *)sharedOCCommunication
                successRequest:(void(^)(NSHTTPURLResponse *response, BOOL hasSupport, NSString *redirectedServer)) success
                failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error)) failure{
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:path]];
    request.securityPolicy = _securityPolicy;
   
    [request getTheStatusOfTheServer:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        
        NSData *data = (NSData*) responseObject;
        NSString *versionString = [NSString new];
        NSError* error=nil;
        
        BOOL hasSharedSupport = NO;
        
        if (data) {
            NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &error];
            if(error) {
                NSLog(@"Error parsing JSON: %@", error);
            } else {
                //Obtain the server version from the version field
                versionString = [jsonArray valueForKey:@"version"];
            }
        } else {
            NSLog(@"Error parsing JSON: data is null");
        }
        
        // NSLog(@"version string: %@", versionString);
        
        //Split the strings - Type 5.0.13
        NSArray *spliteVersion = [versionString componentsSeparatedByString:@"."];
        
        
        NSMutableArray *currentVersionArrray = [NSMutableArray new];
        for (NSString *string in spliteVersion) {
            [currentVersionArrray addObject:string];
        }
        
        NSArray *firstVersionSupportShared = k_version_support_shared;
        
        hasSharedSupport = [UtilsFramework isServerVersion:currentVersionArrray higherThanLimitVersion:firstVersionSupportShared];
        
        success(operation.response, hasSharedSupport, request.redirectedServer);
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failure(operation.response, error);
    }];
}

///-----------------------------------
/// @name Get if the server support cookies
///-----------------------------------
- (void) hasServerCookiesSupport:(NSString*) path onCommunication:(OCCommunication *)sharedOCCommunication
                successRequest:(void(^)(NSHTTPURLResponse *response, BOOL hasSupport, NSString *redirectedServer)) success
                failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error)) failure {
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:path]];
    
    [request getTheStatusOfTheServer:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        
        NSData *data = (NSData*) responseObject;
        NSString *versionString = [NSString new];
        NSError* error=nil;
        
        BOOL hasCookiesSupport = NO;
        
        if (data) {
            NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &error];
            if(error) {
                NSLog(@"Error parsing JSON: %@", error);
            } else {
                //Obtain the server version from the version field
                versionString = [jsonArray valueForKey:@"version"];
            }
        } else {
            NSLog(@"Error parsing JSON: data is null");
        }
        
        // NSLog(@"version string: %@", versionString);
        
        //Split the strings - Type 5.0.13
        NSArray *spliteVersion = [versionString componentsSeparatedByString:@"."];
        
        
        NSMutableArray *currentVersionArrray = [NSMutableArray new];
        for (NSString *string in spliteVersion) {
            [currentVersionArrray addObject:string];
        }
        
        NSArray *firstVersionSupportCookies = k_version_support_cookies;
        
        hasCookiesSupport = [UtilsFramework isServerVersion:currentVersionArrray higherThanLimitVersion:firstVersionSupportCookies];
        
        success(operation.response, hasCookiesSupport, request.redirectedServer);
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failure(operation.response, error);
    }];
}

- (void) readSharedByServer: (NSString *) path
            onCommunication:(OCCommunication *)sharedOCCommunication
             successRequest:(void(^)(NSHTTPURLResponse *response, NSArray *listOfShared, NSString *redirectedServer)) successRequest
             failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error)) failureRequest {
    
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
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
        failureRequest(operation.response, error);
    }];
}

- (void) readSharedByServer: (NSString *) serverPath andPath: (NSString *) path
            onCommunication:(OCCommunication *)sharedOCCommunication
             successRequest:(void(^)(NSHTTPURLResponse *response, NSArray *listOfShared, NSString *redirectedServer)) successRequest
             failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error)) failureRequest {
    
    serverPath = [serverPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_acces_shared_api];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request listSharedByServer:serverPath andPath:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        if (successRequest) {
            NSData *response = (NSData*) responseObject;
            OCXMLSharedParser *parser = [[OCXMLSharedParser alloc]init];
            
            [parser initParserWithData:response];
            NSMutableArray *sharedList = [parser.shareList mutableCopy];
            
            //Return success
            successRequest(operation.response, sharedList, request.redirectedServer);
        }
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error);
    }];
}

- (void) shareFileOrFolderByServer: (NSString *) serverPath andFileOrFolderPath: (NSString *) filePath
                   onCommunication:(OCCommunication *)sharedOCCommunication
                    successRequest:(void(^)(NSHTTPURLResponse *response, NSString *listOfShared, NSString *redirectedServer)) successRequest
                    failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error)) failureRequest {
    
    serverPath = [serverPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_acces_shared_api];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request shareByLinkFileOrFolderByServer:serverPath andPath:filePath onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        if (successRequest) {
            NSData *response = (NSData*) responseObject;
            
            OCXMLShareByLinkParser *parser = [[OCXMLShareByLinkParser alloc]init];
        
            //NSLog(@"response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
            
            [parser initParserWithData:response];
        
            
            switch (parser.statusCode) {
                case kOCErrorServerUnauthorized:
                {
                    NSError *error = [UtilsFramework getErrorByCodeId:kOCErrorServerUnauthorized];
                    
                    failureRequest(operation.response, error);
                    break;
                }
                case kOCErrorServerForbidden:
                {
                    NSError *error = [UtilsFramework getErrorByCodeId:kOCErrorServerForbidden];
                    
                    failureRequest(operation.response, error);
                    break;
                }
                case kOCErrorServerPathNotFound:
                {
                    NSError *error = [UtilsFramework getErrorByCodeId:kOCErrorServerPathNotFound];
                    
                    failureRequest(operation.response, error);
                    break;
                }
                default:
                {
                    
                    NSString *token = parser.token;
                    
                    //We remove the \n and the empty spaces " "
                    token = [token stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
                    
                    if (token) {
                        //Return success
                        successRequest(operation.response, token, request.redirectedServer);
                    } else {
                        //Token is nill so it does not exist
                        NSError *error = [UtilsFramework getErrorByCodeId:kOCErrorServerPathNotFound];
                        
                        failureRequest(operation.response, error);
                    }
                    
                    break;
                }
            }
        }

    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error);
    }];
}

- (void) unShareFileOrFolderByServer: (NSString *) path andIdRemoteShared: (int) idRemoteShared
                     onCommunication:(OCCommunication *)sharedOCCommunication
                      successRequest:(void(^)(NSHTTPURLResponse *response, NSString *redirectedServer)) successRequest
                      failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error)) failureRequest{
    
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    path = [path stringByAppendingString:k_url_acces_shared_api];
    path = [path stringByAppendingString:[NSString stringWithFormat:@"/%d",idRemoteShared]];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request unShareFileOrFolderByServer:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        if (successRequest) {
            //Return success
            successRequest(operation.response, request.redirectedServer);
        }
        
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error);
    }];
}

- (void) isShareFileOrFolderByServer: (NSString *) path andIdRemoteShared: (int) idRemoteShared
                     onCommunication:(OCCommunication *)sharedOCCommunication
                      successRequest:(void(^)(NSHTTPURLResponse *response, NSString *redirectedServer, BOOL isShared)) successRequest
                      failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error)) failureRequest {
    
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    path = [path stringByAppendingString:k_url_acces_shared_api];
    path = [path stringByAppendingString:[NSString stringWithFormat:@"/%d",idRemoteShared]];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    request.securityPolicy = _securityPolicy;
    
    [request isShareFileOrFolderByServer:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        if (successRequest) {
        
            NSData *response = (NSData*) responseObject;
            OCXMLSharedParser *parser = [[OCXMLSharedParser alloc]init];
            
            // NSLog(@"response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
            
            [parser initParserWithData:response];
            NSMutableArray *sharedList = [parser.shareList mutableCopy];
            
            BOOL isShared = NO;
            
            if ([sharedList count] > 0) {
                isShared = YES;
            }
            
            
            //Return success
            successRequest(operation.response, request.redirectedServer, isShared);
        }
        
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error);
    }];
}

#pragma mark - Queue System

/*
 * Method to add a new operation to the queue
 */
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

@end
