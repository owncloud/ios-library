//
//  OCCommunication.h
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

@class OCHTTPRequestOperation;
@class AFURLSessionManager;

@interface OCCommunication : NSObject

//Type of credential
typedef enum {
    credentialNotSet = -1,
    credentialNormal = 0, //user, password
    credentialCookie = 1,
    credentialOauth = 2
} kindOfCredentialEnum;


typedef enum {
    OCErrorUnknow = 90, //On all errors
    OCErrorForbidenCharacters = 100, //On create folder and rename
    OCErrorMovingDestinyNameHaveForbiddenCharacters = 110,//On move file or folder
    OCErrorMovingTheDestinyAndOriginAreTheSame = 111, //On move file or folder
    OCErrorMovingFolderInsideHimself = 112, //On move file or folder
    OCErrorFileToUploadDoesNotExist = 120 //The file that we want upload does not exist
} OCErrorEnum;

//Private properties
@property int kindOfCredential;
@property (nonatomic, strong) NSString *user;
@property (nonatomic, strong) NSString *password;

//Public properties
@property (nonatomic, strong) NSOperationQueue *networkOperationsQueue;
@property (nonatomic, strong) NSMutableArray *downloadOperationQueueArray;
@property (nonatomic, strong) NSMutableArray *uploadOperationQueueArray;

#pragma mark - Credentials

///-----------------------------------
/// @name Set Credential With User
///-----------------------------------

/**
 * Method to set credentials with user and password
 *
 * @param user -> NSString username
 * @param password -> NSString password
 */
- (void) setCredentialsWithUser:(NSString*) user andPassword:(NSString*) password;


///-----------------------------------
/// @name Set Credential with cookie
///-----------------------------------

/**
 * Method that set credentials with cookie.
 * Used for SAML servers.
 *
 * @param cookie -> NSString cookie string
 */
- (void) setCredentialsWithCookie:(NSString*) cookie;


///-----------------------------------
/// @name Set Credential with OAuth
///-----------------------------------

/**
 * Method to set credentials for OAuth with token
 *
 * @param token -> NSString token
 */
- (void) setCredentialsOauthWithToken:(NSString*) token;


/*
 * Method to update the a request with the current credentials
 */
- (id) getRequestWithCredentials:(id) request;


#pragma mark - Network operations

///-----------------------------------
/// @name createFolder
///-----------------------------------

/**
 * Method to create a folder giving the full address where we want put the folder
 *
 * @param path -> NSString with the url where we want put the folder.
 * Ex: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 *
 * @warning remember that you must to set the Credentials before call this method or any other.
 *
 * @warning the "path" must not be on URL Encoding.
 * Ex:
 * Correct path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Pop Music/
 * Wrong path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Pop%20Music/
 *
 * @warning the folder name must not contain the next forbidden characers: "\", "/","<",">",":",""","|","?","*"
 */
- (void) createFolder: (NSString *) path
      onCommunication:(OCCommunication *)sharedOCCommunication
       successRequest:(void(^)(NSHTTPURLResponse *, NSString *)) successRequest
       failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest
   errorBeforeRequest:(void(^)(NSError *)) errorBeforeRequest;


///-----------------------------------
/// @name moveFileOrFolder
///-----------------------------------

/**
 * Method to move or rename a file/folder
 *
 * MOVE
 * @param sourcePath -> NSString with the url of the file or folder that you want move
 * Ex: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music
 * @param destinyPath -> NSString with the new url where we cant move the file or folder
 * Ex: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other Folder/Music
 *
 * RENAME
 * @param sourcePath -> NSString with the url of the file or folder that you want move
 * Ex: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music
 * @param destinyPath -> NSString with the new url where we cant move the file or folder
 * Ex: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Movies
 *
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 * @warning the move will overwritte an existing file on the destiny.
 *
 * @warning remember that you must to set the Credentials before call this method or any other.
 *
 * @warning the "sourcePath" and "destinyPath" must not be on URL Encoding.
 * Correct path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other Folder/Music
 * Wrong path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other%20Folder/Music
 *
 * @warning: to move a folder the "sourcePath" and "destinyPath" must end on "/" character
 * Correct path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music/
 * Wrong path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music
 *
 * @warning: to move a file the "sourcePath" and "destinyPath" must not end on "/" character
 * Correct path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music.mp3
 * Wrong path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music.mp3/
 */

- (void) moveFileOrFolder:(NSString *)sourcePath
                toDestiny:(NSString *)destinyPath
          onCommunication:(OCCommunication *)sharedOCCommunication
           successRequest:(void (^)(NSHTTPURLResponse *, NSString *))successRequest
           failureRequest:(void (^)(NSHTTPURLResponse *, NSError *))failureRequest
       errorBeforeRequest:(void (^)(NSError *))errorBeforeRequest;



///-----------------------------------
/// @name Read Folder
///-----------------------------------

/**
 * Block to get the list of files/folders for a path
 *
 * @param path -> NSString with the url of the path
 * Ex: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music
 *
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 * @warning the "path" must not be on URL Encoding.
 * Correct path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other Folder/Music
 * Wrong path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other%20Folder/Music
 *
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 */
- (void) readFolder: (NSString *) path
    onCommunication:(OCCommunication *)sharedOCCommunication
     successRequest:(void(^)(NSHTTPURLResponse *, NSArray *, NSString *)) successRequest
     failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest;



///-----------------------------------
/// @name Read File
///-----------------------------------

/**
 * Block to get the unique file/folder of a path. Used to get the properties of the file.
 *
 * @param path -> NSString with the url of the path
 * Ex: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music
 *
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 * @warning the "path" must not be on URL Encoding.
 * Correct path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other Folder/Music
 * Wrong path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other%20Folder/Music
 *
 */
- (void) readFile: (NSString *) path
  onCommunication:(OCCommunication *)sharedOCCommunication
   successRequest:(void(^)(NSHTTPURLResponse *, NSArray *, NSString *)) successRequest
   failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest;


///-----------------------------------
/// @name Delete a file or a folder
///-----------------------------------

/**
 * This method delete a file or a folder
 *
 * @param path -> NSString with the url of the file or the folder that the user want to delete
 * Ex:http://www.myowncloudserver.com/owncloud/remote.php/webdav/Folder
 *
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 * @warning the "path" must not be on URL Encoding.
 * Correct path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other Folder/Music
 * Wrong path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other%20Folder/Music
 *
 * @warning remember that you must to set the Credentials before call this method or any other.
 *
 */
- (void) deleteFileOrFolder:(NSString *)path
            onCommunication:(OCCommunication *)sharedOCCommunication
             successRequest:(void (^)(NSHTTPURLResponse *, NSString *))successRequest
              failureRquest:(void (^)(NSHTTPURLResponse *, NSError *))failureRequest;


///-----------------------------------
/// @name Download File
///-----------------------------------

/**
 * This method download a file of a path and returns four blocks
 *
 * progressDownload: get the download inputs about the progress of the download
 * successRequest: the download it's complete
 * failureRequest: the download fail
 * shouldExectuteAsBackgroundTaskWithExpirationHandler: called when the system is in background and the file are downloading and the system will close the process
 * We normally cancel the download in this case
 *
 * @param remotePath -> NSString with the url of the file that the user want to download
 * Ex:http://www.myowncloudserver.com/owncloud/remote.php/webdav/Folder/image.jpg
 *
 * @param localPath -> NSString with the system path where the user want to store the file
 * Ex: /Users/userName/Library/Application Support/iPhone Simulator/7.0.3/Applications/35E6FC65-5492-427B-B6ED-EA9E25633508/Documents/Test Download/image.png
 *
 * @param isLIFO -> BOOL to indicate if the dowload must be to LIFO download queue or FIFO download queue
 *
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 * @return NSOperation -> You can cancel the download using this object.
 * Ex: [operation cancel]
 *
 * @warning the "remotePath" and "localFilePath" must not be on URL Encoding.
 * Correct path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other Folder/image.jpg
 * Wrong path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other%20Folder/image.jpg
 *
 * @warning remember that you must to set the Credentials before call this method or any other.
 */

- (NSOperation *) downloadFile:(NSString *)remotePath toDestiny:(NSString *)localPath withLIFOSystem:(BOOL)isLIFO onCommunication:(OCCommunication *)sharedOCCommunication progressDownload:(void(^)(NSUInteger, long long, long long))progressDownload successRequest:(void(^)(NSHTTPURLResponse *, NSString *)) successRequest failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest shouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler;


///-----------------------------------
/// @name Upload File
///-----------------------------------

/**
 * Method to upload a file. All the files will be upload one by one in a queue.
 *
 * @param NSString -> localPath the path where is the file that we want upload
 * @param NSString -> remotePath the path where we want upload the file
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 * @return NSOperation -> You can cancel the upload using this object
 * Ex: [operation cancel]
 *
 * @warning remember that you must to set the Credentials before call this method or any other.
 *
 */

- (NSOperation *) uploadFile:(NSString *) localPath toDestiny:(NSString *) remotePath onCommunication:(OCCommunication *)sharedOCCommunication progressUpload:(void(^)(NSUInteger, long long, long long))progressUpload successRequest:(void(^)(NSHTTPURLResponse *, NSString *)) successRequest failureRequest:(void(^)(NSHTTPURLResponse *, NSString *, NSError *)) failureRequest  failureBeforeRequest:(void(^)(NSError *)) failureBeforeRequest shouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler;

- (NSURLSessionUploadTask *) uploadFileSession:(NSString *) localPath toDestiny:(NSString *) remotePath onCommunication:(OCCommunication *)sharedOCCommunication withIdentifier:(NSString *) identifier withProgress:(NSProgress * __autoreleasing *) progressValue progressUpload:(void(^)(NSUInteger, long long, long long))progressUpload successRequest:(void(^)(NSURLResponse *, NSString *)) successRequest failureRequest:(void(^)(NSURLResponse *, NSString *, NSError *)) failureRequest  failureBeforeRequest:(void(^)(NSError *)) failureBeforeRequest shouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler;


#pragma mark - OC API Calls

///-----------------------------------
/// @name requestForUserNameByCookie
///-----------------------------------

/**
 * Method to get the User name by the cookie of the session. Used with SAML servers.
 *
 * @param cookieString -> NSString The cookie of the session
 *
 * @param path -> NSString server path
 *
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 */


- (void) getUserNameByCookie:(NSString *) cookieString ofServerPath:(NSString *)path onCommunication:
(OCCommunication *)sharedOCCommunication success:(void(^)(NSHTTPURLResponse *, NSData *, NSString *))success
                     failure:(void(^)(NSHTTPURLResponse *, NSError *))failure;

///-----------------------------------
/// @name Has Server Share Support
///-----------------------------------

/**
 * Method to get if the server has Share API support or not
 *
 * @param path -> NSString server path
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 * @return BOOL in the success about the support
 *
 */
- (void) hasServerShareSupport:(NSString*) path onCommunication:(OCCommunication *)sharedOCCommunication
                successRequest:(void(^)(NSHTTPURLResponse *,BOOL, NSString *)) success
                failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failure;

///-----------------------------------
/// @name readSharedByServer
///-----------------------------------

/**
 * Method to return all the files and folders shareds on the server by the current user
 *
 * @param path -> NSString server path
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 * @return NSArray with all the OCSharedDto of shareds files
 *
 */
- (void) readSharedByServer: (NSString *) path
         onCommunication:(OCCommunication *)sharedOCCommunication
          successRequest:(void(^)(NSHTTPURLResponse *, NSArray *, NSString *)) successRequest
          failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest;

///-----------------------------------
/// @name readSharedByServer
///-----------------------------------

/**
 * Method to return the files and folders shareds on a concrete path by the current user
 *
 * @param serverPath -> NSString server path
 * @param path -> Path of the folder that we want to know that shareds that contain
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 * @return NSArray with all the OCSharedDto of shareds files
 *
 */
- (void) readSharedByServer: (NSString *) serverPath andPath: (NSString *) path
            onCommunication:(OCCommunication *)sharedOCCommunication
             successRequest:(void(^)(NSHTTPURLResponse *, NSArray *, NSString *)) successRequest
             failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest;

///-----------------------------------
/// @name shareFileOrFolderByServer
///-----------------------------------

/**
 * Method to share a file or folder
 *
 * @param serverPath -> NSString server path
 * @param filePath -> path of the file that we want to share. Ex: /file.pdf <- If the file is on the root folder
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 * @return token of the file that we shared. Ex:572d48de3814c90117fbca6442f2f3b2
 *
 * @warning to create the full URL to share the file on a link we have to atatch the token to: http://www.myowncloudserver.com/public.php?service=files&t=572d48de3814c90117fbca6442f2f3b2
 */
- (void) shareFileOrFolderByServer: (NSString *) serverPath andFileOrFolderPath: (NSString *) filePath
                   onCommunication:(OCCommunication *)sharedOCCommunication
                    successRequest:(void(^)(NSHTTPURLResponse *, NSString *, NSString *)) successRequest
                    failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest;

///-----------------------------------
/// @name unShareFileOrFolderByServer
///-----------------------------------

/**
 * Method to share a file or folder
 *
 * @param path -> NSString server path
 * @param idRemoteShared -> id number of the shared. Value obtained on the idRemoteSHared of OCSharedDto
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 */
- (void) unShareFileOrFolderByServer: (NSString *) path andIdRemoteShared: (int) idRemoteShared
                     onCommunication:(OCCommunication *)sharedOCCommunication
                      successRequest:(void(^)(NSHTTPURLResponse *, NSString *)) successRequest
                      failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest;

///-----------------------------------
/// @name isShareFileOrFolderByServer
///-----------------------------------

/**
 * Method to know if a share item still shared
 *
 * @param path -> NSString server path
 * @param idRemoteShared -> id number of the shared. Value obtained on the idRemoteSHared of OCSharedDto
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 */
- (void) isShareFileOrFolderByServer: (NSString *) path andIdRemoteShared: (int) idRemoteShared
                     onCommunication:(OCCommunication *)sharedOCCommunication
                      successRequest:(void(^)(NSHTTPURLResponse *, NSString *, BOOL)) successRequest
                      failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest;

#pragma mark - Queue system
/*
 * Method that add an operation to the appropiate queue
 */
- (void) addOperationToTheNetworkQueue:(OCHTTPRequestOperation *) operation;


@end
