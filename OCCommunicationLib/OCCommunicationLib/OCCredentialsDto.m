//
//  OCCredentialsDto.m
//  ownCloud iOS library
//
//  Created by Noelia Alvarez on 27/10/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "OCCredentialsDto.h"

@implementation OCCredentialsDto

- (id)initWithCredentialsDto:(OCCredentialsDto *)oCredDto{
    
    self = [super init];
    if (self) {
        // Custom initialization
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
