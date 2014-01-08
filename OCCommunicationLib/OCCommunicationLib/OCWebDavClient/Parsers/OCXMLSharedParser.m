//
//  OCXMLSharedParser.m
//  OCCommunicationLib
//
//  Created by javi on 1/7/14.
//  Copyright (c) 2014 ownCloud. All rights reserved.
//

#import "OCXMLSharedParser.h"
#import "OCSharedDto.h"

@implementation OCXMLSharedParser

@synthesize shareList=_shareList;
@synthesize currentShared=_currentShared;

/*
 * Method that init the parse with the xml data from the server
 * @data -> XML webDav data from the owncloud server
 */
- (void)initParserWithData: (NSData*)data{
    
    _shareList = [[NSMutableArray alloc]init];
    
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
    
    if ([elementName isEqualToString:@"element"]) {
        _xmlBucket = [NSMutableDictionary dictionary];
    }
}

/*
 * Util method to make a NSDate object from a string from xml
 * @dateString -> Data string from xml
 */

+ (NSDate*)parseDateString:(NSString*)dateString {
    
    //2014-01-10 00:00:00
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-mm-dd HH:mm:ss"];
    [dateFormat setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSDate *date = [dateFormat dateFromString:dateString];
    
    return date;
    
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    NSLog(@"elementName: %@:%@", elementName,_xmlChars);
    /*
    @property BOOL isDirectory;
    @property int itemSource;
    @property int shareType;
    @property (nonatomic, copy) NSString *shareWith;
    @property int fileSource;
    @property (nonatomic, copy) NSString *path;
    @property int permissions;
    @property long sharedDate;
    @property long expirationDate;
    @property (nonatomic, copy) NSString *token;
    @property (nonatomic, copy) NSString *shareWithDisplayname;
     */
    
    if ([elementName isEqualToString:@"item_type"]) {
        _currentShared = [[OCSharedDto alloc] init];
        
        if([_xmlChars isEqualToString:@"file"]) {
            _currentShared.isDirectory = NO;
        } else {
            _currentShared.isDirectory = YES;
        }
            
    } else if ([elementName isEqualToString:@"item_source"]) {
        
        _currentShared.itemSource = [_xmlChars intValue];
    
    } else if ([elementName isEqualToString:@"parent"]) {
        
        _currentShared.parent = [_xmlChars intValue];
        
    } else if ([elementName isEqualToString:@"share_type"]) {
        
        _currentShared.shareType = [_xmlChars intValue];
        
    } else if ([elementName isEqualToString:@"share_with"]) {
        
        _currentShared.shareWith = _xmlChars;
        
    } else if ([elementName isEqualToString:@"file_source"]) {
        
        _currentShared.fileSource = [_xmlChars intValue];
        
    } else if ([elementName isEqualToString:@"path"]) {
    
        _currentShared.path = _xmlChars;
    
    } else if ([elementName isEqualToString:@"permissions"]) {
        
        _currentShared.permissions = [_xmlChars intValue];
        
    } else if ([elementName isEqualToString:@"stime"]) {
        
        _currentShared.sharedDate = [_xmlChars longLongValue];
        
    } else if ([elementName isEqualToString:@"expiration"]) {
        
        NSDate *date = [[self class] parseDateString:_xmlChars];
        _currentShared.sharedDate = [date timeIntervalSince1970];
        
    } else if ([elementName isEqualToString:@"token"]) {
        
        _currentShared.token = _xmlChars;
        
    } else if ([elementName isEqualToString:@"storage"]) {
        
        _currentShared.storage = [_xmlChars intValue];
        
    } else if ([elementName isEqualToString:@"mail_send"]) {
        
        _currentShared.mailSend = [_xmlChars intValue];
        
    } else if ([elementName isEqualToString:@"uid_owner"]) {
        
        _currentShared.uidOwner = _xmlChars;
        
    } else if ([elementName isEqualToString:@"share_with_displayname"]) {
        
        _currentShared.shareWithDisplayName = _xmlChars;
        
    } else if ([elementName isEqualToString:@"displayname_owner"]) {
        
        _currentShared.displayNameOwner = _xmlChars;
        
        //Last value on the XML so we add the object to the array and begin again
        if (!_currentShared.shareWithDisplayName) {
            //To not have a nil we set an empty string
            _currentShared.shareWithDisplayName = @"";
        }

        [_shareList addObject:_currentShared];
        _currentShared = [OCSharedDto new];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [_xmlChars appendString:string];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser{
    
    NSLog(@"Finish xml directory list parse");
}


@end
