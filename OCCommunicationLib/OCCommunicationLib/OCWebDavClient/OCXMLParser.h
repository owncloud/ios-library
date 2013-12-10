//
//  OCXMLParser.h
//  webdav
//
//
//  Created by Gonzalo Gonzalez on 27/05/13.
//


#import <Foundation/Foundation.h>
#import "OCFileDto.h"

/*enum {
 OCWebDAVDirectoryListing    = 1,
 };*/


@interface OCXMLParser : NSObject <NSXMLParserDelegate>{
    
    NSMutableString *_xmlChars;
    NSMutableDictionary *_xmlBucket;
    //  NSUInteger _parseState;
    
    NSMutableArray *_directoryList;
    OCFileDto *_currentFile;
    
    BOOL isNotFirstFileOfList;
    
    
}

@property(nonatomic,strong) NSMutableArray *directoryList;
@property(nonatomic,strong) OCFileDto *currentFile;

- (void)initParserWithData: (NSData*)data;

@end
