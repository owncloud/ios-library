//
//  ViewController.m
//  OCLibraryExample
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
//

#import "ViewController.h"
#import "OCCommunication.h"
#import "OCFileDto.h"
#import "AppDelegate.h"

//User, pass and server to make the tests
static NSString *user = @"oclibrarytest";
static NSString *password = @"123456";
static NSString *baseUrl = @"https://beta.owncloud.com/owncloud/remote.php/webdav/";


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //Buttons
    _deleteLocalFile.enabled = NO;
    
    //Labels
    _progressLabel.text = @"Empty";
    _goInfoLabel.text = @"";
    
    //Set credentials once
    [self setCredencialsInOCCommunication];
    
   
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)readFolder:(id)sender{
    
    _itemsOfPath = nil;
    [_itemsTableView reloadData];
    
    [self showRootFolder];
    _goButton.enabled = NO;
    
}

- (IBAction)downloadImage:(id)sender{
    
    _downloadButton.enabled = NO;
    
    [self downloadFile];
}

- (IBAction)deleteDownloadedFile:(id)sender{
    
    //Delete the file
    NSError *theError = nil;
    [[NSFileManager defaultManager] removeItemAtPath:_pathOfDownloadFile error:&theError];
    
    _progressLabel.text = @"Empty";
    _downloadedImageView.image = nil;
    
    _downloadButton.enabled = YES;
    _deleteLocalFile.enabled = NO;
    
}


- (IBAction)uploadImage:(id)sender{
    
    _uploadButton.enabled = NO;
    
    [self uploadFile];
    
}


- (IBAction)deleteUploadedFile:(id)sender{
    _uploadProgressLabel.text = @"Deleting file...";
    _deleteRemoteFile.enabled = NO;
    [self deleteFile];
    

}

- (void)deleteUploadLocalFile{
    
    //Delete the file
    NSError *theError = nil;
    [[NSFileManager defaultManager] removeItemAtPath:_pathOfLocalUploadedFile error:&theError];
    
}


#pragma mark - OCComunication Methods

///-----------------------------------
/// @name Set Credentials in OCCommunication
///-----------------------------------

/**
 * Set username and password in the OCComunicacion
 *
 */
- (void) setCredencialsInOCCommunication {
    
    //Sett credencials
    [[AppDelegate sharedOCCommunication] setCredentialsWithUser:user andPassword:password];
    
}

///-----------------------------------
/// @name Show Root Folder
///-----------------------------------

/**
 * This method has block to read the root folder of the specific account,
 * add the data to itemsOfPath array and reload the table view.
 *
 */
- (void) showRootFolder {
    
    _goInfoLabel.text = @"Loading...";
    
    NSString *path = [NSString stringWithFormat:@"%@", baseUrl];
    NSLog(@"Path: %@", path);
    
    path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[AppDelegate sharedOCCommunication] readFolder:path onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirected) {
        NSLog(@"succes");
        for (OCFileDto *itemDto in items) {
            //Check parser
            NSLog(@"Item file name: %@", itemDto.fileName);
            NSLog(@"Item file path: %@", itemDto.filePath);
        }
        
        _itemsOfPath = nil;
        _itemsOfPath = [NSArray arrayWithArray:items];
        
        [_itemsTableView reloadData];
         _goButton.enabled = YES;
        
         _goInfoLabel.text = @"Success";

    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        NSLog(@"Fail");
        
        NSLog(@"Error: %@", error);
         _goButton.enabled = YES;
        
         _goInfoLabel.text = @"Fail";
    }];
    
}

///-----------------------------------
/// @name Create Folder
///-----------------------------------

/**
 * Method to create folder in the root folder
 *
 */
- (void)createFolder {
    
    NSString *folder = [NSString stringWithFormat:@"%@Tests/%@",baseUrl,[NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]]];
    
    [[AppDelegate sharedOCCommunication] createFolder:folder onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        //Folder created
        NSLog(@"Folder created");
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        NSLog(@"Error testCreateFolder: %@", error);
        
    } errorBeforeRequest:^(NSError *error) {
        NSLog(@"Error testCreateFolder: %@", error);
               
    }];

}

///-----------------------------------
/// @name Download file
///-----------------------------------

/**
 * Method that download a specific file to the system Document directory
 *
 */
- (void)downloadFile {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    
    NSString *localPath = [documentsDirectory stringByAppendingString:@"/image.png"];
    
    //Path of server file file
    NSString *serverUrl = [NSString stringWithFormat:@"%@LibExampleDownload/why so serious.jpg", baseUrl];
    
    //Encoding
    serverUrl = [serverUrl stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"Server URL: %@", serverUrl);
    
    _downloadOperation = nil;
    
    _downloadOperation = [[AppDelegate sharedOCCommunication] downloadFile:serverUrl toDestiny:localPath onCommunication:[AppDelegate sharedOCCommunication] progressDownload:^(NSUInteger bytesRead, long long totalBytesRead, long long totalExpectedBytesRead) {
        _progressLabel.text = [NSString stringWithFormat:@"Downloading: %lld bytes", totalBytesRead];
        
    } successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        NSLog(@"LocalFile : %@", localPath);
        _pathOfDownloadFile = localPath;
        UIImage *image = [[UIImage alloc]initWithContentsOfFile:localPath];
        _downloadedImageView.image = image;
        _progressLabel.text = @"Success";
        _deleteLocalFile.enabled = YES;
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        NSLog(@"error while download a file: %@", error);
        _progressLabel.text = @"Error in download";
        _downloadButton.enabled = YES;
        
    } shouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        [_downloadOperation cancel];
    }];
    
}

///-----------------------------------
/// @name Upload File
///-----------------------------------

/**
 *
 *
 */
- (void)uploadFile {
    
    //Copy the specific file to the Documents directory
    UIImage *uploadImage = [UIImage imageNamed:@"image_to_upload.jpg"];
    
    //Convert UIImage to JPEG
    NSData *imgData = UIImageJPEGRepresentation(uploadImage, 1); // 1 is compression quality
    
    //Identify the home directory and file name
    NSString  *imagePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Test.jpg"];
    
    // Write the file.
    [imgData writeToFile:imagePath atomically:YES];
    
    _pathOfLocalUploadedFile = imagePath;
    
    //Path of server file file
    NSString *serverUrl = [NSString stringWithFormat:@"%@1_image_uploaded.jpg", baseUrl];
    serverUrl = [serverUrl stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    _uploadOperation = nil;
    
    _uploadOperation = [[AppDelegate sharedOCCommunication] uploadFile:imagePath toDestiny:serverUrl onCommunication:[AppDelegate sharedOCCommunication] progressUpload:^(NSUInteger bytesWrite, long long totalBytesWrite, long long totalExpectedBytesWrite) {
         _uploadProgressLabel.text = [NSString stringWithFormat:@"Uploading: %lld bytes", totalBytesWrite];
        
    } successRequest:^(NSHTTPURLResponse *response) {
        _pathOfRemoteUploadedFile = serverUrl;
        _uploadProgressLabel.text = @"Success";
        _deleteRemoteFile.enabled = YES;
        
        //Remove the local file
        [self deleteUploadLocalFile];
        
        //Refresh the file list
        [self readFolder:nil];
        
    } failureRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer, NSError *error) {
        NSLog(@"error while upload a file: %@", error);
        _uploadProgressLabel.text = @"Error in download";
        _uploadButton.enabled = YES;
        
    } failureBeforeRequest:^(NSError *error) {
        NSLog(@"error while upload a file: %@", error);
        _uploadProgressLabel.text = @"Error in download";
        _uploadButton.enabled = YES;
        
    } shouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        [_uploadOperation cancel];
    }];
    
   
    
}

- (void) deleteFile {
    
    [[AppDelegate sharedOCCommunication] deleteFileOrFolder:_pathOfRemoteUploadedFile onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        _uploadProgressLabel.text = @"";
        _uploadButton.enabled = YES;
        _deleteRemoteFile.enabled = NO;
        
        //Refresh the file list
        [self readFolder:nil];
        
    } failureRquest:^(NSHTTPURLResponse *response, NSError *error) {
        NSLog(@"error while delete a file: %@", error);
        _uploadProgressLabel.text = @"Error in delete file";
        _deleteRemoteFile.enabled = YES;
    }];
    
}

#pragma mark - Close View


- (IBAction)closeView:(id)sender{
    
    //if there are a operation in progress cancel 
    if (_downloadOperation) {
        [_downloadOperation cancel];
        _downloadOperation = nil;
        //Remove download file
        [self deleteDownloadedFile:nil];
    }
    
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - UITableView DataSource

// Asks the data source to return the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

// Returns the table view managed by the controller object.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    if (!_itemsOfPath) {
        return 0;
    } else {
        return [_itemsOfPath count];
    }
}


// Returns the table view managed by the controller object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"DefaultCell";
    
    UITableViewCell *cell;
    
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    
    OCFileDto *itemDto = [_itemsOfPath objectAtIndex:indexPath.row];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    cell.textLabel.text = [itemDto.fileName stringByReplacingPercentEscapesUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding];
    
    return cell;
}



@end
