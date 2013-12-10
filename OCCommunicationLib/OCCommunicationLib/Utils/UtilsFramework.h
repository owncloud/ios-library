//
//  UtilsFramework.h
//  Owncloud iOs Client
//
//  Created by javi on 10/18/13.
//
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


@end
