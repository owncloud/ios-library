//
//  OCServerFeatures.m
//  ownCloud iOS library
//
//  Created by Noelia Alvarez on 05/04/17.
//  Copyright © 2017 ownCloud. All rights reserved.
//

#import "OCServerFeatures.h"

@implementation OCServerFeatures

- (id)initWithSupportForShare:(BOOL)share sharee:(BOOL)sharee cookies:(BOOL)cookies forbiddenCharacters:(BOOL)forbiddenCharacters capabilities:(BOOL)capabilites fedSharesOptionShare:(BOOL)fedSharesOptionShare {
    
    self = [super init];
    if (self) {
        // Custom initialization
        _hasShareSupport = share;
        _hasShareeSupport = sharee;
        _hasCookiesSupport = cookies;
        _hasForbiddenCharactersSupport = forbiddenCharacters;
        _hasCapabilitiesSupport = capabilites;
        _hasFedSharesOptionShareSupport = fedSharesOptionShare;
    }
    
    return self;
}
@end
