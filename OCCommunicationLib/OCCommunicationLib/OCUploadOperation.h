//
//  OCUploadsWithChunksOperation.h
//  Owncloud iOs Client
//
//  Created by javi on 11/18/13.
//
//

#import <Foundation/Foundation.h>

@class OCCommunication;
@class AFHTTPRequestOperation;

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
- (void) createOperationWith:(NSString *) localFilePath toDestiny:(NSString *) remoteFilePath onCommunication:(OCCommunication *)sharedOCCommunication progressUpload:(void(^)(NSUInteger, long long, long long))progressUpload successRequest:(void(^)(NSHTTPURLResponse *)) successRequest failureRequest:(void(^)(NSHTTPURLResponse *, NSString *redirectedServer, NSError *)) failureRequest failureBeforeRequest:(void(^)(NSError *)) failureBeforeRequest shouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler;

@end
