//
//  OCSharedDto.m
//  Owncloud iOs Client
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

#import "OCSharedDto.h"

@implementation OCSharedDto

- (id)initWithSharedDto:(OCSharedDto *)oSharedDto{
    
    self = [super init];
    if (self) {
        // Custom initialization
        _idRemoteShared = oSharedDto.idRemoteShared;
        _isDirectory = oSharedDto.isDirectory;
        _itemSource = oSharedDto.itemSource;
        _parent = oSharedDto.parent;
        _shareType = oSharedDto.shareType;
        _shareWith = oSharedDto.shareWith;
        _fileSource = oSharedDto.fileSource;
        _path = oSharedDto.path;
        _permissions = oSharedDto.permissions;
        _sharedDate = oSharedDto.sharedDate;
        _expirationDate = oSharedDto.expirationDate;
        _token = oSharedDto.token;
        _storage = oSharedDto.storage;
        _mailSend= oSharedDto.mailSend;
        _uidOwner = oSharedDto.uidOwner;
        _shareWithDisplayName= oSharedDto.shareWithDisplayName;
        _displayNameOwner = oSharedDto.displayNameOwner;
        _uidFileOwner = oSharedDto.uidFileOwner;
        _fileTarget = oSharedDto.fileTarget;
        _name = oSharedDto.name;
        _url= oSharedDto.url;
    }
    
    return self;
}

@end
