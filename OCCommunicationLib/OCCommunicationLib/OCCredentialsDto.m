//
//  OCCredentialsDto.m
//  ownCloud iOS library
//
//  Created by Noelia Alvarez on 27/10/14.
//
// Copyright (C) 2017, ownCloud GmbH.  ( http://www.owncloud.org/ )
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

#import "OCCredentialsDto.h"

@implementation OCCredentialsDto

- (id)initWithCredentialsDto:(OCCredentialsDto *)oCredDto{
    
    self = [super init];
    if (self) {
        // Custom initialization
        _userId = oCredDto.userId;
        _baseURL = oCredDto.baseURL;
        _userName = oCredDto.userName;
        _accessToken = oCredDto.accessToken;
        _refreshToken = oCredDto.refreshToken;
        _expiresIn = oCredDto.expiresIn;
        _tokenType = oCredDto.tokenType;
        _authenticationMethod = oCredDto.authenticationMethod;
    }
    
    return self;
}

-(id) copyWithZone:(NSZone *)zone {
    OCCredentialsDto *credDtoCopy = [[OCCredentialsDto alloc]init];
    credDtoCopy.userId = self.userId;
    credDtoCopy.baseURL = self.baseURL;
    credDtoCopy.userName = self.userName;
    credDtoCopy.accessToken = self.accessToken;
    credDtoCopy.refreshToken = self.refreshToken;
    credDtoCopy.expiresIn = self.expiresIn;
    credDtoCopy.tokenType = self.tokenType;
    credDtoCopy.authenticationMethod = self.authenticationMethod;
    
    return credDtoCopy;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.userId forKey:@"userId"];
    [aCoder encodeObject:self.baseURL forKey:@"baseURL"];
    [aCoder encodeObject:self.userName forKey:@"userName"];
    [aCoder encodeObject:self.accessToken forKey:@"accessToken"];
    [aCoder encodeObject:self.refreshToken forKey:@"refreshToken"];
    [aCoder encodeObject:self.expiresIn forKey:@"expiresIn"];
    [aCoder encodeObject:self.tokenType forKey:@"tokenType"];
    [aCoder encodeInteger:self.authenticationMethod forKey:@"authenticationMethod"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.userId = [aDecoder decodeObjectForKey:@"userId"];
        self.baseURL = [aDecoder decodeObjectForKey:@"baseURL"];
        self.userName = [aDecoder decodeObjectForKey:@"userName"];
        self.accessToken = [aDecoder decodeObjectForKey:@"accessToken"];
        self.refreshToken = [aDecoder decodeObjectForKey:@"refreshToken"];
        self.expiresIn = [aDecoder decodeObjectForKey:@"tokenType"];
        self.tokenType = [aDecoder decodeObjectForKey:@"tokenType"];
        self.authenticationMethod = [aDecoder decodeIntegerForKey:@"authenticationMethod"];
    }
    return self;
}

@end
