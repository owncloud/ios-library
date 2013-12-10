//
//  OCFileDto.h
//  Owncloud iOs Client
//
//  Created by javi on 10/24/13.
//
//

#import <Foundation/Foundation.h>

@interface OCFileDto : NSObject {
    NSString *filePath;
    NSString *fileName;
    BOOL isDirectory;
    long size;
    long date;
    long long etag;
}

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *fileName;
@property BOOL isDirectory;
@property long size;
@property long date;
@property long long etag;

@end
