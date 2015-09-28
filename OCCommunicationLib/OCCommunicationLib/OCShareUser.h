//
//  OCShareUser.h
//  ownCloud iOS library
//
//  Created by Gonzalo Gonzalez on 28/9/15.
//  Copyright © 2015 ownCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OCShareUser : NSObject

@property (nonatomic, strong) NSString *name;
@property BOOL isGroup;

@end
