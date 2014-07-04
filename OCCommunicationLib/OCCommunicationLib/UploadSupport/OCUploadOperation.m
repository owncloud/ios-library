//
//  OCUploadsWithChunksOperation.m
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


#import "OCUploadOperation.h"
#import "OCWebDavClient.h"
#import "OCCommunication.h"
#import "UtilsFramework.h"
#import "OCFrameworkConstants.h"
#import "OCChunkDto.h"
#import "OCChunkInputStream.h"

@implementation OCUploadOperation

///-----------------------------------
/// @name createOperationWith
///-----------------------------------

/**
 * Method to create a new Upload operation
 *
 * @param NSString -> localFilePath the path where is the file that we want upload
 * @param NSString -> remoteFilePath the path where we want upload the file
 * @param OCCommunication -> sharedOCCommunication the OCCommunication singleton that control all the communications
 *
 */
- (void) createOperationWith:(NSString *) localFilePath toDestiny:(NSString *) remoteFilePath onCommunication:(OCCommunication *)sharedOCCommunication progressUpload:(void(^)(NSUInteger, long long, long long))progressUpload successRequest:(void(^)(NSHTTPURLResponse *, NSString *redirectedServer)) successRequest failureRequest:(void(^)(NSHTTPURLResponse *, NSString *redirectedServer, NSError *)) failureRequest failureBeforeRequest:(void(^)(NSError *)) failureBeforeRequest shouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    
    OCWebDAVClient *request = [[OCWebDAVClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    request = [sharedOCCommunication getRequestWithCredentials:request];
    
    __block long long totalBytesExpectedToWrote = [UtilsFramework getSizeInBytesByPath:localFilePath];
    
    _listOfOperationsToUploadAFile = [NSMutableArray new];
    
    _chunkPositionUploading = 0;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //We check if the file exist
    if (![fileManager fileExistsAtPath:localFilePath]) {
        [self cancel];
        
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"You are trying upload a file that does not exist" forKey:NSLocalizedDescriptionKey];
        
        NSError *error = [NSError errorWithDomain:k_domain_error_code code:OCErrorFileToUploadDoesNotExist userInfo:details];
        
        failureBeforeRequest(error);
        
    } else {
        
        NSLog(@"Upload NO Chunks");
        
        [_listOfOperationsToUploadAFile addObject: [request putLocalPath:localFilePath atRemotePath:remoteFilePath onCommunication:sharedOCCommunication progress:^(NSUInteger bytesWrote, long long totalBytesWrote) {

            progressUpload(bytesWrote, totalBytesWrote, totalBytesExpectedToWrote);
        } success:^(OCHTTPRequestOperation *operation, id responseObject) {
            [UtilsFramework addCookiesToStorageFromResponse:operation.response andPath:[NSURL URLWithString:remoteFilePath]];
            [_listOfOperationsToUploadAFile removeObjectIdenticalTo:operation];
            successRequest(operation.response, request.redirectedServer);
        } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
            [UtilsFramework addCookiesToStorageFromResponse:operation.response andPath:[NSURL URLWithString:remoteFilePath]];
            [_listOfOperationsToUploadAFile removeObjectIdenticalTo:operation];
            [self cancel];
            NSLog(@"Error: %@", operation.response);
            failureRequest(operation.response, request.redirectedServer, error);
        } forceCredentialsFailure:^(NSHTTPURLResponse *response, NSError *error) {
            [self cancel];
            NSString *redServer = @"";
            failureRequest(response, redServer, error);
        } shouldExecuteAsBackgroundTaskWithExpirationHandler:^{
            [self cancel];
            handler();
        }]];
    }
}

///-----------------------------------
/// @name cancel
///-----------------------------------

/**
 * Method to cancel the current operation including all the chunks if them exist
 */
- (void) cancel {
    for (NSOperation *currentOperation in _listOfOperationsToUploadAFile) {
        [currentOperation cancel];
    }
}

@end
