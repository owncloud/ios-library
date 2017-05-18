//
//  OCServerFeatures.h
//  ownCloud iOS library
//
//  Created by Noelia Alvarez on 05/04/17.
//  Copyright © 2017 ownCloud. All rights reserved.
//

@interface OCServerFeatures : NSObject

@property BOOL hasShareSupport;
@property BOOL hasShareeSupport;
@property BOOL hasCookiesSupport;
@property BOOL hasForbiddenCharactersSupport;
@property BOOL hasCapabilitiesSupport;
@property BOOL hasFedSharesOptionShareSupport;
@property BOOL hasPublicShareLinkOptionNameSupport;

- (id)initWithSupportForShare:(BOOL)share sharee:(BOOL)sharee cookies:(BOOL)cookies forbiddenCharacters:(BOOL)forbiddenCharacters capabilities:(BOOL)capabilites fedSharesOptionShare:(BOOL)fedSharesOptionShare publicShareLinkOptionName:(BOOL)publicShareLinkOptionName;

@end
