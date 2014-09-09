//
//  OCHTTPSessionManager.m
//  ownCloud iOS library
//
//  Created by Rebeca Martín de León on 11/08/14.
//  Copyright (c) 2014 ownCloud. All rights reserved.
//

#import "OCHTTPSessionManager.h"

@implementation OCHTTPSessionManager

/*
 *  Delegate called when try to upload a file to a self signed server.
    This method is used on the Unit tests so it is forced to accept the certificate however it changes. In this way, if there is a redirection, the credentials are no loses
 */
- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    
        NSLog(@"willSendRequestForAuthenticationChallenge");
    
        __block NSURLCredential *credential = nil;
        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
}


@end
