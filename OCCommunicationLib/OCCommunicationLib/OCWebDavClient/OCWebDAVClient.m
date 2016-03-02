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
#import "NSString+Encode.h"
#import "OCConstants.h"

#define k_api_user_url_xml @"index.php/ocs/cloud/user"
#define k_api_user_url_json @"index.php/ocs/cloud/user?format=json"
#define k_server_information_json @"status.php"
#define k_api_header_request @"OCS-APIREQUEST"
#define k_group_sharee_type 1


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

- (void)setAuthorizationHeaderWithUsername:(NSString *)username password:(NSString *)password {
	NSString *basicAuthCredentials = [NSString stringWithFormat:@"%@:%@", username, password];
    
    [self setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Basic %@", [UtilsFramework AFBase64EncodedStringFromString: basicAuthCredentials]]];
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

- (void)setUserAgent:(NSString *)userAgent{
    
    [[self requestSerializer] setValue:userAgent forHTTPHeaderField:@"User-Agent"];
}

- (OCHTTPRequestOperation *)mr_operationWithRequest:(NSMutableURLRequest *)request onCommunication:(OCCommunication *)sharedOCCommunication withUserSessionToken:(NSString*)token success:(void(^)(OCHTTPRequestOperation *operation, id response, NSString *token))success failure:(void(^)(OCHTTPRequestOperation *operation, NSError *error, NSString *token))failure {
    
    //If is not nil is a redirection so we keep the original url server
    if (!_originalUrlServer) {
        _originalUrlServer = [request.URL absoluteString];
    }
    
    if (sharedOCCommunication.isCookiesAvailable) {
        //We add the cookies of that URL
        request = [UtilsFramework getRequestWithCookiesByRequest:request andOriginalUrlServer:_originalUrlServer];
    } else {
        [UtilsFramework deleteAllCookies];
    }
    
    OCHTTPRequestOperation *operation = [[OCHTTPRequestOperation alloc]initWithRequest:request];
    operation.securityPolicy = self.securityPolicy;
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        success((OCHTTPRequestOperation*)operation,responseObject, token);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure((OCHTTPRequestOperation*)operation, error, token);
    }];
    
    return operation;
    
}

- (OCHTTPRequestOperation *)mr_operationWithRequest:(NSMutableURLRequest *)request onCommunication:(OCCommunication *)sharedOCCommunication success:(void(^)(OCHTTPRequestOperation *, id))success failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    
    //If is not nil is a redirection so we keep the original url server
    if (!_originalUrlServer) {
        _originalUrlServer = [request.URL absoluteString];
    }
    
    if (sharedOCCommunication.isCookiesAvailable) {
        //We add the cookies of that URL
        request = [UtilsFramework getRequestWithCookiesByRequest:request andOriginalUrlServer:_originalUrlServer];
    } else {
        [UtilsFramework deleteAllCookies];
    }
    
    OCHTTPRequestOperation *operation = [[OCHTTPRequestOperation alloc]initWithRequest:request];
    operation.securityPolicy = self.securityPolicy;
    
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
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
    
    return request;
}

- (void)copyPath:(NSString *)source toPath:(NSString *)destination
 onCommunication:(OCCommunication *)sharedOCCommunication
         success:(void(^)(OCHTTPRequestOperation *, id))success
         failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    NSString *destinationPath = [NSString stringWithFormat:@"%@%@",[self.baseURL absoluteString], destination];
    _requestMethod = @"COPY";
    
    NSMutableURLRequest *request = [self requestWithMethod:_requestMethod path:source parameters:nil];
    [request setValue:destinationPath forHTTPHeaderField:@"Destination"];
	[request setValue:@"T" forHTTPHeaderField:@"Overwrite"];
	OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication success:success failure:failure];
    
    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
    
}

- (void)movePath:(NSString *)source toPath:(NSString *)destination
 onCommunication:(OCCommunication *)sharedOCCommunication
         success:(void(^)(OCHTTPRequestOperation *, id))success
         failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    NSString *destinationPath = [NSString stringWithFormat:@"%@%@",[self.baseURL absoluteString], destination];
    _requestMethod = @"MOVE";
    NSMutableURLRequest *request = [self requestWithMethod:_requestMethod path:source parameters:nil];
    [request setValue:destinationPath forHTTPHeaderField:@"Destination"];
	[request setValue:@"T" forHTTPHeaderField:@"Overwrite"];
	OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication success:success failure:failure];
    
    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
}

- (void)deletePath:(NSString *)path
   onCommunication:(OCCommunication *)sharedOCCommunication
           success:(void(^)(OCHTTPRequestOperation *, id))success
           failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    
    _requestMethod = @"DELETE";
    NSMutableURLRequest *request = [self requestWithMethod:_requestMethod path:path parameters:nil];
	OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication success:success failure:failure];
    
    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
    
}


- (void)mr_listPath:(NSString *)path depth:(NSUInteger)depth onCommunication:
(OCCommunication *)sharedOCCommunication
            success:(void(^)(OCHTTPRequestOperation *, id))success
            failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
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
    
    
    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication success:success failure:failure];
    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
}

- (void)mr_listPath:(NSString *)path depth:(NSUInteger)depth withUserSessionToken:(NSString*)token onCommunication:
(OCCommunication *)sharedOCCommunication
            success:(void(^)(OCHTTPRequestOperation *operation, id response, NSString *token))success
            failure:(void(^)(OCHTTPRequestOperation *, NSError *, NSString *token))failure {
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
    
    
    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication withUserSessionToken:token success:success failure:failure];

    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    
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

- (void)listPath:(NSString *)path
 onCommunication:(OCCommunication *)sharedOCCommunication withUserSessionToken:(NSString *)token
         success:(void(^)(OCHTTPRequestOperation *, id, NSString *token))success
         failure:(void(^)(OCHTTPRequestOperation *, NSError *, NSString *token))failure {
    [self mr_listPath:path depth:1 withUserSessionToken:token onCommunication:sharedOCCommunication success:success failure:failure];
}


- (NSOperation *)downloadPath:(NSString *)remoteSource toPath:(NSString *)localDestination withLIFOSystem:(BOOL)isLIFO onCommunication:(OCCommunication *)sharedOCCommunication progress:(void(^)(NSUInteger, long long, long long))progress success:(void(^)(OCHTTPRequestOperation *, id))success failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure shouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    
    //NSLog(@"Local destination path: %@", localDestination);
    
    //Create GET request for download
    _requestMethod = @"GET";
	NSMutableURLRequest *request = [self requestWithMethod:_requestMethod path:remoteSource parameters:nil];
    //Create Operation
	OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication success:success failure:failure];
    
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
        operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    } else {
        [operation setTypeOfOperation:DownloadFIFOQueue];
        operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    }
    
    //Add operation to network queue
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
    
    return operation;
}


- (NSURLSessionDownloadTask *)downloadWithSessionPath:(NSString *)remoteSource toPath:(NSString *)localDestination defaultPriority:(BOOL)defaultPriority onCommunication:(OCCommunication *)sharedOCCommunication withProgress:(NSProgress * __autoreleasing *) progressValue success:(void(^)(NSURLResponse *response, NSURL *filePath))success failure:(void(^)(NSURLResponse *response, NSError *error))failure{
    
    NSLog(@"localSource: %@", remoteSource);
    NSLog(@"remoteDestination: %@", localDestination);
   
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" path:remoteSource parameters:nil];
    
    //If is not nil is a redirection so we keep the original url server
    if (!_originalUrlServer) {
        _originalUrlServer = [request.URL absoluteString];
    }
    
    //We add the cookies of that URL
    request = [UtilsFramework getRequestWithCookiesByRequest:request andOriginalUrlServer:_originalUrlServer];
    
    NSURL *localDestinationUrl = [NSURL fileURLWithPath:localDestination];

   
    NSURLSessionDownloadTask *downloadTask = [sharedOCCommunication.downloadSessionManager downloadTaskWithRequest:request progress:progressValue destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
    
        return localDestinationUrl;
        
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
       
        if (error) {
            NSLog(@"Error: %@", error);
            failure(response, error);
        } else {
            NSLog(@"Success: %@ %@", response, filePath.absoluteString);
            success(response,filePath);
        }
        
    }];
    
    
    if (defaultPriority) {
         [downloadTask resume];
    }
    
    return downloadTask;


}

- (void)checkServer:(NSString *)path onCommunication:
(OCCommunication *)sharedOCCommunication
               success:(void(^)(OCHTTPRequestOperation *, id))success
               failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    _requestMethod = @"HEAD";
    NSMutableURLRequest *request = [self requestWithMethod:_requestMethod path:path parameters:nil];
    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication success:success failure:failure];
    
    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
}

- (void)makeCollection:(NSString *)path onCommunication:
(OCCommunication *)sharedOCCommunication
               success:(void(^)(OCHTTPRequestOperation *, id))success
               failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    _requestMethod = @"MKCOL";
	NSMutableURLRequest *request = [self requestWithMethod:_requestMethod path:path parameters:nil];
    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication success:success failure:failure];
    
    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
}

- (NSOperation *)putLocalPath:(NSString *)localSource atRemotePath:(NSString *)remoteDestination onCommunication:(OCCommunication *)sharedOCCommunication   progress:(void(^)(NSUInteger, long long))progress success:(void(^)(OCHTTPRequestOperation *, id))success failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure forceCredentialsFailure:(void(^)(NSHTTPURLResponse *, NSError *))forceCredentialsFailure shouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    
    
    NSLog(@"localSource: %@", localSource);
    NSLog(@"remoteDestination: %@", remoteDestination);
    
    _requestMethod = @"PUT";
    
    NSMutableURLRequest *request = [self requestWithMethod:_requestMethod path:remoteDestination parameters:nil];
    [request setTimeoutInterval:k_timeout_upload];
    [request setValue:[NSString stringWithFormat:@"%lld", [UtilsFramework getSizeInBytesByPath:localSource]] forHTTPHeaderField:@"Content-Length"];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPBodyStream:[NSInputStream inputStreamWithFileAtPath:localSource]];
    //[request setHTTPBody:[NSData dataWithContentsOfFile:localSource]];
    
	__weak __block OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication success:success failure:failure];
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
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
    
    return operation;
}


- (NSURLSessionUploadTask *)putWithSessionLocalPath:(NSString *)localSource atRemotePath:(NSString *)remoteDestination onCommunication:(OCCommunication *)sharedOCCommunication withProgress:(NSProgress * __autoreleasing *) progressValue success:(void(^)(NSURLResponse *, NSString *))success failure:(void(^)(NSURLResponse *, id, NSError *))failure failureBeforeRequest:(void(^)(NSError *)) failureBeforeRequest {
    
    
    NSLog(@"localSource: %@", localSource);
    NSLog(@"remoteDestination: %@", remoteDestination);
    
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
        if (!_originalUrlServer) {
            _originalUrlServer = [request.URL absoluteString];
        }
        
        if (sharedOCCommunication.isCookiesAvailable) {
            //We add the cookies of that URL
            request = [UtilsFramework getRequestWithCookiesByRequest:request andOriginalUrlServer:_originalUrlServer];
        } else {
            [UtilsFramework deleteAllCookies];
        }
        
        NSURL *file = [NSURL fileURLWithPath:localSource];
        
        sharedOCCommunication.uploadSessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        NSURLSessionUploadTask *uploadTask = [sharedOCCommunication.uploadSessionManager uploadTaskWithRequest:request fromFile:file progress:progressValue
                                                                                             completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                                                                                 if (error) {
                                                                                                     NSLog(@"Error: %@", error);
                                                                                                     failure(response, responseObject, error);
                                                                                                 } else {
                                                                                                     NSLog(@"Success: %@ %@", response, responseObject);
                                                                                                     success(response,responseObject);
                                                                                                 }
                                                                                             }];
        
        
        [uploadTask resume];
        
        return uploadTask;
    }
}

- (NSOperation *)putChunk:(OCChunkDto *) currentChunkDto fromInputStream:(OCChunkInputStream *)chunkInputStream andInputStreamForRedirection:(OCChunkInputStream *) chunkInputStreamForRedirection atRemotePath:(NSString *)remoteDestination onCommunication:(OCCommunication *)sharedOCCommunication  progress:(void(^)(NSUInteger, long long))progress success:(void(^)(OCHTTPRequestOperation *, id))success failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure forceCredentialsFailure:(void(^)(NSHTTPURLResponse *, NSError *))forceCredentialsFailure shouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    
    _requestMethod = @"PUT";
    
    NSMutableURLRequest *request = [self requestWithMethod:_requestMethod path:remoteDestination parameters:nil];
    [request setTimeoutInterval:k_timeout_upload];
    [request setValue:[NSString stringWithFormat:@"%lld", [currentChunkDto.size longLongValue]] forHTTPHeaderField:@"Content-Length"];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request addValue:@"1" forHTTPHeaderField:@"oc-chunked"];
    [request setHTTPBodyStream:chunkInputStream];
    //[request setHTTPBody:data];
    
	__weak __block OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication success:success failure:failure];
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
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
    
    return operation;
    
}


- (void) requestUserNameByCookie:(NSString *) cookieString onCommunication:
(OCCommunication *)sharedOCCommunication success:(void(^)(OCHTTPRequestOperation *, id))success
                         failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    NSString *apiUserUrl = nil;
    apiUserUrl = [NSString stringWithFormat:@"%@%@", self.baseURL, k_api_user_url_json];
    
    NSLog(@"api user name call: %@", apiUserUrl);
    
    _requestMethod = @"GET";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path: apiUserUrl parameters: nil];
	[request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    
    
    
    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication success:success failure:failure];
    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
}

- (void) getStatusOfTheServer:(NSString *)serverPath onCommunication:
(OCCommunication *)sharedOCCommunication success:(void(^)(OCHTTPRequestOperation *operation, id responseObject))success
                            failure:(void(^)(OCHTTPRequestOperation *operation, NSError *error))failure  {
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@", serverPath, k_server_information_json];
    
    _requestMethod = @"GET";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path: urlString parameters: nil];

    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication success:success failure:failure];
    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
    
}

- (void)listSharedByServer:(NSString *)serverPath
 onCommunication:(OCCommunication *)sharedOCCommunication
         success:(void(^)(OCHTTPRequestOperation *, id))success
         failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    
    NSParameterAssert(success);
    
    _requestMethod = @"GET";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    
    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication success:success failure:failure];
    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
    
}

- (void)listSharedByServer:(NSString *)serverPath andPath:(NSString *) path
           onCommunication:(OCCommunication *)sharedOCCommunication
                   success:(void(^)(OCHTTPRequestOperation *, id))success
                   failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    
    NSParameterAssert(success);
	
    NSString *postString = [NSString stringWithFormat: @"?path=%@&subfiles=true",path];
    serverPath = [serverPath stringByAppendingString:postString];
    _requestMethod = @"GET";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    
    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication success:success failure:failure];
    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
    
}

- (void)shareByLinkFileOrFolderByServer:(NSString *)serverPath andPath:(NSString *) filePath andPassword:(NSString *)password
                        onCommunication:(OCCommunication *)sharedOCCommunication
                                success:(void(^)(OCHTTPRequestOperation *, id))success
                                failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    NSParameterAssert(success);
    
    _requestMethod = @"POST";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    _postStringForShare = [NSString stringWithFormat: @"path=%@&shareType=3&password=%@",filePath,password];
    [request setHTTPBody:[_postStringForShare dataUsingEncoding:NSUTF8StringEncoding]];
    
    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication success:success failure:failure];
    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
}

- (void)shareByLinkFileOrFolderByServer:(NSString *)serverPath andPath:(NSString *) filePath
                  onCommunication:(OCCommunication *)sharedOCCommunication
                          success:(void(^)(OCHTTPRequestOperation *, id))success
                          failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    NSParameterAssert(success);
    
    _requestMethod = @"POST";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    _postStringForShare = [NSString stringWithFormat: @"path=%@&shareType=3",filePath];
    [request setHTTPBody:[_postStringForShare dataUsingEncoding:NSUTF8StringEncoding]];
    
    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication success:success failure:failure];
    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
}

- (void)shareWith:(NSString *)userOrGroup shareeType:(NSInteger)shareeType inServer:(NSString *) serverPath andPath:(NSString *) filePath andPermissions:(NSInteger) permissions onCommunication:(OCCommunication *)sharedOCCommunication
                                success:(void(^)(OCHTTPRequestOperation *, id))success
                                failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    NSParameterAssert(success);
    
    _requestMethod = @"POST";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    
    self.postStringForShare = [NSString stringWithFormat: @"path=%@&shareType=%ld&shareWith=%@&permissions=%ld",filePath, (long)shareeType, userOrGroup, (long)permissions];
    [request setHTTPBody:[_postStringForShare dataUsingEncoding:NSUTF8StringEncoding]];
    
    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication success:success failure:failure];
    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
}


- (void)unShareFileOrFolderByServer:(NSString *)serverPath
                        onCommunication:(OCCommunication *)sharedOCCommunication
                                success:(void(^)(OCHTTPRequestOperation *, id))success
                                failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    NSParameterAssert(success);
    
    _requestMethod = @"DELETE";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    
    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication success:success failure:failure];
    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
}


- (void)isShareFileOrFolderByServer:(NSString *)serverPath
                    onCommunication:(OCCommunication *)sharedOCCommunication
                            success:(void(^)(OCHTTPRequestOperation *, id))success
                            failure:(void(^)(OCHTTPRequestOperation *, NSError *))failure {
    NSParameterAssert(success);
    
    _requestMethod = @"GET";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    
    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication success:success failure:failure];
    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
        
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
}

- (void) updateShareItem:(NSInteger)shareId ofServerPath:(NSString*)serverPath withPasswordProtect:(NSString*)password andExpirationTime:(NSString*)expirationTime andPermissions:(NSInteger)permissions
         onCommunication:(OCCommunication *)sharedOCCommunication
                 success:(void(^)(OCHTTPRequestOperation *operation, id response))success
                 failure:(void(^)(OCHTTPRequestOperation *operation, NSError *error))failure{
    
    NSParameterAssert(success);
    
    _requestMethod = @"PUT";
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    
    if (password) {
        self.postStringForShare = [NSString stringWithFormat:@"password=%@",password];
    } else if (expirationTime) {
        self.postStringForShare = [NSString stringWithFormat:@"expireDate=%@",expirationTime];
    }else if (permissions > 0) {
        self.postStringForShare = [NSString stringWithFormat:@"permissions=%ld",(long)permissions];
    }
    
    [request setHTTPBody:[_postStringForShare dataUsingEncoding:NSUTF8StringEncoding]];
    
    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCCommunication success:success failure:failure];
    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCCommunication];
    
    [sharedOCCommunication addOperationToTheNetworkQueue:operation];
    
}

- (void) searchUsersAndGroupsWith:(NSString *)searchString forPage:(NSInteger)page with:(NSInteger)resultsPerPage ofServer:(NSString*)serverPath onCommunication:(OCCommunication *)sharedOCComunication success:(void(^)(OCHTTPRequestOperation *operation, id response))success
    failure:(void(^)(OCHTTPRequestOperation *operation, NSError *error))failure {
    
    NSParameterAssert(success);
    
    _requestMethod = @"GET";
    
    NSString *searchQuery = [NSString stringWithFormat: @"&search=%@",searchString];
    NSString *jsonQuery = [NSString stringWithFormat:@"?format=json"];
    NSString *queryType = [NSString stringWithFormat:@"&itemType=search"];
    NSString *pagination = [NSString stringWithFormat:@"&page=%ld&perPage=%ld", (long)page, (long)resultsPerPage];
    serverPath = [serverPath stringByAppendingString:jsonQuery];
    serverPath = [serverPath stringByAppendingString:queryType];
    serverPath = [serverPath stringByAppendingString:searchQuery];
    serverPath = [serverPath stringByAppendingString:pagination];

    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    
    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCComunication success:success failure:failure];
    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCComunication];
    
    [sharedOCComunication addOperationToTheNetworkQueue:operation];
    
    
}

- (void) getCapabilitiesOfServer:(NSString*)serverPath onCommunication:(OCCommunication *)sharedOCComunication success:(void(^)(OCHTTPRequestOperation *operation, id response))success
                         failure:(void(^)(OCHTTPRequestOperation *operation, NSError *error))failure{
    _requestMethod = @"GET";
    
    NSString *jsonQuery = [NSString stringWithFormat:@"?format=json"];
    serverPath = [serverPath stringByAppendingString:jsonQuery];
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    
    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCComunication success:success failure:failure];
    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCComunication];
    
    [sharedOCComunication addOperationToTheNetworkQueue:operation];

    
}


#pragma mark - Remote thumbnails

- (void) getRemoteThumbnailByServer:(NSString*)serverPath ofFilePath:(NSString*)filePath  withWidth:(NSInteger)fileWidth andHeight:(NSInteger)fileHeight onCommunication:(OCCommunication *)sharedOCComunication
                            success:(void(^)(OCHTTPRequestOperation *operation, id response))success
                            failure:(void(^)(OCHTTPRequestOperation *operation, NSError *error))failure{
    _requestMethod = @"GET";
    
//    NSString *jsonQuery = [NSString stringWithFormat:@"?format=json"];
//    serverPath = [serverPath stringByAppendingString:jsonQuery];
    //TOODO encode filepath
    
    NSString *query = [NSString stringWithFormat:@"/%i/%i/%@", (int)fileWidth, (int)fileHeight, filePath];
    serverPath = [serverPath stringByAppendingString:query];
    
    NSMutableURLRequest *request = [self sharedRequestWithMethod:_requestMethod path:serverPath parameters:nil];
    
    OCHTTPRequestOperation *operation = [self mr_operationWithRequest:request onCommunication:sharedOCComunication success:success failure:failure];
    [operation setTypeOfOperation:NavigationQueue];
    operation = [self setRedirectionBlockOnOperation:operation withOCCommunication:sharedOCComunication];
    
    [sharedOCComunication addOperationToTheNetworkQueue:operation];
    
    
}


#pragma mark - Manage Redirections

- (OCHTTPRequestOperation *) setRedirectionBlockOnOperation:(OCHTTPRequestOperation *) operation withOCCommunication: (OCCommunication *) sharedOCCommunication {
    
   __block OCHTTPRequestOperation *op = operation;
    
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) redirectResponse;
        NSDictionary *dict = [httpResponse allHeaderFields];
        //Server path of redirected server
        NSString *responseURLString = [dict objectForKey:@"Location"];
        
        if (responseURLString) {
            
           // NSLog(@"responseURLString: %@", responseURLString);
           // NSLog(@"requestRedirect.HTTPMethod: %@", request.HTTPMethod);
            
            if ([UtilsFramework isURLWithSamlFragment:responseURLString] || httpResponse.statusCode == k_redirected_code_1) {
                //We set the redirectedServer in case SAML or is a permanent redirection
                self.redirectedServer = responseURLString;
            }
            
            NSMutableURLRequest *requestRedirect = [request mutableCopy];
            [requestRedirect setURL: [NSURL URLWithString:responseURLString]];
            
            //Set the URL into the request
            if (op.localSource) {
                //Only for uploads without chunks
                [requestRedirect setHTTPBodyStream:[NSInputStream inputStreamWithFileAtPath:op.localSource]];
            } else if (op.chunkInputStream) {
                //Only for uploads with chunks
                [requestRedirect setHTTPBodyStream:op.chunkInputStream];
            }
            
            requestRedirect = [sharedOCCommunication getRequestWithCredentials:requestRedirect];
            requestRedirect.HTTPMethod = _requestMethod;
            
            if (_postStringForShare) {
                //It is a request to share a file by link
                requestRedirect = [self sharedRequestWithMethod:_requestMethod path:responseURLString parameters:nil];
                [requestRedirect setHTTPBody:[_postStringForShare dataUsingEncoding:NSUTF8StringEncoding]];
            }
            
            if (sharedOCCommunication.isCookiesAvailable) {
                //We add the cookies of that URL
                request = [UtilsFramework getRequestWithCookiesByRequest:requestRedirect andOriginalUrlServer:_originalUrlServer];
            } else {
                [UtilsFramework deleteAllCookies];
            }
            return requestRedirect;
            
        } else {
            return request;
        }
    }];
    
    return operation;
}

@end
