//
//  Owncloud_iOs_ClientTests.m
//  Owncloud iOs ClientTests
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


#import "OCCommunicationLibTests.h"
#import "OCCommunication.h"
#import "OCFrameworkConstants.h"
#import "OCFileDto.h"

@implementation OCCommunicationLibTests

//User, pass and server to make the tests
static NSString *user = @"oclibrarytest";
static NSString *password = @"123456";
static NSString *baseUrl = @"https://beta.owncloud.com/owncloud/remote.php/webdav/";

/*Structure to test on server:
 /Tests/Folder A/Test.jpeg
 /Tests/Folder B/
 */

///-----------------------------------
/// @name setUp
///-----------------------------------

/**
 * Method to get ready the tests
 */
- (void)setUp
{
    [super setUp];
    
	_sharedOCCommunication = [[OCCommunication alloc] init];
    [_sharedOCCommunication setCredentialsWithUser:user andPassword:password];
	
    
    //Create some folders
    
    //1. Create Tests folder
    [self createFolderWithName:@"Tests"];
    
    //2. Create Tests/Folder A
    [self createFolderWithName:@"Tests/Folder A"];
    
    //3. Create Test/Folder B
    [self createFolderWithName:@"Tests/Folder B"];
    
    //4. Create Test/Folder C
    [self createFolderWithName:@"Tests/Folder C"];
    
    
    
    
    
}

- (void)tearDown
{
    // 1. Delete Test folder
    [self deleteFolderWithName:@"Tests"];
    
    [super tearDown];
}

#pragma mark - SetUp Methods

- (void) createFolderWithName:(NSString*)path{
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSString *folder = [NSString stringWithFormat:@"%@%@",baseUrl,path];
     folder = [folder stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [_sharedOCCommunication createFolder:folder onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        //Folder created
        NSLog(@"Folder %@ created", folder);
        dispatch_semaphore_signal(semaphore);
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
       NSLog(@"Error created:%@ folder", folder);
        // Signal that block has completed
        dispatch_semaphore_signal(semaphore);
    } errorBeforeRequest:^(NSError *error) {
        NSLog(@"Error created:%@ folder", folder);
        // Signal that block has completed
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);

}

- (void) deleteFolderWithName:(NSString *)path{
    
    NSString *folder = [NSString stringWithFormat:@"%@%@",baseUrl,path];
    folder = [folder stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //We create a semaphore to wait until we recive the responses from Async calls
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [_sharedOCCommunication deleteFileOrFolder:folder onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse * response, NSString *redirectedServer) {
        //Folder deleted
        NSLog(@"Folder deleted");
        dispatch_semaphore_signal(semaphore);
    } failureRquest:^(NSHTTPURLResponse * response, NSError * error) {
        //Error
        XCTFail(@"Error testDeleteFolder: %@", error);
        // Signal that block has completed
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    dispatch_release(semaphore);
    
    
}


#pragma mark - Tests

///-----------------------------------
/// @name testCreateFolder
///-----------------------------------

/**
 * Method to test if we can create a folder
 */
- (void)testCreateFolder
{
    //We create a semaphore to wait until we recive the responses from Async calls
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSString *folder = [NSString stringWithFormat:@"%@Tests/%@",baseUrl,[NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]]];
    
    [_sharedOCCommunication createFolder:folder onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        //Folder created
        NSLog(@"Folder created");
        dispatch_semaphore_signal(semaphore);
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        XCTFail(@"Error testCreateFolder: %@", error);
        // Signal that block has completed
        dispatch_semaphore_signal(semaphore);
    } errorBeforeRequest:^(NSError *error) {
        XCTFail(@"Error testCreateFolder: %@", error);
        // Signal that block has completed
        dispatch_semaphore_signal(semaphore);
    }];
    
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);
}

///-----------------------------------
/// @name testCreateFolderWithForbiddenCharacters
///-----------------------------------

/**
 * Method to check if we check the forbidden characters when we try to create a folder
 *
 * @warning The special characters are: "\","<",">",":",""","|","?","*"
 */

/*- (void)testCreateFolderWithForbiddenCharacters
{
    NSArray* arrayForbiddenCharacters = [NSArray arrayWithObjects:@"\\",@"<",@">",@":",@"\"",@"|",@"?",@"*", nil];
    
    for (NSString *currentCharacer in arrayForbiddenCharacters) {
        NSString *folder = [NSString stringWithFormat:@"%@Tests/%@",baseUrl,[NSString stringWithFormat:@"%f%@-folder", [NSDate timeIntervalSinceReferenceDate], currentCharacer]];
        
        //We create a semaphore to wait until we recive the responses from Async calls
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        [_sharedOCCommunication createFolder:folder onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
            //Folder created
            NSLog(@"Folder created");
            XCTFail(@"Error testCreateFolderWithSpecialCharacters problem on: %@", currentCharacer);
            dispatch_semaphore_signal(semaphore);
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
            XCTFail(@"Error testCreateFolderWithSpecialCharacters problem on: %@", currentCharacer);
            // Signal that block has completed
            dispatch_semaphore_signal(semaphore);
        } errorBeforeRequest:^(NSError *error) {
            NSLog(@"Forbbiden character detected: %@", currentCharacer);
            // Signal that block has completed
            dispatch_semaphore_signal(semaphore);
        }];
        
        // Run loop
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
        dispatch_release(semaphore);
    }
}*/

///-----------------------------------
/// @name testMoveFileOnSameFolder
///-----------------------------------

/**
 * Method to test move file on the same folder
 */
/*- (void)testMoveFileOnSameFolder {
    NSString *origin = [NSString stringWithFormat:@"%@Tests/Folder A/Test.jpeg", baseUrl];
    NSString *destiny = [NSString stringWithFormat:@"%@Tests/Folder A/Test.jpeg", baseUrl];
    
    //We create a semaphore to wait until we recive the responses from Async calls
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [_sharedOCCommunication moveFileOrFolder:origin toDestiny:destiny onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        XCTFail(@"File Moved on the same folder");
        dispatch_semaphore_signal(semaphore);
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        XCTFail(@"Error moving file on the same folder Response: %@ and Error: %@", response, error);
        dispatch_semaphore_signal(semaphore);
    } errorBeforeRequest:^(NSError *error) {
        if (error.code == OCErrorMovingTheDestinyAndOriginAreTheSame) {
            NSLog(@"File on the same folder not moved");
        } else {
            XCTFail(@"Error moving file on same folder: %@", error);
        }
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);
}*/

///-----------------------------------
/// @name testMoveFile
///-----------------------------------

/**
 * Method to try move a file
 */
/*- (void)testMoveFile {
    
    NSString *origin = [NSString stringWithFormat:@"%@Tests/Folder A/Test.jpeg", baseUrl];
    NSString *destiny = [NSString stringWithFormat:@"%@Tests/Folder B/Test.jpeg", baseUrl];
    
    //We create a semaphore to wait until we recive the responses from Async calls
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [_sharedOCCommunication moveFileOrFolder:origin toDestiny:destiny onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        NSLog(@"File moved");
        dispatch_semaphore_signal(semaphore);
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        XCTFail(@"Error moving file Response: %@ and Error: %@", response, error);
        dispatch_semaphore_signal(semaphore);
    } errorBeforeRequest:^(NSError *error) {
        XCTFail(@"Error moving file: %@", error);
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);
}*/

///-----------------------------------
/// @name testMoveFileForbiddenCharacters
///-----------------------------------

/**
 * Method to try to move a file with destiny name have forbidden characters
 */
/*- (void)testMoveFileForbiddenCharacters {
    
    NSArray *arrayForbiddenCharacters = [NSArray arrayWithObjects:@"\\",@"<",@">",@":",@"\"",@"|",@"?",@"*", nil];
    
    for (NSString *currentCharacter in arrayForbiddenCharacters) {
        NSString *origin = [NSString stringWithFormat:@"%@Tests/Folder A/Test.jpeg", baseUrl];
        NSString *destiny = [NSString stringWithFormat:@"%@Tests/Folder C/Test%@.jpeg", baseUrl, currentCharacter];
        
        //We create a semaphore to wait until we recive the responses from Async calls
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        [_sharedOCCommunication moveFileOrFolder:origin toDestiny:destiny onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
            XCTFail(@"File Moved and renamed");
            dispatch_semaphore_signal(semaphore);
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
            XCTFail(@"Error moving file and renamed Response: %@ and Error: %@", response, error);
            dispatch_semaphore_signal(semaphore);
        } errorBeforeRequest:^(NSError *error) {
            if (error.code == OCErrorMovingDestinyNameHaveForbiddenCharacters) {
                NSLog(@"File with forbidden characters not moved");
            } else {
                XCTFail(@"Error moving and renaming file: %@", error);
            }
            
            dispatch_semaphore_signal(semaphore);
        }];
        
        // Run loop
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
        dispatch_release(semaphore);
    }
}*/

///-----------------------------------
/// @name testMoveFolderInsideHimself
///-----------------------------------

/**
 * Method to try to move a folder inside himself
 */
/*- (void)testMoveFolderInsideHimself {
    
    NSString *origin = [NSString stringWithFormat:@"%@Tests/Folder A/", baseUrl];
    NSString *destiny = [NSString stringWithFormat:@"%@Tests/Folder A/Folder A/", baseUrl];
    
    //We create a semaphore to wait until we recive the responses from Async calls
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [_sharedOCCommunication moveFileOrFolder:origin toDestiny:destiny onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        XCTFail(@"Folder Moved inside himself");
        dispatch_semaphore_signal(semaphore);
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        XCTFail(@"Error moving folder inside himself Response: %@ and Error: %@", response, error);
        dispatch_semaphore_signal(semaphore);
    } errorBeforeRequest:^(NSError *error) {
        if (error.code == OCErrorMovingFolderInsideHimself) {
            NSLog(@"File renamed not moved");
        } else {
            XCTFail(@"Error moving folder inside himself: %@", error);
        }
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);
}*/

///-----------------------------------
/// @name testMoveFolder
///-----------------------------------

/**
 * Method to try to move a folder
 */
/*- (void)testMoveFolder {
    NSString *origin = [NSString stringWithFormat:@"%@Tests/Folder A/", baseUrl];
    NSString *destiny = [NSString stringWithFormat:@"%@Tests/Folder B/Folder A/", baseUrl];
    
    //We create a semaphore to wait until we recive the responses from Async calls
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [_sharedOCCommunication moveFileOrFolder:origin toDestiny:destiny onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        NSLog(@"Folder Moved");
        dispatch_semaphore_signal(semaphore);
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        XCTFail(@"Error moving folder Response: %@ and Error: %@", response, error);
        dispatch_semaphore_signal(semaphore);
    } errorBeforeRequest:^(NSError *error) {
        XCTFail(@"Error moving folder: %@", error);
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);
}*/

///-----------------------------------
/// @name testRenameFileWithForbiddenCharacters
///-----------------------------------

/**
 * Method  try to rename a file with forbidden characters
 *
 */
/*- (void)testRenameFileWithForbiddenCharacters {
    
    NSArray *arrayForbiddenCharacters = [NSArray arrayWithObjects:@"\\",@"<",@">",@":",@"\"",@"|",@"?",@"*", nil];
    
    for (NSString *currentCharacter in arrayForbiddenCharacters) {
        
        NSString *origin = [NSString stringWithFormat:@"%@Tests/Folder B/Test.jpeg", baseUrl];
        NSString *destiny = [NSString stringWithFormat:@"%@Tests/Folder B/Test-%@.jpeg", baseUrl, currentCharacter];
        
        //We create a semaphore to wait until we recive the responses from Async calls
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        [_sharedOCCommunication moveFileOrFolder:origin toDestiny:destiny onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
            XCTFail(@"File renamed with forbidden characters");
            dispatch_semaphore_signal(semaphore);
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
            XCTFail(@"Error renaming file with forbidden characters Response: %@ and Error: %@", response, error);
            dispatch_semaphore_signal(semaphore);
        } errorBeforeRequest:^(NSError *error) {
            if (error.code == OCErrorMovingDestinyNameHaveForbiddenCharacters) {
                NSLog(@"File not renamed with forbidden characters");
                dispatch_semaphore_signal(semaphore);
            } else {
                XCTFail(@"Error renaming file with forbidden characters: %@", error);
                dispatch_semaphore_signal(semaphore);
            }
        }];
        
        // Run loop
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
        dispatch_release(semaphore);
    }
}*/

///-----------------------------------
/// @name testRenameFile
///-----------------------------------

/**
 * Method  try to rename a file
 *
 */
/*- (void)testRenameFile {
    NSString *origin = [NSString stringWithFormat:@"%@Tests/Folder B/Test.jpeg", baseUrl];
    NSString *destiny = [NSString stringWithFormat:@"%@Tests/Folder B/Test Renamed.jpeg", baseUrl];
    
    //We create a semaphore to wait until we recive the responses from Async calls
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [_sharedOCCommunication moveFileOrFolder:origin toDestiny:destiny onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        NSLog(@"File Renamed");
        dispatch_semaphore_signal(semaphore);
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        XCTFail(@"Error renaming file Response: %@ and Error: %@", response, error);
        dispatch_semaphore_signal(semaphore);
    } errorBeforeRequest:^(NSError *error) {
        XCTFail(@"Error renaming file: %@", error);
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);
}*/

///-----------------------------------
/// @name testRenameFolderWithForbiddenCharacters
///-----------------------------------

/**
 * Method  try to rename a folder with forbidden characters
 *
 */
/*- (void)testRenameFolderWithForbiddenCharacters {
    
    NSArray *arrayForbiddenCharacters = [NSArray arrayWithObjects:@"\\",@"<",@">",@":",@"\"",@"|",@"?",@"*", nil];
    
    for (NSString *currentCharacter in arrayForbiddenCharacters) {
        NSString *origin = [NSString stringWithFormat:@"%@Tests/Folder B/", baseUrl];
        NSString *destiny = [NSString stringWithFormat:@"%@Tests/Folder B-%@/", baseUrl, currentCharacter];
        
        //We create a semaphore to wait until we recive the responses from Async calls
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        [_sharedOCCommunication moveFileOrFolder:origin toDestiny:destiny onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
            XCTFail(@"Folder renamed with forbidden characters");
            dispatch_semaphore_signal(semaphore);
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
            XCTFail(@"Error renaming folder with forbidden characters Response: %@ and Error: %@", response, error);
            dispatch_semaphore_signal(semaphore);
        } errorBeforeRequest:^(NSError *error) {
            if (error.code == OCErrorMovingDestinyNameHaveForbiddenCharacters) {
                NSLog(@"Folder not renamed with forbidden characters");
                dispatch_semaphore_signal(semaphore);
            } else {
                XCTFail(@"Error renaming folder with forbidden characters: %@", error);
                dispatch_semaphore_signal(semaphore);
            }
        }];
        
        // Run loop
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
        dispatch_release(semaphore);
    }
}*/

///-----------------------------------
/// @name testRenameFolder
///-----------------------------------

/**
 * Method  try to rename a folder
 *
 */
/*- (void)testRenameFolder {
    NSString *origin = [NSString stringWithFormat:@"%@Tests/Folder B/", baseUrl];
    NSString *destiny = [NSString stringWithFormat:@"%@Tests/Folder B Renamed/", baseUrl];
    
    //We create a semaphore to wait until we recive the responses from Async calls
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [_sharedOCCommunication moveFileOrFolder:origin toDestiny:destiny onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        NSLog(@"Folder Renamed");
        dispatch_semaphore_signal(semaphore);
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        XCTFail(@"Error renaming folder Response: %@ and Error: %@", response, error);
        dispatch_semaphore_signal(semaphore);
    } errorBeforeRequest:^(NSError *error) {
        XCTFail(@"Error renaming folder: %@", error);
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);
}*/

///-----------------------------------
/// @name testRestoreServerToNextTests
///-----------------------------------

/**
 * Method to restore all the files and folders in order to can test again everything
 *
 * @warning If this test not pass the next execution of the other test could not pass.
 */
/*- (void)testRestoreServerToNextTests {
    
    //Desrenaming the file
    NSString *origin = [NSString stringWithFormat:@"%@Tests/Folder B Renamed/Test Renamed.jpeg", baseUrl];
    NSString *destiny = [NSString stringWithFormat:@"%@Tests/Folder B Renamed/Test.jpeg", baseUrl];
    
    //We create a semaphore to wait until we recive the responses from Async calls
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [_sharedOCCommunication moveFileOrFolder:origin toDestiny:destiny onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        NSLog(@"File Renamed");
        dispatch_semaphore_signal(semaphore);
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        XCTFail(@"Error renaming file Response: %@ and Error: %@", response, error);
        dispatch_semaphore_signal(semaphore);
    } errorBeforeRequest:^(NSError *error) {
        XCTFail(@"Error renaming file: %@", error);
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);
    
    //Desrenaming the folder
    origin = [NSString stringWithFormat:@"%@Tests/Folder B Renamed/", baseUrl];
    destiny = [NSString stringWithFormat:@"%@Tests/Folder B/", baseUrl];
    
    //We create a semaphore to wait until we recive the responses from Async calls
    semaphore = dispatch_semaphore_create(0);
    
    [_sharedOCCommunication moveFileOrFolder:origin toDestiny:destiny onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        NSLog(@"Folder Renamed");
        dispatch_semaphore_signal(semaphore);
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        XCTFail(@"Error renaming folder Response: %@ and Error: %@", response, error);
        dispatch_semaphore_signal(semaphore);
    } errorBeforeRequest:^(NSError *error) {
        XCTFail(@"Error renaming folder: %@", error);
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);
    
    //Restore the folder
    origin = [NSString stringWithFormat:@"%@Tests/Folder B/Folder A/", baseUrl];
    destiny = [NSString stringWithFormat:@"%@Tests/Folder A/", baseUrl];
    
    //We create a semaphore to wait until we recive the responses from Async calls
    semaphore = dispatch_semaphore_create(0);
    
    [_sharedOCCommunication moveFileOrFolder:origin toDestiny:destiny onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        NSLog(@"Folder restored");
        dispatch_semaphore_signal(semaphore);
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        XCTFail(@"Error restoring folder Response: %@ and Error: %@", response, error);
        dispatch_semaphore_signal(semaphore);
    } errorBeforeRequest:^(NSError *error) {
        XCTFail(@"Error restoring folder: %@", error);
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);
    
    //Restore the file
    origin = [NSString stringWithFormat:@"%@Tests/Folder B/Test.jpeg", baseUrl];
    destiny = [NSString stringWithFormat:@"%@Tests/Folder A/Test.jpeg", baseUrl];
    
    //We create a semaphore to wait until we recive the responses from Async calls
    semaphore = dispatch_semaphore_create(0);
    
    [_sharedOCCommunication moveFileOrFolder:origin toDestiny:destiny onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        NSLog(@"File restored");
        dispatch_semaphore_signal(semaphore);
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        XCTFail(@"Error restoring file Response: %@ and Error: %@", response, error);
        dispatch_semaphore_signal(semaphore);
    } errorBeforeRequest:^(NSError *error) {
        XCTFail(@"Error restoring file: %@", error);
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);
    
    
    
}*/

///-----------------------------------
/// @name testToDeleteAFolder
///-----------------------------------

/**
 * Method to test if we can create a folder
 */
/*- (void)testDeleteAFolder
{
    //We create a semaphore to wait until we recive the responses from Async calls
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSString *folder = [NSString stringWithFormat:@"%@Tests/%@",baseUrl,[NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]]];
    folder = [folder stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [_sharedOCCommunication createFolder:folder onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        //Folder created
        NSLog(@"Folder created");
        dispatch_semaphore_signal(semaphore);
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        XCTFail(@"Error testCreateFolder: %@", error);
        // Signal that block has completed
        dispatch_semaphore_signal(semaphore);
    } errorBeforeRequest:^(NSError *error) {
        XCTFail(@"Error testCreateFolder: %@", error);
        // Signal that block has completed
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);
    
    //We create a semaphore to wait until we recive the responses from Async calls
    semaphore = dispatch_semaphore_create(0);
    
    [_sharedOCCommunication deleteFileOrFolder:folder onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse * response, NSString *redirectedServer) {
        //Folder deleted
        NSLog(@"Folder deleted");
        dispatch_semaphore_signal(semaphore);
    } failureRquest:^(NSHTTPURLResponse * response, NSError * error) {
        //Error
        XCTFail(@"Error testDeleteFolder: %@", error);
        // Signal that block has completed
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    dispatch_release(semaphore);
}*/

///-----------------------------------
/// @name Test Read Folder
///-----------------------------------

/**
 * In this test we check many things:
 * 1.- The read folder method works, conected with server and get the answer
 * 2.- Check the parser checking a specific number of items in the selected path
 * 3.- Check the parser checking a specific number of files and folders
 *
 */
/*- (void)testReadFolder{
    
    //We create a semaphore to wait until we recive the responses from Async calls
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    //Path with 7 elements: {3 files, 3 folders and the parent folder}
    NSString *path = [NSString stringWithFormat:@"%@Tests/Test Read Folder/", baseUrl];
    NSLog(@"Path: %@", path);
    
    
    path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [_sharedOCCommunication readFolder:path onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
        
        //Counters
        NSInteger foldersCount = 0;
        NSInteger filesCount = 0;
        //Remove the parent folder item
        NSInteger realItemsCount = items.count - 1;
        
        //Constants
        const int k_items = 6;
        const int k_files = 3;
        const int k_folders = 3;
        
        //Loop the items
        for (OCFileDto *itemDto in items) {
            //Check parser
            NSLog(@"Item file name: %@", itemDto.fileName);
            NSLog(@"Item file path: %@", itemDto.filePath);
            
            //Not include the root folder
            if (itemDto.fileName !=nil) {
                //File or folder
                if (itemDto.isDirectory) {
                    foldersCount++;
                } else {
                    filesCount++;
                }
            }
        }
        
        if (realItemsCount ==  k_items) {
            
            //Check account of files and folders
            if (foldersCount == k_folders && filesCount == k_files) {
                NSLog(@"Read Folder Test OK");
            } else {
                XCTFail(@"Error reading a folder - There are: %d folders and %d files insead of %d folders and %d files", foldersCount, filesCount, k_folders, k_files);
            }
            
        } else {
            XCTFail(@"Error reading a folder - There are: %d elements insead of 6 elements", realItemsCount);
        }
        
        dispatch_semaphore_signal(semaphore);
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        XCTFail(@"Error reading a folder - Response: %@ and Error: %@", response, error);
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);
}*/

///-----------------------------------
/// @name Test Read File
///-----------------------------------

/**
 * In this test we check the etag of a specific folder
 * we do changes in the folder in order to know the etag changed
 *
 */
/*-(void)testReadFile{
    
    //1.- Get and Store the etag of a specific folder
    
    //2.- Create a new folder with a specific name
    
    //3.- Delete the folder created
    
    //4.- Get and Compare the etag of the same folder with the preview, if is different the TEST is OK
    
    //Block Store Attributes
    __block long long etag = 0;
    
    
    //Path of new folder
    NSString *newFolder = [NSString stringWithFormat:@"%@Tests/Test Read File/DeletedFolder/", baseUrl];
    newFolder = [newFolder stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //We create a semaphore to wait until we recive the responses from Async calls
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    //Path to the test
    NSString *path = [NSString stringWithFormat:@"%@Tests/Test Read File/", baseUrl];
    path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"Path: %@", path);
    
    
    [_sharedOCCommunication readFile:path onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
        
        for (OCFileDto *itemDto in items) {
            //Check parser
            NSLog(@"Item file path: %@", itemDto.filePath);
            NSLog(@"Item etag: %lld", itemDto.etag);
            
            if (itemDto.etag) {
                etag = itemDto.etag;
            } else {
                XCTFail(@"Error getting the etag");
            }
        }
        
        dispatch_semaphore_signal(semaphore);
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        XCTFail(@"Error reading the folder properties - Response: %@ and Error: %@", response, error);
        dispatch_semaphore_signal(semaphore);
        
    }];
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);
    
    //Check if etag exists
    if (etag > 0) {
        
        //Create Folder
        //We create a semaphore to wait until we recive the responses from Async calls
        semaphore = dispatch_semaphore_create(0);
        
        
        [_sharedOCCommunication createFolder:newFolder onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
            //Folder created
            NSLog(@"Folder created");
            dispatch_semaphore_signal(semaphore);
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
            XCTFail(@"Error testCreateFolder: %@", error);
            // Signal that block has completed
            dispatch_semaphore_signal(semaphore);
        } errorBeforeRequest:^(NSError *error) {
            XCTFail(@"Error testCreateFolder: %@", error);
            // Signal that block has completed
            dispatch_semaphore_signal(semaphore);
        }];
        
        
        // Run loop
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
        dispatch_release(semaphore);
        
        
        
        //Delete Folder
        //We create a semaphore to wait until we recive the responses from Async calls
        semaphore = dispatch_semaphore_create(0);
        
        
        [_sharedOCCommunication deleteFileOrFolder:newFolder onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse * response, NSString *redirectedServer) {
            //Folder deleted
            NSLog(@"Folder deleted");
            dispatch_semaphore_signal(semaphore);
        } failureRquest:^(NSHTTPURLResponse * response, NSError * error) {
            //Error
            XCTFail(@"Error testDeleteFolder: %@", error);
            // Signal that block has completed
            dispatch_semaphore_signal(semaphore);
        }];
        
        // Run loop
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        dispatch_release(semaphore);
        
        
        
        //Get the folder etag again
        //We create a semaphore to wait until we recive the responses from Async calls
        semaphore = dispatch_semaphore_create(0);
        
        [_sharedOCCommunication readFile:path onCommunication:_sharedOCCommunication successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
            
            for (OCFileDto *itemDto in items) {
                //Check parser
                NSLog(@"Item file path: %@", itemDto.filePath);
                NSLog(@"Item etag: %lld", itemDto.etag);
                
                if (itemDto.etag) {
                    
                    if (etag == itemDto.etag) {
                        XCTFail(@"The same etag after the changes");
                    }else{
                        NSLog(@"Test OK");
                    }
                    
                    
                } else {
                    XCTFail(@"Error getting the etag");
                }
            }
            
            dispatch_semaphore_signal(semaphore);
            
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
            XCTFail(@"Error reading the folder properties - Response: %@ and Error: %@", response, error);
            dispatch_semaphore_signal(semaphore);
            
        }];
        
        // Run loop
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
        dispatch_release(semaphore);
        
    }
    
}*/


///-----------------------------------
/// @name Test Download File
///-----------------------------------

/**
 * This test try to download a specific file
 * It the file download the test is ok
 *
 */
/*- (void) testDownloadFile {
    
    //We create a semaphore to wait until we recive the responses from Async calls
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    //Create Folder in File Sytem to test
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    //Documents/Test Download/
    NSString *localPath = [documentsDirectory stringByAppendingPathComponent:@"Test Download"];
    
    //Make the path if not exists
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentsDirectory])
        [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory withIntermediateDirectories:NO attributes:nil error:&error];
    
    
    //Documents/Test Download/image.png
    localPath = [localPath stringByAppendingString:@"/image.png"];
    
    //Path of server file file
    NSString *serverUrl = [NSString stringWithFormat:@"%@Tests/Test Download/test image.PNG", baseUrl];
    serverUrl = [serverUrl stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"Server URL: %@", serverUrl);
    
    __block NSOperation *operation = nil;
    
    operation = [_sharedOCCommunication downloadFile:serverUrl toDestiny:localPath onCommunication:_sharedOCCommunication progressDownload:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        
        NSLog(@"Download :%d bytes of %lld bytes", bytesRead, totalBytesExpectedToRead);
        
    } successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        
        NSLog(@"Download file ok");
        
        //Delete the file
        NSError *theError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:localPath error:&theError];
        
        dispatch_semaphore_signal(semaphore);
        
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        
        XCTFail(@"Error download a file - Response: %@ - Error: %@", response, error);
        
        //Delete the file
        NSError *theError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:localPath error:&theError];
        dispatch_semaphore_signal(semaphore);
        
        
    } shouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        
        NSLog(@"Cancel download");
        [operation cancel];
        
    }];
    
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);
    
    
    
}*/

///-----------------------------------
/// @name Test download not existing file
///-----------------------------------

/**
 * This test try to download a unexisting file
 * The test works if the file is not download
 *
 */
/*- (void) testDownloadNotExistingFile {
    
    //We create a semaphore to wait until we recive the responses from Async calls
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    //Create Folder in File Sytem to test
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    //Documents/Test Download/
    NSString *localPath = [documentsDirectory stringByAppendingPathComponent:@"Test Download"];
    
    //Make the path if not exists
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentsDirectory])
        [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory withIntermediateDirectories:NO attributes:nil error:&error];
    
    
    //Documents/Test Download/image.png
    localPath = [localPath stringByAppendingString:@"/image.png"];
    
    //Path of server file that not exist
    NSString *serverUrl = [NSString stringWithFormat:@"%@Tests/Test Download/test image not exist.PNG", baseUrl];
    serverUrl = [serverUrl stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"Local Paht: %@", localPath);
    NSLog(@"Server URL: %@", serverUrl);
    
    __block NSOperation *operation = nil;
    
    operation = [_sharedOCCommunication downloadFile:serverUrl toDestiny:localPath onCommunication:_sharedOCCommunication progressDownload:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        
        NSLog(@"Download :%d bytes of %lld bytes", bytesRead, totalBytesExpectedToRead);
        
    } successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        
        XCTFail(@"Download file ok, not possible");
        
        //Delete the file
        NSError *theError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:localPath error:&theError];
        
        dispatch_semaphore_signal(semaphore);
        
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        
        NSLog(@"Error download a file - Response: %@ - Error: %@", response, error);
        
        //Delete the file
        NSError *theError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:localPath error:&theError];
        dispatch_semaphore_signal(semaphore);
        
        
    } shouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        
        NSLog(@"Cancel download");
        [operation cancel];
        
    }];
    
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);
    
}*/

///-----------------------------------
/// @name Test to upload a small file
///-----------------------------------

/**
 * This test try to uplad a file without chunks
 *
 */
/*- (void) testUploadAFileNoChunks {
    
    //We create a semaphore to wait until we recive the responses from Async calls
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    //Create Folder in File Sytem to test
    NSString *localPath = [NSString stringWithFormat:@"%@/CompanyLogo.png", [[NSBundle mainBundle] resourcePath]];
    
    //Path of server file file
    NSString *serverUrl = [NSString stringWithFormat:@"%@Tests/Test Upload/CompanyLogo.png", baseUrl];
    serverUrl = [serverUrl stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"Server URL: %@", serverUrl);
    
    __block NSOperation *operation = nil;
    
    operation = [_sharedOCCommunication uploadFile:localPath toDestiny:serverUrl onCommunication:_sharedOCCommunication progressUpload:^(NSUInteger bytesWrote, long long totalBytesWrote, long long totalBytesExpectedToWrote) {
        if(totalBytesExpectedToWrote/1024 == 0) {
            
            if (bytesWrote>0) {
                float percent;
                
                percent=totalBytesWrote*100/totalBytesExpectedToWrote;
                percent = percent / 100;
                
                NSLog(@"percent: %f", percent*100);
            }
        }
        
    } successRequest:^(NSHTTPURLResponse *response) {
        NSLog(@"File Uploaded");
        dispatch_semaphore_signal(semaphore);
    } failureRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer, NSError *error) {
        XCTFail(@"Error. File do not uploaded: %@", error);
        dispatch_semaphore_signal(semaphore);
    } failureBeforeRequest:^(NSError *error) {
        XCTFail(@"Error File does not exist");
        dispatch_semaphore_signal(semaphore);
    } shouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        XCTFail(@"Error Credentials. File do not uploaded");
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);
    
}*/

///-----------------------------------
/// @name Test to upload a big file
///-----------------------------------

/**
 * This test try to uplad a file with chunks
 * To test it we need at first download a file from the server
 */
/*- (void) testUploadAFileWithChunks {
    
    //We create a semaphore to wait until we recive the responses from Async calls
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    //Create Folder in File Sytem to test
    NSString *localPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"audio.mp3"];
    
    //Path of server file file
    NSString *serverUrl = [NSString stringWithFormat:@"%@Tests/audio.mp3", baseUrl];
    serverUrl = [serverUrl stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"Server URL: %@", serverUrl);
    
    __block NSOperation *operation = nil;
    
    operation = [_sharedOCCommunication downloadFile:serverUrl toDestiny:localPath onCommunication:_sharedOCCommunication progressDownload:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        
        NSLog(@"Download :%d bytes of %lld bytes", bytesRead, totalBytesExpectedToRead);
        
    } successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        
        NSLog(@"Download file ok");
        
        //Delete the file
        
        //NSError *theError = nil;
        //[[NSFileManager defaultManager] removeItemAtPath:localPath error:&theError];
        
        dispatch_semaphore_signal(semaphore);
        
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        
        XCTFail(@"Error download a file - Response: %@ - Error: %@", response, error);
        
        //Delete the file
        NSError *theError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:localPath error:&theError];
        dispatch_semaphore_signal(semaphore);
        
        
    } shouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        
        NSLog(@"Cancel download");
        [operation cancel];
        
    }];
    
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        
        semaphore = dispatch_semaphore_create(0);
        
        //Path of server file file
        NSString *serverUrlToUpload = [NSString stringWithFormat:@"%@Tests/Test Upload/audio.mp3", baseUrl];
        serverUrlToUpload = [serverUrlToUpload stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSLog(@"Server URL: %@", serverUrl);
        
        operation = nil;
        
        operation = [_sharedOCCommunication uploadFile:localPath toDestiny:serverUrlToUpload onCommunication:_sharedOCCommunication progressUpload:^(NSUInteger bytesWrote, long long totalBytesWrote, long long totalBytesExpectedToWrote) {
            
            NSLog(@"NSLog: %lld - %lld", totalBytesWrote, totalBytesExpectedToWrote);
            
            if(totalBytesExpectedToWrote/1024 != 0) {
                if (bytesWrote>0) {
                    float percent;
                    
                    percent=totalBytesWrote*100/totalBytesExpectedToWrote;
                    
                    NSLog(@"percent: %f", percent);
                }
            }
            
        } successRequest:^(NSHTTPURLResponse *response) {
            NSLog(@"File Uploaded");
            dispatch_semaphore_signal(semaphore);
        } failureRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer,NSError *error) {
            XCTFail(@"Error. File do not uploaded: %@", error);
            dispatch_semaphore_signal(semaphore);
        } failureBeforeRequest:^(NSError *error) {
            XCTFail(@"Error File does not exist");
            dispatch_semaphore_signal(semaphore);
        } shouldExecuteAsBackgroundTaskWithExpirationHandler:^{
            XCTFail(@"Error Credentials. File do not uploaded");
            dispatch_semaphore_signal(semaphore);
        }];
        
        // Run loop
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
        dispatch_release(semaphore);
        
        //Delete the file
        NSError *theError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:localPath error:&theError];
        
    } else {
        XCTFail(@"Error Downloading the file. We can not make the testUploadAFileWithChunks");
    }
}*/

///-----------------------------------
/// @name Test to upload a file that does not exist
///-----------------------------------

/**
 * This test try to upload that does not exist on the filesystem
 * This test is passed if we detect that the file does not exist
 *
 */
/*- (void) testUploadAFileThatDoesNotExist {
    
    //We create a semaphore to wait until we recive the responses from Async calls
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    //Create Folder in File Sytem to test
    NSString *localPath = [NSString stringWithFormat:@"%@/Name of the file that does not exist.png", [[NSBundle mainBundle] resourcePath]];
    
    //Path of server file file
    NSString *serverUrl = [NSString stringWithFormat:@"%@Tests/Test Upload/Name of the file that does not exist.png", baseUrl];
    serverUrl = [serverUrl stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"Server URL: %@", serverUrl);
    
    __block NSOperation *operation = nil;
    
    operation = [_sharedOCCommunication uploadFile:localPath toDestiny:serverUrl onCommunication:_sharedOCCommunication progressUpload:^(NSUInteger bytesWrote, long long totalBytesWrote, long long totalBytesExpectedToWrote) {
        if(totalBytesExpectedToWrote/1024 == 0) {
            
            if (bytesWrote>0) {
                float percent;
                
                percent=totalBytesWrote*100/totalBytesExpectedToWrote;
                percent = percent / 100;
                
                NSLog(@"percent: %f", percent*100);
            }
        }
        
    } successRequest:^(NSHTTPURLResponse *response) {
        XCTFail(@"Error We upload a file that does not exist");
        dispatch_semaphore_signal(semaphore);
    } failureRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer, NSError *error) {
        XCTFail(@"Error. File do not uploaded: %@", error);
        dispatch_semaphore_signal(semaphore);
    } failureBeforeRequest:^(NSError *error) {
        NSLog(@"File that do not exist does not upload");
        dispatch_semaphore_signal(semaphore);
    } shouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        XCTFail(@"Error Credentials. File do not uploaded");
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Run loop
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    dispatch_release(semaphore);
    
}*/

@end
