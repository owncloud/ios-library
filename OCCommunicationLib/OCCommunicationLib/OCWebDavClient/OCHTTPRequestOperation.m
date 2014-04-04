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


#define k_redirected_code_1 301
#define k_redirected_code_2 302
#define k_redirected_code_3 307

typedef enum {
    AFOperationPausedState      = -1,
    AFOperationReadyState       = 1,
    AFOperationExecutingState   = 2,
    AFOperationFinishedState    = 3,
} _AFOperationState;

typedef signed short AFOperationState;

@interface OCHTTPRequestOperation ()
@property (readwrite, nonatomic, strong) NSMutableURLRequest *request;
@end


@implementation OCHTTPRequestOperation

//Necessary method copied of AFURLConnectionOperation class for use "start" override method
+ (void) __attribute__((noreturn)) networkRequestThreadEntryPoint:(id)__unused object {
    do {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] run];
        }
    } while (YES);
}

//Necessary method copied of AFURLConnectionOperation class for use "start" override method
+ (NSThread *)networkRequestThread {
    static NSThread *_networkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
        [_networkRequestThread start];
    });
    
    return _networkRequestThread;
}


#pragma mark - Redirection protection

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
            NSHTTPURLResponse *hr = (NSHTTPURLResponse*)redirectResponse;
            NSDictionary *dict = [hr allHeaderFields];
            
            //Server path of redirected server
            NSString *responseURLString = [dict objectForKey:@"Location"];
            
            
            [self.request setURL: [NSURL URLWithString:responseURLString]];
            
            if (_localSource) {
                //Only for uploads without chunks
                [self.request setHTTPBodyStream:[NSInputStream inputStreamWithFileAtPath:_localSource]];
            }
            if (_chunkInputStream) {
                //Only for uploads with chunks
                [self.request setHTTPBodyStream:_chunkInputStream];
            }
            
            //For uploads we store the redirections of the request
            if (_typeOfOperation == UploadQueue) {
                //We only need the first redirecttion for SAML
                if (!_redirectedServer) {
                    _redirectedServer = requestRed.URL.absoluteString;
                }
            } else {
                _redirectedServer = redirectResponse.URL.absoluteString;
            }
            
            return self.request;
        }
    }
    
    
    return requestRed;
}


///-----------------------------------
/// @name Start
///-----------------------------------

/**
 * Override this method of AFURLConnectionOperation because when there are
 * some downloads paused and the user cancel some of this
 */
- (void)start {
    
    [super start];
    
    //Check if the operation is not in execution and is a download type
    if (!self.isExecuting && self.typeOfOperation == DownloadQueue) {
          //Launch the start method
          [self performSelector:@selector(operationDidStart) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    }

}



@end
