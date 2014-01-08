//
//  OCSharedDto.h
//  OCCommunicationLib
//
//  Created by javi on 1/7/14.
//  Copyright (c) 2014 ownCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OCSharedDto : NSObject

typedef enum {
    shareTypeUser = 0,
    shareTypeGroup = 1,
    shareTypeLink = 3,
    shareTypeEmail = 4,
    shareTypeContact = 5,
    shareTypeRemote = 6
} enumShareType;

@property NSInteger idRemoteShared;
@property BOOL isDirectory;
@property NSInteger itemSource;
@property NSInteger parent;
@property NSInteger shareType;
@property (nonatomic, copy) NSString *shareWith;
@property NSInteger fileSource;
@property (nonatomic, copy) NSString *path;
@property NSInteger permissions;
@property long sharedDate;
@property long expirationDate;
@property (nonatomic, copy) NSString *token;
@property NSInteger storage;
@property NSInteger mailSend;
@property (nonatomic, copy) NSString *uidOwner;
@property (nonatomic, copy) NSString *shareWithDisplayName;
@property (nonatomic, copy) NSString *displayNameOwner;


@end
