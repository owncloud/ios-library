//
//  OCWebDAVClient.m
//  OCWebDAVClient
//
//  This class is based in https://github.com/zwaldowski/DZWebDAVClient. Copyright (c) 2012 Zachary Waldowski, Troy Brant, Marcus Rohrmoser, and Sam Soffes.
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


#import "OCWebDAVClient.h"
#import "OCFrameworkConstants.h"
#import "OCCommunication.h"
#import "OCChunkDto.h"
#import "OCChunkInputStream.h"
#import "UtilsFramework.h"
#import "AFURLSessionManager.h"

#define k_api_user_url_xml @"index.php/ocs/cloud/user"
#define k_api_user_url_json @"index.php/ocs/cloud/user?format=json"
#define k_server_information_json @"status.php"
#define k_api_header_request @"OCS-APIREQUEST"


NSString const *OCWebDAVContentTypeKey		= @"getcontenttype";
NSString const *OCWebDAVETagKey				= @"getetag";
NSString const *OCWebDAVCTagKey				= @"getctag";
NSString const *OCWebDAVCreationDateKey		= @"creationdate";
NSString const *OCWebDAVModificationDateKey	= @"modificationdate";

@interface OCWebDAVClient()

- (void)mr_listPath:(NSString *)path depth:(NSUInteger)depth onCommunication:
(OCCommunication *)sharedOCCommunication
            success:(void(^)(OCHTTPRequestOperation *, id))success
            failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure;

@end

@implementation OCWebDAVClient


- (id)initWithBaseURL:(NSURL *)url {
    if ((self = [super initWithBaseURL:url])) {
        
        
    }
    return self;
}

static NSString * AFBase64EncodedStringFromString(NSString *string) {
    NSData *data = [NSData dataWithBytes:[string UTF8String] length:[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    NSUInteger length = [data length];
    NSMutableData *mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    
    uint8_t *input = (uint8_t *)[data bytes];
    uint8_t *output = (uint8_t *)[mutableData mutableBytes];
    
    for (NSUInteger i = 0; i < length; i += 3) {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        static uint8_t const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        
        NSUInteger idx = (i / 3) * 4;
        output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kAFBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kAFBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
}

- (void)setAuthorizationHeaderWithUsername:(NSString *)username password:(NSString *)password {
	NSString *basicAuthCredentials = [NSString stringWithFormat:@"%@:%@", username, password];
    
    [self setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Basic %@", AFBase64EncodedStringFromString(basicAuthCredentials)]];
}

- (void)setAuthorizationHeaderWithCookie:(NSString *) cookieString {
    [self setDefaultHeader:@"Cookie" value:cookieString];
}

- (void)setAuthorizationHeaderWithToken:(NSString *)token {
    // [self setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Token token=\"%@\"", token]];
    [self setDefaultHeader:@"Authorization" value:token];
    
}

- (void)setDefaultHeader:(NSString *)header value:(NSString *)value {
    
    [[self requestSerializer] setValue:value forHTTPHeaderField:header];
}


- (OCHTTPRequestOperation *)mr_operationWithRequest:(NSURLRequest *)request success:(void(^)(OCHTTPRequestOperation *, id))success failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    
    OCHTTPRequestOperation *operation = [[OCHTTPRequestOperation alloc]initWithRequest:request];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        success((OCHTTPRequestOperation*)operation,responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure((OCHTTPRequestOperation*)operation, error);
    }];
    
    return operation;
    
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters {
    
    NSMutableURLRequest *request = [[self requestSerializer] requestWithMethod:method URLString:path parameters:parameters error:nil];
    
    [request setCachePolicy: NSURLRequestReloadIgnoringLocalCacheData];
    [request setTimeoutInterval: k_timeout_webdav];
    
    return request;
}

- (NSMutableURLRequest *)sharedRequestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters {
    
    NSMutableURLRequest *request = [[self requestSerializer] requestWithMethod:method URLString:path parameters:parameters error:nil];
    
    //NSMutableURLRequest *request = [super requestWithMethod:method path:path parameters:parameters];
    [request setCachePolicy: NSURLRequestReloadIgnoringLocalCacheData];
    [request setTimeoutInterval: k_timeout_webdav];
    //Header for use the OC API CALL
    NSString *ocs_apiquests = @"true";
    [request setValue:ocs_apiquests forHTTPHeaderField:k_api_header_request];
    
    return request;
}

- (void)copyPath:(NSString *)source toPath:(NSString *)destination
 onCommunication:(OCCommunication *)sharedOCCommunication
         success:(void(^)(OCHTTPRequestOperation *, id))success
         failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    NSString *destinationPath = [NSString stringWithFormat:@"%@%@",[self.baseURL absoluteString], destination];
    NSMutableURLRequest *request = [self requestWithMethod:@"COPY" path:source parameters:nil];
    [request setValue:destinationPath forHTTPHeaderField:@"Destination"];
	[request setValue:@"T" forHTTPHeaderField:@"Overwrite"];
	OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request success:success failure:failure];
    
    [operation setTypeOfOperation:NavigationQueue];
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
    
}

- (void)movePath:(NSString *)source toPath:(NSString *)destination
 onCommunication:(OCCommunication *)sharedOCCommunication
         success:(void(^)(OCHTTPRequestOperation *, id))success
         failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    NSString *destinationPath = [NSString stringWithFormat:@"%@%@",[self.baseURL absoluteString], destination];
    NSMutableURLRequest *request = [self requestWithMethod:@"MOVE" path:source parameters:nil];
    [request setValue:destinationPath forHTTPHeaderField:@"Destination"];
	[request setValue:@"T" forHTTPHeaderField:@"Overwrite"];
	OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request success:success failure:failure];
    
    [operation setTypeOfOperation:NavigationQueue];
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
}

- (void)deletePath:(NSString *)path
   onCommunication:(OCCommunication *)sharedOCCommunication
           success:(void(^)(OCHTTPRequestOperation *, id))success
           failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    NSMutableURLRequest *request = [self requestWithMethod:@"DELETE" path:path parameters:nil];
	OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request success:success failure:failure];
    
    [operation setTypeOfOperation:NavigationQueue];
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
    
}


- (void)mr_listPath:(NSString *)path depth:(NSUInteger)depth onCommunication:
(OCCommunication *)sharedOCCommunication
            success:(void(^)(OCHTTPRequestOperation *, id))success
            failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
	NSParameterAssert(success);
	NSMutableURLRequest *request = [self requestWithMethod:@"PROPFIND" path:path parameters:nil];
	NSString *depthHeader = nil;
	if (depth <= 0)
		depthHeader = @"0";
	else if (depth == 1)
		depthHeader = @"1";
	else
		depthHeader = @"infinity";
    [request setValue: depthHeader forHTTPHeaderField: @"Depth"];
    
    [request setHTTPBody:[@"<?xml version=\"1.0\" encoding=\"utf-8\" ?><D:propfind xmlns:D=\"DAV:\"><D:allprop/></D:propfind>" dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    
    
    OCHTTPRequestOperation *operation = [[OCHTTPRequestOperation alloc]initWithRequest:request];
    [operation setTypeOfOperation:NavigationQueue];
    
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        success((OCHTTPRequestOperation*)operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure((OCHTTPRequestOperation*)operation, operation.error);
    }];
    
    
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
    
}

- (void)propertiesOfPath:(NSString *)path
         onCommunication: (OCCommunication *)sharedOCCommunication
                 success:(void(^)(OCHTTPRequestOperation *, id ))success
                 failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
	[self mr_listPath:path depth:0 onCommunication:sharedOCCommunication success:success failure:failure];
}

- (void)listPath:(NSString *)path
 onCommunication:(OCCommunication *)sharedOCCommunication
         success:(void(^)(OCHTTPRequestOperation *, id))success
         failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
	[self mr_listPath:path depth:1 onCommunication:sharedOCCommunication success:success failure:failure];
}


- (NSOperation *)downloadPath:(NSString *)remoteSource toPath:(NSString *)localDestination withLIFOSystem:(BOOL)isLIFO onCommunication:(OCCommunication *)sharedOCCommunication progress:(void(^)(NSUInteger, long long, long long))progress success:(void(^)(OCHTTPRequestOperation *, id))success failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure shouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    
    //NSLog(@"Local destination path: %@", localDestination);
    
    //Create GET request for download
	NSMutableURLRequest *request = [self requestWithMethod:@"GET" path:remoteSource parameters:nil];
    //Create Operation
	OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request success:success failure:failure];
    
    //Progress block
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        
        NSLog(@"bytes read are: %lld of total bytes are: %lld", totalBytesRead, totalBytesExpectedToRead);
        
        progress(bytesRead, totalBytesRead, totalBytesExpectedToRead);
        
    }];
    
    //Execute task when backgroun expired
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        handler();
    }];
    
	operation.outputStream = [NSOutputStream outputStreamToFileAtPath:localDestination append:NO];
    
    //Set type download operation
    if (isLIFO) {
        [operation setTypeOfOperation:DownloadLIFOQueue];
    } else {
        [operation setTypeOfOperation:DownloadFIFOQueue];
    }
    
    //Add operation to network queue
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
    
    return operation;
}

- (void)makeCollection:(NSString *)path onCommunication:
(OCCommunication *)sharedOCCommunication
               success:(void(^)(OCHTTPRequestOperation *, id))success
               failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
	NSURLRequest *request = [self requestWithMethod:@"MKCOL" path:path parameters:nil];
    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request success:success failure:failure];
    
    [operation setTypeOfOperation:NavigationQueue];
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
}

- (void)put:(NSData *)data path:(NSString *)remoteDestination success:(void(^)(OCHTTPRequestOperation *, id))success
    failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    NSMutableURLRequest *request = [self requestWithMethod:@"PUT" path:remoteDestination parameters:nil];
	[request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
	[request setValue:[NSString stringWithFormat:@"%d", data.length] forHTTPHeaderField:@"Content-Length"];
	OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request success:success failure:failure];
	operation.inputStream = [NSInputStream inputStreamWithData:data];
    //TODO:Uncomment this
    //[self enqueueHTTPRequestOperation:operation];
    [self.operationQueue addOperation:operation];
}


- (NSOperation *)putLocalPath:(NSString *)localSource atRemotePath:(NSString *)remoteDestination onCommunication:(OCCommunication *)sharedOCCommunication   progress:(void(^)(NSUInteger, long long))progress success:(void(^)(OCHTTPRequestOperation *, id))success failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure forceCredentialsFailure:(void(^)(NSHTTPURLResponse *, NSError *))forceCredentialsFailure shouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    
    
    NSLog(@"localSource: %@", localSource);
    NSLog(@"remoteDestination: %@", remoteDestination);
    
    NSMutableURLRequest *request = [self requestWithMethod:@"PUT" path:remoteDestination parameters:nil];
    [request setTimeoutInterval:k_timeout_upload];
    [request setValue:[NSString stringWithFormat:@"%lld", [UtilsFramework getSizeInBytesByPath:localSource]] forHTTPHeaderField:@"Content-Length"];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    [request setHTTPBodyStream:[NSInputStream inputStreamWithFileAtPath:localSource]];
    //[request setHTTPBody:[NSData dataWithContentsOfFile:localSource]];
    
	__weak __block OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request success:success failure:failure];
    operation.localSource = localSource;
    
    [operation setWillSendRequestForAuthenticationChallengeBlock:^(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge) {
        //Credential error
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"You have entered forbbiden characters" forKey:NSLocalizedDescriptionKey];
        
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:remoteDestination] statusCode:401 HTTPVersion: @"" headerFields:[request allHTTPHeaderFields]];
        
        NSError *error = [NSError errorWithDomain:k_domain_error_code code:401 userInfo:nil];
        forceCredentialsFailure(response, error);
    }];
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWrote, long long totalBytesWrote, long long totalBytesExpectedToWrote) {
        progress(bytesWrote, totalBytesWrote);
    }];
    
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        handler();
    }];
    
    [operation setTypeOfOperation:UploadQueue];
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
    
    return operation;
}


- (NSURLSessionUploadTask *)putWithSessionLocalPath:(NSString *)localSource atRemotePath:(NSString *)remoteDestination onCommunication:(OCCommunication *)sharedOCCommunication withProgress:(NSProgress * __autoreleasing *) progressValue success:(void(^)(NSURLResponse *, NSString *))success failure:(void(^)(NSURLResponse *, NSError *))failure{
    
    
    NSLog(@"localSource: %@", localSource);
    NSLog(@"remoteDestination: %@", remoteDestination);
    
    
    NSMutableURLRequest *request = [self requestWithMethod:@"PUT" path:remoteDestination parameters:nil];
    [request setTimeoutInterval:k_timeout_upload];
    [request setValue:[NSString stringWithFormat:@"%lld", [UtilsFramework getSizeInBytesByPath:localSource]] forHTTPHeaderField:@"Content-Length"];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    
    NSURL *file = [NSURL fileURLWithPath:localSource];
    
    NSURLSessionUploadTask *uploadTask = [sharedOCCommunication.uploadSessionManager uploadTaskWithRequest:request fromFile:file progress:progressValue
                                                                                         completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                                                                             if (error) {
                                                                                                 NSLog(@"Error: %@", error);
                                                                                                 failure(response, error);
                                                                                             } else {
                                                                                                 NSLog(@"Success: %@ %@", response, responseObject);
                                                                                                 success(response,responseObject);
                                                                                             }
                                                                                         }];
    
    
    [uploadTask resume];
    
    return uploadTask;
}

- (NSOperation *)putChunk:(OCChunkDto *) currentChunkDto fromInputStream:(OCChunkInputStream *)chunkInputStream andInputStreamForRedirection:(OCChunkInputStream *) chunkInputStreamForRedirection atRemotePath:(NSString *)remoteDestination onCommunication:(OCCommunication *)sharedOCCommunication  progress:(void(^)(NSUInteger, long long))progress success:(void(^)(OCHTTPRequestOperation *, id))success failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure forceCredentialsFailure:(void(^)(NSHTTPURLResponse *, NSError *))forceCredentialsFailure shouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    
    NSMutableURLRequest *request = [self requestWithMethod:@"PUT" path:remoteDestination parameters:nil];
    [request setTimeoutInterval:k_timeout_upload];
    [request setValue:[NSString stringWithFormat:@"%lld", [currentChunkDto.size longLongValue]] forHTTPHeaderField:@"Content-Length"];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    [request addValue:@"1" forHTTPHeaderField:@"oc-chunked"];
    [request setHTTPBodyStream:chunkInputStream];
    //[request setHTTPBody:data];
    
	__weak __block OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request success:success failure:failure];
    operation.chunkInputStream = chunkInputStreamForRedirection;
    
    [operation setWillSendRequestForAuthenticationChallengeBlock:^(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge) {
        //Credential error
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"You have entered forbbiden characters" forKey:NSLocalizedDescriptionKey];
        
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:remoteDestination] statusCode:401 HTTPVersion: @"" headerFields:[request allHTTPHeaderFields]];
        
        NSError *error = [NSError errorWithDomain:k_domain_error_code code:401 userInfo:nil];
        forceCredentialsFailure(response, error);
    }];
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWrote, long long totalBytesWrote, long long totalBytesExpectedToWrote) {
        progress(bytesWrote, totalBytesWrote);
    }];
    
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        handler();
    }];
    
    [operation setTypeOfOperation:UploadQueue];
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
    
    return operation;
    
}


- (void) requestUserNameByCookie:(NSString *) cookieString onCommunication:
(OCCommunication *)sharedOCCommunication success:(void(^)(OCHTTPRequestOperation *, id))success
                         failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    NSString *apiUserUrl = nil;
    apiUserUrl = [NSString stringWithFormat:@"%@%@", self.baseURL, k_api_user_url_json];
    
    NSLog(@"api user name call: %@", apiUserUrl);
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:@"GET" path: apiUserUrl parameters: nil];
	[request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    
    
    
    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request success:success failure:failure];
    [operation setTypeOfOperation:NavigationQueue];
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
}

- (void) getTheStatusOfTheServer:(NSString *)serverPath onCommunication:
(OCCommunication *)sharedOCCommunication success:(void(^)(OCHTTPRequestOperation *, id))success
                            failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure  {
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@", serverPath, k_server_information_json];
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:@"GET" path: urlString parameters: nil];

    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request success:success failure:failure];
    [operation setTypeOfOperation:NavigationQueue];
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
    
}

- (void)listSharedByServer:(NSString *)serverPath
 onCommunication:(OCCommunication *)sharedOCCommunication
         success:(void(^)(OCHTTPRequestOperation *, id))success
         failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    
    NSParameterAssert(success);
    NSMutableURLRequest *request = [self sharedRequestWithMethod:@"GET" path:serverPath parameters:nil];
    
    OCHTTPRequestOperation *operation = [[OCHTTPRequestOperation alloc]initWithRequest:request];
    [operation setTypeOfOperation:NavigationQueue];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        success((OCHTTPRequestOperation*)operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure((OCHTTPRequestOperation*)operation, operation.error);
    }];
    
    
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
    
}

- (void)listSharedByServer:(NSString *)serverPath andPath:(NSString *) path
           onCommunication:(OCCommunication *)sharedOCCommunication
                   success:(void(^)(OCHTTPRequestOperation *, id))success
                   failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    
    NSParameterAssert(success);
	
    NSString *postString = [NSString stringWithFormat: @"?path=%@&subfiles=true",path];
    serverPath = [[serverPath stringByAppendingString:postString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
     NSMutableURLRequest *request = [self sharedRequestWithMethod:@"GET" path:serverPath parameters:nil];
    
    OCHTTPRequestOperation *operation = [[OCHTTPRequestOperation alloc]initWithRequest:request];
    [operation setTypeOfOperation:NavigationQueue];
    
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        success((OCHTTPRequestOperation*)operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure((OCHTTPRequestOperation*)operation, operation.error);
    }];
    
    
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
    
}

- (void)shareByLinkFileOrFolderByServer:(NSString *)serverPath andPath:(NSString *) filePath
                  onCommunication:(OCCommunication *)sharedOCCommunication
                          success:(void(^)(OCHTTPRequestOperation *, id))success
                          failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    NSParameterAssert(success);
    NSMutableURLRequest *request = [self sharedRequestWithMethod:@"POST" path:serverPath parameters:nil];

    NSString *postString = [NSString stringWithFormat: @"path=%@&shareType=3",filePath];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    OCHTTPRequestOperation *operation = [[OCHTTPRequestOperation alloc]initWithRequest:request];
    [operation setTypeOfOperation:NavigationQueue];
    
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        success((OCHTTPRequestOperation*)operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure((OCHTTPRequestOperation*)operation, operation.error);
    }];
    
    
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
}

- (void)unShareFileOrFolderByServer:(NSString *)serverPath
                        onCommunication:(OCCommunication *)sharedOCCommunication
                                success:(void(^)(OCHTTPRequestOperation *, id))success
                                failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    NSParameterAssert(success);
    NSMutableURLRequest *request = [self sharedRequestWithMethod:@"DELETE" path:serverPath parameters:nil];
    
    OCHTTPRequestOperation *operation = [[OCHTTPRequestOperation alloc]initWithRequest:request];
    [operation setTypeOfOperation:NavigationQueue];
    
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        success((OCHTTPRequestOperation*)operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure((OCHTTPRequestOperation*)operation, operation.error);
    }];
    
    
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
}

- (void)isShareFileOrFolderByServer:(NSString *)serverPath
                    onCommunication:(OCCommunication *)sharedOCCommunication
                            success:(void(^)(OCHTTPRequestOperation *, id))success
                            failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    NSParameterAssert(success);
    NSMutableURLRequest *request = [self sharedRequestWithMethod:@"GET" path:serverPath parameters:nil];
    
    OCHTTPRequestOperation *operation = [[OCHTTPRequestOperation alloc]initWithRequest:request];
    [operation setTypeOfOperation:NavigationQueue];
    
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        success((OCHTTPRequestOperation*)operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure((OCHTTPRequestOperation*)operation, operation.error);
    }];
    
    
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
}

@end