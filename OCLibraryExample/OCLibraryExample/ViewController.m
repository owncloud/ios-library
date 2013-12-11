//
//  ViewController.m
//  OCLibraryExample
//
//  Created by Gonzalo Gonzalez on 21/11/13.
//  Copyright (c) 2013 ownCloud. All rights reserved.
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


#pragma mark - OCComunication Methods

- (void) setCredencialsInOCCommunication {
    
    //Sett credencials
    [[AppDelegate sharedOCCommunication] setCredentialsWithUser:user andPassword:password];
    
}

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
        
         _goInfoLabel.text = @"Succes";

    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        NSLog(@"Fail");
        
        NSLog(@"Error: %@", error);
         _goButton.enabled = YES;
        
         _goInfoLabel.text = @"Fail";
    }];
    
}

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

- (void)downloadFile {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    
    NSString *localPath = [documentsDirectory stringByAppendingString:@"/image.png"];
    
    //Path of server file file
    NSString *serverUrl = [NSString stringWithFormat:@"%@LibExampleDownload/why so serious.jpg", baseUrl];
    serverUrl = [serverUrl stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"Server URL: %@", serverUrl);
    
    __block NSOperation *operation = nil;

    operation = [[AppDelegate sharedOCCommunication] downloadFile:serverUrl toDestiny:localPath onCommunication:[AppDelegate sharedOCCommunication] progressDownload:^(NSUInteger bytesRead, long long totalBytesRead, long long totalExpectedBytesRead) {
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
        [operation cancel];
    }];
    
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


/*-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 20;
}*/


@end
