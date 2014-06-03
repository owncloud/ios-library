//
//  UtilsFramework.h
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

#import <Foundation/Foundation.h>

@interface UtilsFramework : NSObject

/*
 * Method that check the file name or folder name to find forbiden characters
 * This is the forbiden characters in server: "\", "/","<",">",":",""","|","?","*"
 * @fileName -> file name
 */
+ (BOOL) isForbidenCharactersInFileName:(NSString*)fileName;


///-----------------------------------
/// @name getErrorByCodeId
///-----------------------------------

/**
 * Method to return a NSError based on the Error Code Enum
 *
 * @param int errorCode to Enum to identify the error code
 *
 * @return NSError
 */
+ (NSError *) getErrorByCodeId:(int) errorCode;

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
+ (NSString *) getFileNameOrFolderByPath:(NSString *) path;

/*
 * Method that return a boolean that indicate if is the same url
 */
+ (BOOL) isTheSameFileOrFolderByNewURLString:(NSString *) newURLString andOriginURLString:(NSString *)  originalURLString;

/*
 * Method that return a boolean that indicate if newUrl is under the original Url
 */
+ (BOOL) isAFolderUnderItByNewURLString:(NSString *) newURLString andOriginURLString:(NSString *)  originalURLString;

/**
 * Method to return the size of a file by a path
 *
 * @param NSString -> path of the file
 *
 * @return long long -> size of the file in the path
 */
+ (long long) getSizeInBytesByPath:(NSString *) path;


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
+ (BOOL) isURLWithSamlFragment:(NSString*)urlString;

///-----------------------------------
/// @name AFBase64EncodedStringFromString:
///-----------------------------------

/**
 * Method encode a string to base64 in order to set the credentials
 *
 * @param string -> string to be encoding
 *
 * @return NSString -> the result of the encoded string
 */
+ (NSString *) AFBase64EncodedStringFromString:(NSString *) string;

@end
