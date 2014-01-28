//
//  OCXMLShareByLinkParser.m
//  OCCommunicationLib
//
//  Created by javi on 1/13/14.
//  Copyright (c) 2014 ownCloud. All rights reserved.
//

#import "OCXMLShareByLinkParser.h"

@implementation OCXMLShareByLinkParser

@synthesize token=_token;

/*
 * Method that init the parse with the xml data from the server
 * @data -> XML webDav data from the owncloud server
 */
- (void)initParserWithData: (NSData*)data{
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    [parser parse];
    
}


#pragma mark - XML Parser Delegate Methods


/*
 * Method that init parse process.
 */

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    if (!_xmlChars) {
        _xmlChars = [NSMutableString string];
    }
    
    //NSLog(@"_xmlChars: %@", _xmlChars);
    
    [_xmlChars setString:@""];
    
    if ([elementName isEqualToString:@"ocs"]) {
        _xmlBucket = [NSMutableDictionary dictionary];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    NSLog(@"elementName: %@:%@", elementName,_xmlChars);
    
    if ([elementName isEqualToString:@"statuscode"]) {
        _statusCode = [_xmlChars intValue];
    }

    if ([elementName isEqualToString:@"token"]) {
        _token = _xmlChars;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [_xmlChars appendString:string];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser{
    
    NSLog(@"Finish xml directory list parse");
}

@end
