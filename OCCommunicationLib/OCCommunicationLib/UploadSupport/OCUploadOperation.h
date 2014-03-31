//
//  OCUploadsWithChunksOperation.h
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

#import <Foundation/Foundation.h>

@class OCCommunication;

@interface OCUploadOperation : NSOperation

@property int chunkPositionUploading;
@property (nonatomic, strong) NSMutableArray *listOfOperationsToUploadAFile;

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
- (void) createOperationWith:(NSString *) localFilePath toDestiny:(NSString *) remoteFilePath onCommunication:(OCCommunication *)sharedOCCommunication progressUpload:(void(^)(NSUInteger, long long, long long))progressUpload successRequest:(void(^)(NSHTTPURLResponse *, NSString *redirectedServer)) successRequest failureRequest:(void(^)(NSHTTPURLResponse *, NSString *redirectedServer, NSError *)) failureRequest failureBeforeRequest:(void(^)(NSError *)) failureBeforeRequest shouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler;

@end
