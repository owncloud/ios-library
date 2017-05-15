//
//  OCServerFeatures.m
//  ownCloud iOS library
//
//  Created by Noelia Alvarez on 05/04/17.
//  Copyright © 2017 ownCloud. All rights reserved.
//

#import "OCServerFeatures.h"

@implementation OCServerFeatures

- (id)initWithSupportForShare:(BOOL)share sharee:(BOOL)sharee cookies:(BOOL)cookies forbiddenCharacters:(BOOL)forbiddenCharacters capabilities:(BOOL)capabilites fedSharesOptionShare:(BOOL)fedSharesOptionShare publicShareLinkOptionName:(BOOL)publicShareLinkOptionName {
    
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
            castedOther.hasPublicShareLinkOptionNameSupport == self.hasPublicShareLinkOptionNameSupport
            );

}

@end
