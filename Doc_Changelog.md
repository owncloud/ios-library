What's the new in 1.5 version
---------------

- Added support to work with Sharee API (New server API from version 8.2 to manage users and groups)

 + Update the method "- (void) hasServerShareSupport:..." in order to get also if the server support "sharee api". Now the method is called "- (void) hasServerShareAndShareeSupport:..." and return in the block "BOOL hasShareSupport, BOOL hasShareeSupport" boolean properties. 
 + Search users and groups. New method that return a list of "OCShareUser" objects using a search string: "- (void) searchUsersAndGroupsWith...". Used to get lists of users and group in order to share files or folders with them using the new "shareWith" method. 
 + New object class called "OCShareUser" that it used to store users or groups.
 + New method share with users: "- (void)shareWith:...". Using the name property of the OCShare object you can share file or folders with users or groups.

- Updated AFNetworking library v2.6.0

- Modified security policy to fix some issues with requests that were canceled after a while using self signed servers.
  

Previous changes:
---------------

-  1.1.4 version
---------------

Added token support in read folder method for multiaccount. In order to differenciate the user account in the response from the server side we have added token support, for the moment only in the readFolder method.

We have a method in UtilsFramework.h called "getUserSessionToken" to get a unique session id.

+ (NSString *) getUserSessionToken;

We can use that to send as a parameter on readFolder method. Also if only we have a single account we can use "nil" 

- (void) readFolder: (NSString *) path withUserSessionToken:(NSString *)token
    onCommunication:(OCCommunication *)sharedOCCommunication
     successRequest:(void(^)(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer, NSString *token)) successRequest
     failureRequest:(void(^)(NSHTTPURLResponse *response, NSError *error, NSString *token)) failureRequest;


-  1.1.3 version
---------------

From OC 8.1, the server manage the forbbiden characters except the '/'. 

New method to check if the server has forbidden characters support.
- (void) hasServerForbiddenCharactersSupport:(NSString*) path onCommunication:(OCCommunication *)sharedOCCommunication .....

We have prepared the current createFolder and moveFileOrFolder methods for do support that. We have added a new BOOL parameter "isFCSupported" using the previews method you can know what is the value of "isFCSupported"

You can see more specific in OCCommunication class.

-  old versions
---------------


Download queue
---------------
When we download a file we use a queue in order to download the files one by one. 
By default the queue es FIFO. We will download the files in the order that the developer add them.
But if we want to use the queue as LIFO (download first the last file that we add to download) we need to call "setDownloadQueueToLIFO" method
Code example
~~~~~~~~~~~~
.. code-block:: objective-c
//Set the downloads with LIFO system
[[AppDelegate sharedOCCommunication] setDownloadQueueToLIFO:YES];
