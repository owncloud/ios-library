//
//  OCCapabilities.m
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

#import "OCCapabilities.h"

@implementation OCCapabilities

- (id)init {
    self = [super init];
    if (self) {
        self.versionMajor = 0;
        self.versionMinor = 0;
        self.versionMicro = 0;
        self.versionString = @"";
        self.versionEdition = @"";
        self.corePollInterval = 0;
        self.filesSharingExpireDateDaysNumber = 0;
        
    }
    return self;
}

#pragma mark - NSCopying

-(id) copyWithZone:(NSZone *)zone {
    OCCapabilities *capCopy = [[OCCapabilities alloc]init];
    capCopy.versionMajor = self.versionMajor;
    capCopy.versionMinor = self.versionMinor;
    capCopy.versionMicro = self.versionMicro;
    capCopy.versionString = self.versionString;
    capCopy.versionEdition = self.versionEdition;
    
    capCopy.corePollInterval = self.corePollInterval;
    
    capCopy.isFilesSharingAPIEnabled = self.isFilesSharingAPIEnabled;
    
    capCopy.isFilesSharingShareLinkEnabled = self.isFilesSharingShareLinkEnabled;
    
    capCopy.isFilesSharingPasswordEnforcedEnabled = self.isFilesSharingPasswordEnforcedEnabled;
    
    capCopy.isFilesSharingExpireDateByDefaultEnabled = self.isFilesSharingExpireDateByDefaultEnabled;
    capCopy.isFilesSharingExpireDateEnforceEnabled = self.isFilesSharingExpireDateEnforceEnabled;
    capCopy.filesSharingExpireDateDaysNumber = self.filesSharingExpireDateDaysNumber;

    capCopy.isFilesSharingAllowUserSendMailNotificationAboutShareLinkEnabled = self.isFilesSharingAllowUserSendMailNotificationAboutShareLinkEnabled;
    capCopy.isFilesSharingAllowPublicUploadsEnabled = self.isFilesSharingAllowPublicUploadsEnabled;
    capCopy.isFilesSharingSupportsUploadOnlyEnabled = self.isFilesSharingSupportsUploadOnlyEnabled;
    capCopy.isFilesSharingAllowUserCreateMultiplePublicLinksEnabled = self.isFilesSharingAllowUserCreateMultiplePublicLinksEnabled;

    capCopy.isFilesSharingAllowUserSendMailNotificationAboutOtherUsersEnabled = self.isFilesSharingAllowUserSendMailNotificationAboutOtherUsersEnabled;
    capCopy.isFilesSharingReSharingEnabled = self.isFilesSharingReSharingEnabled;

    capCopy.isFilesSharingAllowUserSendSharesToOtherServersEnabled = self.isFilesSharingAllowUserSendSharesToOtherServersEnabled;
    capCopy.isFilesSharingAllowUserReceiveSharesToOtherServersEnabled = self.isFilesSharingAllowUserReceiveSharesToOtherServersEnabled;

    capCopy.isFileBigFileChunkingEnabled = self.isFileBigFileChunkingEnabled;
    capCopy.isFileUndeleteEnabled = self.isFileUndeleteEnabled;
    capCopy.isFileVersioningEnabled = self.isFileVersioningEnabled;

    return capCopy;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:self.versionMajor forKey:@"versionMajor"];
    [aCoder encodeInteger:self.versionMinor forKey:@"versionMinor"];
    [aCoder encodeInteger:self.versionMicro forKey:@"versionMicro"];
    [aCoder encodeObject:self.versionString forKey:@"versionString"];
    [aCoder encodeObject:self.versionEdition forKey:@"versionEdition"];
    
    [aCoder encodeInteger:self.corePollInterval forKey:@"corePollInterval"];
    
    [aCoder encodeBool:self.isFilesSharingAPIEnabled forKey:@"isFilesSharingAPIEnabled"];
    
    [aCoder encodeBool:self.isFilesSharingShareLinkEnabled forKey:@"isFilesSharingShareLinkEnabled"];
    
    [aCoder encodeBool:self.isFilesSharingPasswordEnforcedEnabled forKey:@"isFilesSharingPasswordEnforcedEnabled"];
    
    [aCoder encodeBool:self.isFilesSharingExpireDateByDefaultEnabled forKey:@"isFilesSharingExpireDateByDefaultEnabled"];
    [aCoder encodeBool:self.isFilesSharingExpireDateEnforceEnabled forKey:@"isFilesSharingExpireDateEnforceEnabled"];
    [aCoder encodeInteger:self.filesSharingExpireDateDaysNumber forKey:@"filesSharingExpireDateDaysNumber"];
    
    [aCoder encodeBool:self.isFilesSharingAllowUserSendMailNotificationAboutShareLinkEnabled forKey:@"isFilesSharingAllowUserSendMailNotificationAboutShareLinkEnabled"];
    [aCoder encodeBool:self.isFilesSharingAllowPublicUploadsEnabled forKey:@"isFilesSharingAllowPublicUploadsEnabled"];
    [aCoder encodeBool:self.isFilesSharingSupportsUploadOnlyEnabled forKey:@"isFilesSharingSupportsUploadOnlyEnabled"];
    [aCoder encodeBool:self.isFilesSharingAllowUserCreateMultiplePublicLinksEnabled forKey:@"isFilesSharingAllowUserCreateMultiplePublicLinksEnabled"];
    
    [aCoder encodeBool:self.isFilesSharingAllowUserSendMailNotificationAboutOtherUsersEnabled forKey:@"isFilesSharingAllowUserSendMailNotificationAboutOtherUsersEnabled"];
    [aCoder encodeBool:self.isFilesSharingReSharingEnabled forKey:@"isFilesSharingReSharingEnabled"];

    [aCoder encodeBool:self.isFilesSharingAllowUserSendSharesToOtherServersEnabled forKey:@"isFilesSharingAllowUserSendSharesToOtherServersEnabled"];
    [aCoder encodeBool:self.isFilesSharingAllowUserReceiveSharesToOtherServersEnabled forKey:@"isFilesSharingAllowUserReceiveSharesToOtherServersEnabled"];

    [aCoder encodeBool:self.isFileBigFileChunkingEnabled forKey:@"isFileBigFileChunkingEnabled"];
    [aCoder encodeBool:self.isFileUndeleteEnabled forKey:@"isFileUndeleteEnabled"];
    [aCoder encodeBool:self.isFileVersioningEnabled forKey:@"isFileVersioningEnabled"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init]) {
        self.versionMajor = [aDecoder decodeIntegerForKey:@"versionMajor"];
        self.versionMinor = [aDecoder decodeIntegerForKey:@"versionMinor"];
        self.versionMicro = [aDecoder decodeIntegerForKey:@"versionMicro"];
        self.versionString = [aDecoder decodeObjectForKey:@"versionString"];
        self.versionEdition = [aDecoder decodeObjectForKey:@"versionEdition"];
        
        self.corePollInterval = [aDecoder decodeIntegerForKey:@"corePollInterval"];
        
        self.isFilesSharingAPIEnabled = [aDecoder decodeBoolForKey:@"isFilesSharingAPIEnabled"];
        
        self.isFilesSharingShareLinkEnabled = [aDecoder decodeBoolForKey:@"isFilesSharingShareLinkEnabled"];
        
        self.isFilesSharingPasswordEnforcedEnabled = [aDecoder decodeBoolForKey:@"isFilesSharingPasswordEnforcedEnabled"];
        
        self.isFilesSharingExpireDateByDefaultEnabled = [aDecoder decodeBoolForKey:@"isFilesSharingExpireDateByDefaultEnabled"];
        self.isFilesSharingExpireDateEnforceEnabled = [aDecoder decodeBoolForKey:@"isFilesSharingExpireDateEnforceEnabled"];
        self.filesSharingExpireDateDaysNumber = [aDecoder decodeIntegerForKey:@"filesSharingExpireDateDaysNumber"];
        
        self.isFilesSharingAllowUserSendMailNotificationAboutShareLinkEnabled = [aDecoder decodeBoolForKey:@"isFilesSharingAllowUserSendMailNotificationAboutShareLinkEnabled"];
        self.isFilesSharingAllowPublicUploadsEnabled = [aDecoder decodeBoolForKey:@"isFilesSharingAllowPublicUploadsEnabled"];
        self.isFilesSharingSupportsUploadOnlyEnabled = [aDecoder decodeBoolForKey:@"isFilesSharingSupportsUploadOnlyEnabled"];
        self.isFilesSharingAllowUserCreateMultiplePublicLinksEnabled = [aDecoder decodeBoolForKey:@"isFilesSharingAllowUserCreateMultiplePublicLinksEnabled"];

        self.isFilesSharingAllowUserSendMailNotificationAboutOtherUsersEnabled = [aDecoder decodeBoolForKey:@"isFilesSharingAllowUserSendMailNotificationAboutOtherUsersEnabled"];
        self.isFilesSharingReSharingEnabled = [aDecoder decodeBoolForKey:@"isFilesSharingReSharingEnabled"];

        self.isFilesSharingAllowUserSendSharesToOtherServersEnabled = [aDecoder decodeBoolForKey:@"isFilesSharingAllowUserSendSharesToOtherServersEnabled"];
        self.isFilesSharingAllowUserReceiveSharesToOtherServersEnabled = [aDecoder decodeBoolForKey:@"isFilesSharingAllowUserReceiveSharesToOtherServersEnabled"];

        self.isFileBigFileChunkingEnabled = [aDecoder decodeBoolForKey:@"isFilesSharingReSharingEnabled"];
        self.isFileUndeleteEnabled = [aDecoder decodeBoolForKey:@"isFileUndeleteEnabled"];
        self.isFileVersioningEnabled = [aDecoder decodeBoolForKey:@"isFileVersioningEnabled"];
    }
    return self;
}

@end
