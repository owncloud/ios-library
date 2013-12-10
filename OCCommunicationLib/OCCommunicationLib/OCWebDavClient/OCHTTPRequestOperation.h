//
//  OCHTTPRequestOperation.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 12/11/13.
//
//

#import "AFHTTPRequestOperation.h"

typedef enum {
    DownloadQueue   = 0,
    UploadQueue     = 1,
    NavigationQueue = 2
} typeOfOperationQueue;


@interface OCHTTPRequestOperation : AFHTTPRequestOperation


@property (nonatomic, assign) typeOfOperationQueue typeOfOperation;
@property (nonatomic, strong) NSString *redirectedServer;

@end
