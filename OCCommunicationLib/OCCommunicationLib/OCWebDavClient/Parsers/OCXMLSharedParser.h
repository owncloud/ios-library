//
//  OCXMLSharedParser.h
//  OCCommunicationLib
//
//  Created by javi on 1/7/14.
//  Copyright (c) 2014 ownCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCSharedDto.h"

@interface OCXMLSharedParser :  NSObject <NSXMLParserDelegate>{
    
    NSMutableString *_xmlChars;
    NSMutableDictionary *_xmlBucket;
    NSMutableArray *_shareList;
    OCSharedDto *_currentShared;
    BOOL isNotFirstFileOfList;
    
}

@property(nonatomic,strong) NSMutableArray *shareList;
@property(nonatomic,strong) OCSharedDto *currentShared;

- (void)initParserWithData: (NSData*)data;

@end
