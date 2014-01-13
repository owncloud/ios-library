//
//  OCXMLShareByLinkParser.h
//  OCCommunicationLib
//
//  Created by javi on 1/13/14.
//  Copyright (c) 2014 ownCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OCXMLShareByLinkParser : NSObject <NSXMLParserDelegate>{
    
    NSMutableString *_xmlChars;
    NSMutableDictionary *_xmlBucket;
    NSMutableArray *_shareList;
    NSString *token;
    BOOL isNotFirstFileOfList;
    
}

@property(nonatomic,strong) NSMutableArray *shareList;
@property(nonatomic,strong) NSString *token;

- (void)initParserWithData: (NSData*)data;

@end
