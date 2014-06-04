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
        
    } else if ([UtilsFramework getSizeInBytesByPath:localFilePath] > k_OC_lenght_chunk) {
    //} else if (NO) { //Force not use chunks
        //The file have to be divided in chunks
        
        NSLog(@"Upload With Chunks");
        
        NSArray *listOfChunksDto = [self prepareChunksByFile:localFilePath andRemoteFilePath:remoteFilePath];
        
        NSInputStream *input = [NSInputStream inputStreamWithFileAtPath:localFilePath];
        NSInputStream *inputForRedirection = [NSInputStream inputStreamWithFileAtPath:localFilePath];
        
        //We create two different InputStream for the same because if we work with a redirected server the redirection happens after begin to read the inputStream
        OCChunkInputStream *chunkInputStream = [[OCChunkInputStream alloc]initWithInputStream:input andBytesToRead:totalBytesExpectedToWrote];
        OCChunkInputStream *chunkInputStreamForRedirection = [[OCChunkInputStream alloc]initWithInputStream:inputForRedirection andBytesToRead:totalBytesExpectedToWrote];
        
        for (OCChunkDto *currentChunkDto in listOfChunksDto) {
          
            NSLog(@"Creating chunks operation %d of %d", ([listOfChunksDto indexOfObject:currentChunkDto]+1),[listOfChunksDto count]);
            
            [_listOfOperationsToUploadAFile addObject: [request putChunk:currentChunkDto fromInputStream:chunkInputStream andInputStreamForRedirection:chunkInputStreamForRedirection atRemotePath:currentChunkDto.remotePath onCommunication:sharedOCCommunication
            progress:^(NSUInteger bytesWrote, long long totalBytesWrote) {
                
                totalBytesWrote = (_chunkPositionUploading * k_OC_lenght_chunk) + totalBytesWrote;
                
                progressUpload(bytesWrote, totalBytesWrote, totalBytesExpectedToWrote);
            } success:^(OCHTTPRequestOperation *operation, id responseObject) {
                
                [_listOfOperationsToUploadAFile removeObjectIdenticalTo:operation];

                
                _chunkPositionUploading++;
                if (_chunkPositionUploading == [listOfChunksDto count]) {
                    //This is the last chunk so we finish the upload.
                    successRequest(operation.response, request.redirectedServer);
                }

            } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
                 [_listOfOperationsToUploadAFile removeObjectIdenticalTo:operation];
                [self cancel];
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
        
    } else {
        
        NSLog(@"Upload NO Chunks");
        
        [_listOfOperationsToUploadAFile addObject: [request putLocalPath:localFilePath atRemotePath:remoteFilePath onCommunication:sharedOCCommunication progress:^(NSUInteger bytesWrote, long long totalBytesWrote) {

            progressUpload(bytesWrote, totalBytesWrote, totalBytesExpectedToWrote);
        } success:^(OCHTTPRequestOperation *operation, id responseObject) {
            [_listOfOperationsToUploadAFile removeObjectIdenticalTo:operation];
            successRequest(operation.response, request.redirectedServer);
        } failure:^(OCHTTPRequestOperation *operation, NSError *error) {
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
/// @name prepareChunksByFile
///-----------------------------------

/**
 * Method to return an array of NSStrings that contains all the chunks with the paths that we will uploads.
 *
 * @param NSString -> localFilePath the path where is the file that we want upload
 * @param NSString -> remoteFilePath the path where we want upload the file
 */
- (NSMutableArray *) prepareChunksByFile: (NSString *) localFilePath andRemoteFilePath: (NSString *) remoteFilePath {
    NSLog(@"Prepare chunks");
    
    NSMutableArray *listOfChunksDto = [NSMutableArray new];
    
    //Random transfer id
    int maxNumber = 1000000;
    int randon_number;
    randon_number=((int)arc4random() / maxNumber);
    //Convert negative valors
    if (randon_number<0) {
        randon_number=randon_number*-1;
    }
    
    //NSData *fileData = [ NSData dataWithContentsOfFile:_filePath];
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:localFilePath error:NULL];
    NSNumber * size = [attributes objectForKey: NSFileSize];
    NSUInteger length = [size integerValue];
    
    // NSUInteger length = [fileData length];
    NSLog(@"File length: %d", length);
    NSUInteger chunkSize = k_OC_lenght_chunk;
    NSLog(@"ChunkSize: %d", chunkSize);
    
    NSUInteger offset = 0;
    NSUInteger chunkIndex = 0;

    
    int totalChunksForThisFile = ceil((float)length/(float)k_OC_lenght_chunk);
    
    NSLog(@"Number of chunks: %d", totalChunksForThisFile);
    
    do {
        
        OCChunkDto *currentChunk = [OCChunkDto new];
        
        //Store position
        currentChunk.position = [NSNumber numberWithInt:offset];
        
        //Store the chunk size
        NSUInteger thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset;
        currentChunk.size = [NSNumber numberWithInt:thisChunkSize];
        
        //Avanced position
        offset += thisChunkSize;
        
        
        // Store the name of chunk
        //https://s3.owncloud.com/owncloud/remote.php/webdav/Demo%20Delete/Video-19-11-13-01-10-24-0.MOV-chunking-1189-17-0
        currentChunk.remotePath = [NSString stringWithFormat:@"%@-chunking-%d-%d-%d", remoteFilePath, randon_number, totalChunksForThisFile, chunkIndex];
        
        NSLog(@"currentChunk.remotePath: %@", currentChunk.remotePath);
        
        chunkIndex++;
        
        [listOfChunksDto addObject:currentChunk];
        
    } while (offset < length);
    
    return listOfChunksDto;
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
