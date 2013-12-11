//
//  OCCommunication.h
//  Owncloud iOs Client
//
//  Created by javi on 10/15/13.
//
//

#import <Foundation/Foundation.h>

@class OCHTTPRequestOperation;

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
 * @param pathOfNewFolder -> NSString with the url where we want put the folder.
 * Ex: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 *
 * @warning remember that you must to set the Credentials before call this method or any other.
 *
 * @warning the "pathOfNewFolder" must not be on URL Encoding.
 * Ex:
 * Correct path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Pop Music/
 * Wrong path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Pop%20Music/
 *
 * @warning the folder name must not contain the next forbidden characers: "\", "/","<",">",":",""","|","?","*"
 */
- (void) createFolder: (NSString *) pathOfNewFolder
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
 * @param source -> NSString with the url of the file or folder that you want move
 * Ex: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music
 * @param toPath -> NSString with the new url where we cant move the file or folder
 * Ex: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other Folder/Music
 *
 * RENAME
 * @param source -> NSString with the url of the file or folder that you want move
 * Ex: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music
 * @param toPath -> NSString with the new url where we cant move the file or folder
 * Ex: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Movies
 *
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 * @warning the move will overwritte an existing file on the destiny. To prevent it we recommend to use //TODO: finish this comment after make propfind method
 *
 * @warning remember that you must to set the Credentials before call this method or any other.
 *
 * @warning the "source" and "path" must not be on URL Encoding.
 * Correct path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other Folder/Music
 * Wrong path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other%20Folder/Music
 *
 * @warning: to move a folder the "source" and "path" must end on "/" character
 * Correct path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music/
 * Wrong path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music
 *
 * @warning: to move a file the "source" and "path" must not end on "/" character
 * Correct path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music.mp3
 * Wrong path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music.mp3/
 */

- (void) moveFileOrFolder:(NSString *)source
                toDestiny:(NSString *)destiny
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
 * @param remotePath -> NSString with the url of the path
 * Ex: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music
 *
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 * @warning the "source" and "remotePath" must not be on URL Encoding.
 * Correct path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other Folder/Music
 * Wrong path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other%20Folder/Music
 *
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 */
- (void) readFolder: (NSString *) remotePath
    onCommunication:(OCCommunication *)sharedOCCommunication
     successRequest:(void(^)(NSHTTPURLResponse *, NSArray *, NSString *)) successRequest
     failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest;



///-----------------------------------
/// @name Read File
///-----------------------------------

/**
 * Block to get the unique file/folder of a path. Used to get the properties of the file.
 *
 * @param remotePath -> NSString with the url of the path
 * Ex: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Music
 *
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 * @warning the "remotePath" must not be on URL Encoding.
 * Correct path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other Folder/Music
 * Wrong path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other%20Folder/Music
 *
 */
- (void) readFile: (NSString *) remotePath
  onCommunication:(OCCommunication *)sharedOCCommunication
   successRequest:(void(^)(NSHTTPURLResponse *, NSArray *, NSString *)) successRequest
   failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest;


///-----------------------------------
/// @name Delete a file or a folder
///-----------------------------------

/**
 * This method delete a file or a folder
 *
 * @param patToDelete -> NSString with the url of the file or the folder that the user want to delete
 * Ex:http://www.myowncloudserver.com/owncloud/remote.php/webdav/Folder
 *
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 * @warning the "pathToDelete" must not be on URL Encoding.
 * Correct path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other Folder/Music
 * Wrong path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other%20Folder/Music
 *
 * @warning remember that you must to set the Credentials before call this method or any other.
 *
 */
- (void) deleteFileOrFolder:(NSString *)pathToDelete
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
 * @param remoteFilePath -> NSString with the url of the file that the user want to download
 * Ex:http://www.myowncloudserver.com/owncloud/remote.php/webdav/Folder/image.jpg
 *
 * @param localFilePath -> NSString with the system path where the user want to store the file
 * Ex: /Users/userName/Library/Application Support/iPhone Simulator/7.0.3/Applications/35E6FC65-5492-427B-B6ED-EA9E25633508/Documents/Test Download/image.png
 *
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 * @return NSOperation -> You can cancel the download using this object.
 * Ex: [operation cancel]
 *
 * @warning the "remoteFilePath" and "localFilePath" must not be on URL Encoding.
 * Correct path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other Folder/image.jpg
 * Wrong path: http://www.myowncloudserver.com/owncloud/remote.php/webdav/Other%20Folder/image.jpg
 *
 * @warning remember that you must to set the Credentials before call this method or any other.
 */

- (NSOperation *) downloadFile:(NSString *)remoteFilePath toDestiny:(NSString *)localFilePath onCommunication:(OCCommunication *)sharedOCCommunication progressDownload:(void(^)(NSUInteger, long long, long long))progressDownload successRequest:(void(^)(NSHTTPURLResponse *, NSString *)) successRequest failureRequest:(void(^)(NSHTTPURLResponse *, NSError *)) failureRequest shouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler;


///-----------------------------------
/// @name Upload File
///-----------------------------------

/**
 * Method to upload a file. All the files will be upload one by one in a queue.
 *
 * @param NSString -> localFilePath the path where is the file that we want upload
 * @param NSString -> remoteFilePath the path where we want upload the file
 * @param sharedOCCommunication -> OCCommunication Singleton of communication to add the operation on the queue.
 *
 * @return NSOperation -> You can cancel the upload using this object
 * Ex: [operation cancel]
 *
 * @warning remember that you must to set the Credentials before call this method or any other.
 *
 */

- (NSOperation *) uploadFile:(NSString *) localFilePath toDestiny:(NSString *) remoteFilePath onCommunication:(OCCommunication *)sharedOCCommunication progressUpload:(void(^)(NSUInteger, long long, long long))progressUpload successRequest:(void(^)(NSHTTPURLResponse *)) successRequest failureRequest:(void(^)(NSHTTPURLResponse *, NSString *, NSError *)) failureRequest  failureBeforeRequest:(void(^)(NSError *)) failureBeforeRequest shouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler;


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


#pragma mark - Queue system
/*
 * Method that add an operation to the appropiate queue
 */
- (void) addOperationToTheNetworkQueue:(OCHTTPRequestOperation *) operation;


@end
