//
//  OCCommunication.m
//  Owncloud iOs Client
//
// Copyright (c) 2014 ownCloud (http://www.owncloud.org/)
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


@implementation OCCommunication


-(id) init {
    
    self = [super init];
    
    if (self) {
        
        //Init the Queue Array
        _uploadOperationQueueArray = [[NSMutableArray alloc] init];
        
        //Credentials not set yet
        _kindOfCredential = credentialNotSet;
        
        //Network Queue
        _networkOperationsQueue =[[NSOperationQueue alloc] init];
        [_networkOperationsQueue setMaxConcurrentOperationCount:3];
    }
    
    return self;
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
}




#pragma mark - Network Operations

///-----------------------------------
/// @name Create a folder
///-----------------------------------
- (void) createFolder: (NSString *) path
      onCommunication:(OCCommunication *)sharedOCCommunication
       successRequest:(void(^)(NSHTTPURLResponse *, NSString *)) successRequest
       failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest
   errorBeforeRequest:(void(^)(NSError *)) errorBeforeRequest {
    
    if ([UtilsFramework isForbidenCharactersInFileName:[UtilsFramework getFileNameOrFolderByPath:path]]) {
        NSError *error = [UtilsFramework getErrorByCodeId:OCErrorForbidenCharacters];
        errorBeforeRequest(error);
    } else {
        OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
        
        request = [self getRequestWithCredentials:request];
        
        path = [path encodeString:NSUTF8StringEncoding];
        
        [request makeCollection:path onCommunication:sharedOCCommunication
                        success:^(OCHTTPRequestOperation *operation, id responseObject) {
                            if (successRequest) {
                                successRequest(operation.response, operation.redirectedServer);
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
           successRequest:(void (^)(NSHTTPURLResponse *, NSString *))successRequest
           failureRequest:(void (^)(NSHTTPURLResponse *, NSError *))failureRequest
       errorBeforeRequest:(void (^)(NSError *))errorBeforeRequest {
    
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
        
        [request movePath:sourcePath toPath:destinyPath onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
            if (successRequest) {
                successRequest(operation.response, operation.redirectedServer);
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
             successRequest:(void (^)(NSHTTPURLResponse *, NSString *))successRequest
              failureRquest:(void (^)(NSHTTPURLResponse *, NSError *))failureRequest {
    
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    
    [request deletePath:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        if (successRequest) {
            successRequest(operation.response, operation.redirectedServer);
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
     successRequest:(void(^)(NSHTTPURLResponse *, NSArray *, NSString *)) successRequest
     failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest {
    
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    
    [request listPath:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        if (successRequest) {
            NSData *response = (NSData*) responseObject;
            OCXMLParser *parser = [[OCXMLParser alloc]init];
            [parser initParserWithData:response];
            NSMutableArray *directoryList = [parser.directoryList mutableCopy];
            
            //Return success
            successRequest(operation.response, directoryList, operation.redirectedServer);
        }
        
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error);
    }];
}

///-----------------------------------
/// @name Download File
///-----------------------------------

- (NSOperation *) downloadFile:(NSString *)remotePath toDestiny:(NSString *)localPath onCommunication:(OCCommunication *)sharedOCCommunication progressDownload:(void(^)(NSUInteger, long long, long long))progressDownload successRequest:(void(^)(NSHTTPURLResponse *, NSString *)) successRequest failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest shouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    
    remotePath = [remotePath encodeString:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    
    NSLog(@"Remote File Path: %@", remotePath);
    NSLog(@"Local File Path: %@", localPath);
    
    NSOperation *operation = [request downloadPath:remotePath toPath:localPath onCommunication:sharedOCCommunication progress:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        progressDownload(bytesRead,totalBytesRead,totalBytesExpectedToRead);
    } success:^(OCHTTPRequestOperation *operation, id responseObject) {
        successRequest(operation.response, operation.redirectedServer);
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error);
    } shouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        handler();
    }];
    
    return operation;
}


///-----------------------------------
/// @name Upload File
///-----------------------------------

- (NSOperation *) uploadFile:(NSString *) localPath toDestiny:(NSString *) remotePath onCommunication:(OCCommunication *)sharedOCCommunication progressUpload:(void(^)(NSUInteger, long long, long long))progressUpload successRequest:(void(^)(NSHTTPURLResponse *, NSString *)) successRequest failureRequest:(void(^)(NSHTTPURLResponse *, NSString *, NSError *)) failureRequest  failureBeforeRequest:(void(^)(NSError *)) failureBeforeRequest shouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    
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
/// @name Read File
///-----------------------------------
- (void) readFile: (NSString *) path
  onCommunication:(OCCommunication *)sharedOCCommunication
   successRequest:(void(^)(NSHTTPURLResponse *, NSArray *, NSString *)) successRequest
   failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest {
    
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    
    [request propertiesOfPath:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        
        if (successRequest) {
            NSData *response = (NSData*) responseObject;
            OCXMLParser *parser = [[OCXMLParser alloc]init];
            [parser initParserWithData:response];
            NSMutableArray *directoryList = [parser.directoryList mutableCopy];
            
            //Return success
            successRequest(operation.response, directoryList, operation.redirectedServer);
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
(OCCommunication *)sharedOCCommunication success:(void(^)(NSHTTPURLResponse *, NSData *, NSString *))success
                     failure:(void(^)(NSHTTPURLResponse *, NSError *))failure{
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:path]];
    request = [self getRequestWithCredentials:request];
    
    [request requestUserNameByCookie:cookieString onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        success(operation.response, operation.responseData, operation.redirectedServer);
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failure(operation.response, error);
    }];
}

- (void) hasServerShareSupport:(NSString*) path onCommunication:(OCCommunication *)sharedOCCommunication
                successRequest:(void(^)(NSHTTPURLResponse *,BOOL, NSString *)) success
                failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failure{
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:path]];
   
    [request getTheStatusOfTheServer:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        
        NSData *data = (NSData*) responseObject;
        NSString *versionString = [NSString new];
        NSError* error=nil;
        
        __block BOOL hasSharedSupport = NO;
        
        if (data) {
            NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &error];
            if(error) {
                NSLog(@"Error parsing JSON: %@", error);
            } else {
                versionString = [jsonArray valueForKey:@"versionstring"];
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
        
       // NSLog(@"First version that supported Shared API: %@", firstVersionSupportShared);
        //NSLog(@"Current version: %@", currentVersionArrray);
        
        //Loop of compare
        [firstVersionSupportShared enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *firstVersionString = obj;
            NSString *currentVersionString = [currentVersionArrray objectAtIndex:idx];
            
            int firstVersionInt = [firstVersionString intValue];
            int currentVersionInt = [currentVersionString intValue];
            
            //NSLog(@"firstVersion item %d item is: %d", idx, firstVersionInt);
            //NSLog(@"currentVersion item %d item is: %d", idx, currentVersionInt);
            
            //Comparation secure
            switch (idx) {
                case 0:
                    //if the first number is higher
                    if (currentVersionInt > firstVersionInt) {
                        hasSharedSupport = YES;
                        *stop=YES;
                    }
                    //if the first number is lower
                    if (currentVersionInt < firstVersionInt) {
                        hasSharedSupport = NO;
                        *stop=YES;
                    }
                    
                    break;
                    
                case 1:
                    //if the seccond number is higger
                    if (currentVersionInt > firstVersionInt) {
                        hasSharedSupport = YES;
                        *stop=YES;
                    }
                    //if the second number is lower
                    if (currentVersionInt < firstVersionInt) {
                        hasSharedSupport = NO;
                        *stop=YES;
                    }
                    break;
                    
                case 2:
                    //if the third number is higger or equal
                    if (currentVersionInt >= firstVersionInt) {
                        hasSharedSupport = YES;
                        *stop=YES;
                    }else{
                        //if the third number is lower
                        hasSharedSupport = NO;
                        *stop=YES;
                    }
                    break;
                    
                default:
                    
                    break;
            }
 
            
        }];
        

        
        success(operation.response, hasSharedSupport, operation.redirectedServer);
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failure(operation.response, error);
    }];
    
}

- (void) readSharedByServer: (NSString *) path
    onCommunication:(OCCommunication *)sharedOCCommunication
     successRequest:(void(^)(NSHTTPURLResponse *, NSArray *, NSString *)) successRequest
     failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest {
    
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    path = [path stringByAppendingString:k_url_acces_shared_api];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    
    [request listSharedByServer:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        if (successRequest) {
            NSData *response = (NSData*) responseObject;
            OCXMLSharedParser *parser = [[OCXMLSharedParser alloc]init];
            
           // NSLog(@"response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
            
            [parser initParserWithData:response];
            NSMutableArray *sharedList = [parser.shareList mutableCopy];
            
            //Return success
            successRequest(operation.response, sharedList, operation.redirectedServer);
        }
        
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error);
    }];
}

- (void) readSharedByServer: (NSString *) serverPath andPath: (NSString *) path
            onCommunication:(OCCommunication *)sharedOCCommunication
             successRequest:(void(^)(NSHTTPURLResponse *, NSArray *, NSString *)) successRequest
             failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest {
    
    serverPath = [serverPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_acces_shared_api];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    
    [request listSharedByServer:serverPath andPath:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        if (successRequest) {
            NSData *response = (NSData*) responseObject;
            OCXMLSharedParser *parser = [[OCXMLSharedParser alloc]init];
            
            [parser initParserWithData:response];
            NSMutableArray *sharedList = [parser.shareList mutableCopy];
            
            //Return success
            successRequest(operation.response, sharedList, operation.redirectedServer);
        }
    } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
        failureRequest(operation.response, error);
    }];
}

- (void) shareFileOrFolderByServer: (NSString *) serverPath andFileOrFolderPath: (NSString *) filePath
                   onCommunication:(OCCommunication *)sharedOCCommunication
                    successRequest:(void(^)(NSHTTPURLResponse *, NSString *, NSString *)) successRequest
                    failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest {
    
    serverPath = [serverPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    serverPath = [serverPath stringByAppendingString:k_url_acces_shared_api];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    
    [request shareByLinkFileOrFolderByServer:serverPath andPath:filePath onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        if (successRequest) {
            NSData *response = (NSData*) responseObject;
            //NSLog(@"response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
            OCXMLShareByLinkParser *parser = [[OCXMLShareByLinkParser alloc]init];
        
           // NSLog(@"response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
            
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
                        successRequest(operation.response, token, operation.redirectedServer);
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

- (void) unShareFileOrFolderByServer: (NSString *) path andIdRemoteShared: (int) idRemoteSared
                   onCommunication:(OCCommunication *)sharedOCCommunication
                    successRequest:(void(^)(NSHTTPURLResponse *, NSString *)) successRequest
                    failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest {
    
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    path = [path stringByAppendingString:k_url_acces_shared_api];
    path = [path stringByAppendingString:[NSString stringWithFormat:@"/%d",idRemoteSared]];
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [self getRequestWithCredentials:request];
    
    [request unShareFileOrFolderByServer:path onCommunication:sharedOCCommunication success:^(OCHTTPRequestOperation *operation, id responseObject) {
        if (successRequest) {
            
            //Return success
            successRequest(operation.response, operation.redirectedServer);
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
    [self clearCookiesFromURL:operation.request.URL];
    
    NSArray *operationArray = [_networkOperationsQueue operations];
    
    //NSLog(@"operations array has: %d operations", operationArray.count);
    //NSLog(@"current operation description: %@", operation.description);
    
    OCHTTPRequestOperation *lastOperationDownload;
    OCHTTPRequestOperation *lastOperationUpload;
    OCHTTPRequestOperation *lastOperationNavigation;
    
    //We get the last operation for each type
    for (int i = 0 ; i < [operationArray count] ; i++) {
        OCHTTPRequestOperation *currentOperation = [operationArray objectAtIndex:i];
        
        
        switch (operation.typeOfOperation) {
            case DownloadQueue:
                if(currentOperation.typeOfOperation == DownloadQueue) {
                    lastOperationDownload = currentOperation;
                }
                break;
            case UploadQueue:
                if(currentOperation.typeOfOperation == UploadQueue) {
                    lastOperationUpload = currentOperation;
                }
                break;
            case NavigationQueue:
                if(currentOperation.typeOfOperation == NavigationQueue) {
                    lastOperationNavigation = currentOperation;
                }
                break;
                
            default:
                break;
        }
    }
    
    //We add the dependency
    switch (operation.typeOfOperation) {
        case DownloadQueue:
            if(lastOperationDownload) {
                [operation addDependency:lastOperationDownload];
            }
            break;
        case UploadQueue:
            if(lastOperationUpload) {
                [operation addDependency:lastOperationUpload];
            }
            break;
        case NavigationQueue:
            if(lastOperationNavigation) {
                [operation addDependency:lastOperationNavigation];
            }
            break;
            
        default:
            break;
    }
    
    //Finally we add the new operation to the queue
    [self.networkOperationsQueue addOperation:operation];
    
}

#pragma mark - Clear Cookies and Cache

- (void)clearCookiesFromURL:(NSURL*) url {
    
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [cookieStorage cookiesForURL:url];
    for (NSHTTPCookie *cookie in cookies)
    {
        //NSLog(@"Delete cookie");
        [cookieStorage deleteCookie:cookie];
    }
}

- (void)eraseURLCache
{
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
}

@end
