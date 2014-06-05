//
//  OCURLSessionManager.m
//  ownCloud iOS library
//
//  Created by Javier Gonzalez on 05/06/14.
//  Copyright (c) 2014 ownCloud. All rights reserved.
//

#import "OCURLSessionManager.h"

@implementation OCURLSessionManager

/*
 *  Delegate called when try to upload a file to a self signed server
 */
- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    __block NSURLCredential *credential = nil;
    
    credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
}

@end
