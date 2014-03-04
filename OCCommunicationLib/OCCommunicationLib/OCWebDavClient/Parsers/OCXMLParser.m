//
//  OCXMLParser.m
//  webdav
//
// Copyright (c) 2014 ownCloud (http://www.owncloud.org/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//


#import "OCXMLParser.h"

NSString *OCCWebDAVContentTypeKey   = @"contenttype";
NSString *OCCWebDAVETagKey          = @"etag";
NSString *OCCWebDAVHREFKey          = @"href";
NSString *OCCWebDAVURIKey           = @"uri";

@implementation OCXMLParser

@synthesize directoryList=_directoryList;
@synthesize currentFile=_currentFile;

/*
 * Method that init the parse with the xml data from the server
 * @data -> XML webDav data from the owncloud server
 */
- (void)initParserWithData: (NSData*)data{
    
    _directoryList = [[NSMutableArray alloc]init];
    
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
    
    if ([elementName isEqualToString:@"d:response"]) {
        _xmlBucket = [NSMutableDictionary dictionary];
    }
}

/*
 * Util method to make a NSDate object from a string from xml
 * @dateString -> Data string from xml
 */

+ (NSDate*)parseDateString:(NSString*)dateString {
    
    NSDate *date;
    NSError *error = nil;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeDate error:&error];
    NSArray *matches = [detector matchesInString:dateString options:0 range:NSMakeRange(0, [dateString length])];
    for (NSTextCheckingResult *match in matches) {
        date = match.date;
        NSLog(@"Detected Date: %@", match.date);
        NSLog(@"Detected Time Zone: %@", match.timeZone);
    }
    return date;
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    // NSLog(@"elementName: %@:%@", elementName,_xmlChars);
    
    
    if ([elementName isEqualToString:@"d:href"]) {
        
        if ([_xmlChars hasPrefix:@"http"]) {
            NSURL *junk = [NSURL URLWithString:_xmlChars];
            BOOL trailingSlash = [_xmlChars hasSuffix:@"/"];
            [_xmlChars setString:[junk path]];
            if (trailingSlash) {
                [_xmlChars appendString:@"/"];
            }
        }
        
        //If has lenght, there are an item
        if ([_xmlChars length]) {
            //Create FileDto
            _currentFile = [[OCFileDto alloc] init];
            [_xmlBucket setObject:[_xmlChars copy] forKey:OCCWebDAVURIKey];
            
            NSArray *splitedUrl = [_xmlChars componentsSeparatedByString:@"/"];
            
            //Check if the item is a folder or a file
            if([_xmlChars hasSuffix:@"/"]) {
                //It's a folder
                int fileNameLenght = [((NSString *)[splitedUrl objectAtIndex:[splitedUrl count]-2]) length];
                
                if ( fileNameLenght > 0) {
                    //FileDto filepath
                    _currentFile.filePath = [_xmlChars substringToIndex:[_xmlChars length] - (fileNameLenght+1)];
                } else {
                    _currentFile.filePath = @"/";
                }
            } else {
                //It's a file
                int fileNameLenght = [((NSString *)[splitedUrl objectAtIndex:[splitedUrl count]-1]) length];
                if (fileNameLenght > 0) {
                    _currentFile.filePath = [_xmlChars substringToIndex:[_xmlChars length] - fileNameLenght];
                }else {
                    _currentFile.filePath = @"/";
                }
            }
        }
        
        NSArray *foo = [_xmlChars componentsSeparatedByString: @"/"];
        NSString *lastBit;
        
        if([_xmlChars hasSuffix:@"/"]) {
            lastBit = [foo objectAtIndex: [foo count]-2];
            lastBit = [NSString stringWithFormat:@"%@/",lastBit];
        } else {
            lastBit = [foo objectAtIndex: [foo count]-1];
        }
        
        //NSString *lastBit = [_xmlChars substringFromIndex:_uriLength];
        //NSLog(@"lastBit:- %@",lastBit);
        if (isNotFirstFileOfList == YES) {
            [_xmlBucket setObject:lastBit forKey:OCCWebDAVHREFKey];
            _currentFile.fileName = lastBit;
            
            if([_xmlChars hasSuffix:@"/"]) {
                _currentFile.isDirectory = YES;
            } else {
                _currentFile.isDirectory = NO;
            }
        }
        
        isNotFirstFileOfList = YES;
        
        //NSLog(@"1 _xmlBucked :- %@",_xmlBucket);
    }
    //DATE
    else if ([elementName isEqualToString:@"d:getlastmodified"]) {
        
        if ([_xmlChars length]) {
            NSDate *d = [[self class] parseDateString:_xmlChars];
            
            if (d) {
                //FildeDto Date
                _currentFile.date = [d timeIntervalSince1970];
                int colIdx = [elementName rangeOfString:@":"].location;
                [_xmlBucket setObject:d forKey:[elementName substringFromIndex:colIdx + 1]];
            }
            
            else {
                NSLog(@"Could not parse date string '%@' for '%@'", _xmlChars, elementName);
            }
        }
    }
    else if ([elementName hasSuffix:@":getlastmodified"]) {
        // 'Thu, 30 Oct 2008 02:52:47 GMT'
        // Monday, 12-Jan-98 09:25:56 GMT
        // Value: HTTP-date  ; defined in section 3.3.1 of RFC2068
        
        
    }
    //ETAG
    else if ([elementName hasSuffix:@":getetag"] && [_xmlChars length]) {
        NSLog(@"getetag: %@", _xmlChars);
        
        NSString *stringClean = [_xmlChars stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        NSArray *listItems = [stringClean componentsSeparatedByString:@"."];
        unsigned long long etag;
        
        NSScanner* pScanner = [NSScanner scannerWithString: [listItems objectAtIndex:0]];
        
        [pScanner scanHexLongLong: &etag];
        //FileDto etag
        
        NSLog(@"the etag is: %lld", etag);
        
        _currentFile.etag = etag;
    }
    //CONTENT TYPE
    else if ([elementName hasSuffix:@":getcontenttype"] && [_xmlChars length]) {
        [_xmlBucket setObject:[_xmlChars copy] forKey:OCCWebDAVContentTypeKey];
        
    }
    //SIZE
    else if([elementName hasSuffix:@"d:getcontentlength"] && [_xmlChars length]) {
        //FileDto current size
        _currentFile.size = [_xmlChars longLongValue];
        
    }
    
    else if ([elementName isEqualToString:@"d:response"]) {
        //NSLog(@"2 _xmlBucked :- %@",_xmlBucket);
        
        //Add to directoryList
        [_directoryList addObject:_currentFile];
        _currentFile = [[OCFileDto alloc] init];
        
        if ([_xmlBucket objectForKey:@"href"]) {
            //Directory bucket
            //[_directoryBucket addObject:_xmlBucket];
        }
        _xmlBucket = nil;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [_xmlChars appendString:string];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser{
    
    NSLog(@"Finish xml directory list parse");
}





@end
