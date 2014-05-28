//
//  OCHTTPRequestOperation.m
//  Owncloud iOs Client
//
// Copyright (C) 2014 ownCloud Inc. (http://www.owncloud.org/)
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


#import "OCHTTPRequestOperation.h"
#import "OCChunkInputStream.h"
#import "OCFrameworkConstants.h"
#import "UtilsFramework.h"

#define k_redirected_code_1 301
#define k_redirected_code_2 302
#define k_redirected_code_3 307

@interface OCHTTPRequestOperation ()
@property (readwrite, nonatomic, strong) NSMutableURLRequest *request;
@end

@implementation OCHTTPRequestOperation

@synthesize request;

#pragma mark - Redirection protection

///-----------------------------------
/// @name connection:willSendRequest:redirectResponse:
///-----------------------------------

/**
 * Connection redirected (NSURLConnection Delegate Method)
 * This method is called when the NSURLConnection detects that
 * there is a redirecction
 *
 * @param connection -> NSURLConnection
 * @param requestRed -> NSURLRequest
 * @param redirectResponse -> NSURLResponse
 *
 * @return NSURLRequest
 *
 */

- (NSURLRequest *)connection: (NSURLConnection *)connection
             willSendRequest: (NSURLRequest *)requestRed
            redirectResponse: (NSURLResponse *)redirectResponse;
{
    //If there is a redireccion
    if (redirectResponse) {
        NSLog(@"redirecction");
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) redirectResponse;
        int statusCode = [httpResponse statusCode];
        NSLog(@"HTTP status %d", statusCode);
        
        if (k_redirected_code_1 == statusCode || k_redirected_code_2 == statusCode || k_redirected_code_3 == statusCode) {
            //We get all the headers in order to obtain the Location
            NSDictionary *dict = [httpResponse allHeaderFields];
            //Server path of redirected server
            NSString *responseURLString = [dict objectForKey:@"Location"];
            //Set the URL into the request            
            [self.request setURL: [NSURL URLWithString:responseURLString]];
            
            if (_localSource) {
                //Only for uploads without chunks
                [self.request setHTTPBodyStream:[NSInputStream inputStreamWithFileAtPath:_localSource]];
            } else if (_chunkInputStream) {
                //Only for uploads with chunks
                [self.request setHTTPBodyStream:_chunkInputStream];
            }
            //Check if there is a SAML fragment on the URL string
            if ([UtilsFramework isURLWithSamlFragment:responseURLString]) {
                _redirectedServer = responseURLString;
            }
            
            return self.request;
        }
    }
    return requestRed;
}


@end
