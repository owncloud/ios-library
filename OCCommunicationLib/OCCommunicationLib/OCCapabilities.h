//
//  OCCapabilities.h
//  ownCloud iOS library
//
//  Created by Gonzalo Gonzalez on 4/11/15.
//
// Copyright (C) 2017, ownCloud GmbH. ( http://www.owncloud.org/ )
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

@interface OCCapabilities : NSObject <NSCopying>

/*VERSION*/
@property (nonatomic) NSInteger versionMajor;
@property (nonatomic) NSInteger versionMinor;
@property (nonatomic) NSInteger versionMicro;
@property (nonatomic, strong) NSString *versionString;
@property (nonatomic, strong) NSString *versionEdition;

/*CAPABILITIES*/

/*CORE*/
@property (nonatomic) NSInteger corePollInterval;

/*FILES SHARING*/

@property (nonatomic) BOOL isFilesSharingAPIEnabled;

//SHARE LINK FEATURES
@property (nonatomic) BOOL isFilesSharingShareLinkEnabled;

//Share Link with password
@property (nonatomic) BOOL isFilesSharingPasswordEnforcedEnabled;

//Share Link with expiration date
@property (nonatomic) BOOL isFilesSharingExpireDateByDefaultEnabled;
@property (nonatomic) BOOL isFilesSharingExpireDateEnforceEnabled;
@property (nonatomic) NSInteger filesSharingExpireDateDaysNumber;

//Other share link features
@property (nonatomic) BOOL isFilesSharingAllowUserSendMailNotificationAboutShareLinkEnabled;
@property (nonatomic) BOOL isFilesSharingAllowPublicUploadsEnabled;
@property (nonatomic) BOOL isFilesSharingSupportsUploadOnlyEnabled;
@property (nonatomic) BOOL isFilesSharingAllowUserCreateMultiplePublicLinksEnabled;

//Other Shares Features
@property (nonatomic) BOOL isFilesSharingAllowUserSendMailNotificationAboutOtherUsersEnabled;
@property (nonatomic) BOOL isFilesSharingReSharingEnabled;

//Federating cloud share (before called Server-to-Server sharing)
@property (nonatomic) BOOL isFilesSharingAllowUserSendSharesToOtherServersEnabled;
@property (nonatomic) BOOL isFilesSharingAllowUserReceiveSharesToOtherServersEnabled;


/*FILES*/
@property (nonatomic) BOOL isFileBigFileChunkingEnabled;
@property (nonatomic) BOOL isFileUndeleteEnabled;
@property (nonatomic) BOOL isFileVersioningEnabled;

- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end
