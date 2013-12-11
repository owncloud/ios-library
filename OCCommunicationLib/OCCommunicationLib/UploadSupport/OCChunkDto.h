//
//  OCChunkDto.h
//  Owncloud iOs Client
//
//  Created by javi on 11/19/13.
//
//

#import <Foundation/Foundation.h>

@interface OCChunkDto : NSObject {

    NSNumber *position;
    NSNumber *size;
    NSString *remotePath;
}

@property (nonatomic, copy) NSNumber *position;
@property (nonatomic, copy) NSNumber *size;
@property (nonatomic, copy) NSString *remotePath;

@end
