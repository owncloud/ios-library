//
//  UtilsFramework.m
//  Owncloud iOs Client
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


#import "UtilsFramework.h"
#import "OCCommunication.h"
#import "OCFrameworkConstants.h"

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
        if([originalURLString isEqualToString:[newURLString substringToIndex: [originalURLString length]]]){
            return YES;
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

@end
