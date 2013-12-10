//
//  OCHTTPRequestOperation.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 12/11/13.
//
//

#import "OCHTTPRequestOperation.h"

#define k_redirected_code 302
#define k_other_redirected_code 307

@interface OCHTTPRequestOperation ()
@property (readwrite, nonatomic, strong) NSMutableURLRequest *request;
@end

@implementation OCHTTPRequestOperation


#pragma mark - Redirection protection

- (NSURLRequest *)connection: (NSURLConnection *)connection
             willSendRequest: (NSURLRequest *)requestRed
            redirectResponse: (NSURLResponse *)redirectResponse;
{
    if (redirectResponse) {
        
        NSLog(@"redirecction");
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) redirectResponse;
        int statusCode = [httpResponse statusCode];
        NSLog(@"HTTP status %d", statusCode);
        
        if (k_redirected_code == 302 || k_other_redirected_code == 307) {
            
            //URL of redirected server
           /* NSString *responseURLString = redirectResponse.URL.absoluteString;
            NSLog(@"Response url is: %@", responseURLString);
            NSLog(@"Request url is: %@", requestRed.URL.absoluteString);*/
            
            //we stores the redirection of the response
            _redirectedServer = redirectResponse.URL.absoluteString;
            
            //For uploads we store the redirections of the request
            if (_typeOfOperation == UploadQueue) {
                _redirectedServer = requestRed.URL.absoluteString;
                
                //Cancel the upload
                
                //[self cancel];
            }
        }
        
        [self.request setURL: [requestRed URL]];
        
        return self.request;
        
    } else {
        //NSLog(@"no redirection");
        return requestRed;
    }
}


@end
