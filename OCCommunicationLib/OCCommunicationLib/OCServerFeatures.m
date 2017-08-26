//
//  OCServerFeatures.m
//  ownCloud iOS library
//
//  Created by Noelia Alvarez on 05/04/17.
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


#import "OCServerFeatures.h"

@implementation OCServerFeatures

- (id)initWithSupportForShare:(BOOL)share sharee:(BOOL)sharee cookies:(BOOL)cookies forbiddenCharacters:(BOOL)forbiddenCharacters capabilities:(BOOL)capabilites fedSharesOptionShare:(BOOL)fedSharesOptionShare publicShareLinkOptionName:(BOOL)publicShareLinkOptionName publicShareLinkOptionUploadOnlySupport:(BOOL)publicShareLinkOptionUploadOnlySupport {
    
    self = [super init];
    if (self) {
        // Custom initialization
        _hasShareSupport = share;
        _hasShareeSupport = sharee;
        _hasCookiesSupport = cookies;
        _hasForbiddenCharactersSupport = forbiddenCharacters;
        _hasCapabilitiesSupport = capabilites;
        _hasFedSharesOptionShareSupport = fedSharesOptionShare;
        _hasPublicShareLinkOptionNameSupport = publicShareLinkOptionName;
        _hasPublicShareLinkOptionUploadOnlySupport = publicShareLinkOptionUploadOnlySupport;
        
    }
    
    return self;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    OCServerFeatures *castedOther = (OCServerFeatures *)other;
    return (castedOther.hasShareSupport == self.hasShareSupport &&
            castedOther.hasShareeSupport == self.hasShareeSupport &&
            castedOther.hasCookiesSupport == self.hasCookiesSupport &&
            castedOther.hasForbiddenCharactersSupport == self.hasForbiddenCharactersSupport &&
            castedOther.hasCapabilitiesSupport == self.hasCapabilitiesSupport &&
            castedOther.hasFedSharesOptionShareSupport == self.hasFedSharesOptionShareSupport &&
            castedOther.hasPublicShareLinkOptionNameSupport == self.hasPublicShareLinkOptionNameSupport &&
            castedOther.hasPublicShareLinkOptionUploadOnlySupport == self.hasPublicShareLinkOptionUploadOnlySupport
            );

}

@end
