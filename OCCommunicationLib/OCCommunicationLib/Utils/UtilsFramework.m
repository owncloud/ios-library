//
//  UtilsFramework.m
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


#import "UtilsFramework.h"
#import "OCCommunication.h"
#import "OCFrameworkConstants.h"
#import "OCErrorMsg.h"

#define kSAMLFragmentArray [NSArray arrayWithObjects: @"wayf", @"saml", nil]

@implementation UtilsFramework

/*
 * Method that check the file name or folder name to find forbiden characters
 * This is the forbiden characters in server: "\", "/","<",">",":",""","|","?","*"
 * @fileName -> file name
 */
+ (BOOL)isForbidenCharactersInFileName:(NSString*)fileName{
    BOOL thereAreForbidenCharacters=NO;
    
    
    
    //Check the filename
    for(int i =0 ;i<[fileName length]; i++) {
        
        if ([fileName characterAtIndex:i]=='/'){
            thereAreForbidenCharacters=YES;
        }
        if ([fileName characterAtIndex:i]=='\\'){
            thereAreForbidenCharacters=YES;
        }
        
        if ([fileName characterAtIndex:i]=='<'){
            thereAreForbidenCharacters=YES;
        }
        if ([fileName characterAtIndex:i]=='>'){
            thereAreForbidenCharacters=YES;
        }
        if ([fileName characterAtIndex:i]=='"'){
            thereAreForbidenCharacters=YES;
        }
        if ([fileName characterAtIndex:i]==','){
            thereAreForbidenCharacters=YES;
        }
        if ([fileName characterAtIndex:i]==':'){
            thereAreForbidenCharacters=YES;
        }
        if ([fileName characterAtIndex:i]=='|'){
            thereAreForbidenCharacters=YES;
        }
        if ([fileName characterAtIndex:i]=='?'){
            thereAreForbidenCharacters=YES;
        }
        if ([fileName characterAtIndex:i]=='*'){
            thereAreForbidenCharacters=YES;
        }
        
        
    }
    
    return thereAreForbidenCharacters;
}

///-----------------------------------
/// @name getErrorByCodeId
///-----------------------------------

/**
 * Method to return a Error with description from a OC Error code
 *
 * @param int -> errorCode number to identify the OC Error
 *
 * @return NSError
 *
 */
+ (NSError *) getErrorByCodeId:(int) errorCode {
    NSError *error = nil;
    
    switch (errorCode) {
        case OCErrorForbidenCharacters:
        {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"You have entered forbbiden characters" forKey:NSLocalizedDescriptionKey];
            
            error = [NSError errorWithDomain:k_domain_error_code code:OCErrorForbidenCharacters userInfo:details];
            break;
        }
            
        case OCErrorMovingDestinyNameHaveForbiddenCharacters:
        {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"The file or folder that you are moving have forbidden characters" forKey:NSLocalizedDescriptionKey];
            
            error = [NSError errorWithDomain:k_domain_error_code code:OCErrorMovingDestinyNameHaveForbiddenCharacters userInfo:details];
            break;
        }
            
        case OCErrorMovingTheDestinyAndOriginAreTheSame:
        {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"You are trying to move the file to the same folder" forKey:NSLocalizedDescriptionKey];
            
            error = [NSError errorWithDomain:k_domain_error_code code:OCErrorMovingTheDestinyAndOriginAreTheSame userInfo:details];
            break;
        }
            
        case OCErrorMovingFolderInsideHimself:
        {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"You are trying to move a folder inside himself" forKey:NSLocalizedDescriptionKey];
            
            error = [NSError errorWithDomain:k_domain_error_code code:OCErrorMovingFolderInsideHimself userInfo:details];
            break;
        }
            
        case kOCErrorServerPathNotFound:
        {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"You are trying to access to a file that does not exist" forKey:NSLocalizedDescriptionKey];
            
            error = [NSError errorWithDomain:k_domain_error_code code:kOCErrorServerPathNotFound userInfo:details];
            break;
        }
            
        case kOCErrorServerForbidden:
        {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"You are trying to do a forbbiden operation" forKey:NSLocalizedDescriptionKey];
            
            error = [NSError errorWithDomain:k_domain_error_code code:kOCErrorServerForbidden userInfo:details];
            break;
        }
            
        default:
        {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"Unknow error" forKey:NSLocalizedDescriptionKey];
            
            error = [NSError errorWithDomain:k_domain_error_code code:OCErrorUnknow userInfo:details];
            break;
        }
    }
    
    return error;
}

///-----------------------------------
/// @name getFileNameOrFolderByPath
///-----------------------------------

/**
 * Method that return a filename from a path
 *
 * @param NSString -> path of the file (including the file)
 *
 * @return NSString -> fileName
 *
 */
+ (NSString *) getFileNameOrFolderByPath:(NSString *) path {
    
    NSString *output;
    
    if (path && [path length] > 0) {
        NSArray *listItems = [path componentsSeparatedByString:@"/"];
        
        output = [listItems objectAtIndex:[listItems count]-1];
        
        if ([output length] <= 0) {
            output = [listItems objectAtIndex:[listItems count]-2];
        }
        
        //If is a folder we set the last character in order to compare folders with folders and files with files
        /*if([path hasSuffix:@"/"]) {
         output = [NSString stringWithFormat:@"%@/", output];
         }*/
    }
    
    return  output;
}

/*
 * Method that return a boolean that indicate if is the same url
 */
+ (BOOL) isTheSameFileOrFolderByNewURLString:(NSString *) newURLString andOriginURLString:(NSString *)  originalURLString{
    
    
    if ([originalURLString isEqualToString:newURLString]) {
        return YES;
    }
    
    return NO;
    
}

/*
 * Method that return a boolean that indicate if newUrl is under the original Url
 */
+ (BOOL) isAFolderUnderItByNewURLString:(NSString *) newURLString andOriginURLString:(NSString *)  originalURLString{
    
    if([originalURLString length] < [newURLString length]) {
        
        NSString *subString = [newURLString substringToIndex: [originalURLString length]];
        
        if([originalURLString isEqualToString: subString]){
            
            newURLString = [newURLString substringFromIndex:[subString length]];
            
            if ([newURLString rangeOfString:@"/"].location == NSNotFound) {
                //Is a rename of the last part of the file or folder
                return NO;
            } else {
                //Is a move inside himself
                return YES;
            }
        }
    }
    return NO;
    
}

///-----------------------------------
/// @name getSizeInBytesByPath
///-----------------------------------

/**
 * Method to return the size of a file by a path
 *
 * @param NSString -> path of the file
 *
 * @return long long -> size of the file in the path
 */
+ (long long) getSizeInBytesByPath:(NSString *)path {
    long long fileLength = [[[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] valueForKey:NSFileSize] unsignedLongLongValue];
    
    return fileLength;
}





///-----------------------------------
/// @name isURLWithSamlFragment:
///-----------------------------------

/**
 * Method to check a url string to looking for a SAML fragment
 *
 * @param urlString -> url from redirect server
 *
 * @return BOOL -> the result about if exist the SAML fragment or not
 */
+ (BOOL) isURLWithSamlFragment:(NSString*)urlString {
    
    urlString = [urlString lowercaseString];
    
    if (urlString) {
        for (NSString* samlFragment in kSAMLFragmentArray) {
            if ([urlString rangeOfString:samlFragment options:NSCaseInsensitiveSearch].location != NSNotFound) {
                NSLog(@"A SAML fragment is in the request url");
                return YES;
            }
        }
    }
    return NO;
}

+ (NSString *) AFBase64EncodedStringFromString:(NSString *) string {
    NSData *data = [NSData dataWithBytes:[string UTF8String] length:[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    NSUInteger length = [data length];
    NSMutableData *mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    
    uint8_t *input = (uint8_t *)[data bytes];
    uint8_t *output = (uint8_t *)[mutableData mutableBytes];
    
    for (NSUInteger i = 0; i < length; i += 3) {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        static uint8_t const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        
        NSUInteger idx = (i / 3) * 4;
        output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kAFBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kAFBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
}


@end
