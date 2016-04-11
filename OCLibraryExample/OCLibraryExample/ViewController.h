//
//  ViewController.h
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

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDataSource>


//UI
@property (nonatomic,strong)IBOutlet UITableView *itemsTableView;
@property (nonatomic,strong)IBOutlet UILabel *goInfoLabel;
@property (nonatomic,strong)IBOutlet UIButton *goButton;
@property (nonatomic,strong)IBOutlet UILabel *progressLabel;
@property (nonatomic,strong)IBOutlet UIButton *downloadButton;
@property (nonatomic,strong)IBOutlet UIButton *deleteLocalFile;
@property (nonatomic,strong)IBOutlet UIImageView *downloadedImageView;
@property (nonatomic,strong)IBOutlet UILabel *uploadProgressLabel;
@property (nonatomic,strong)IBOutlet UIButton *uploadButton;
@property (nonatomic,strong)IBOutlet UIButton *uploadWithSessionButton;
@property (nonatomic,strong)IBOutlet UIButton *deleteRemoteFile;



//
@property (nonatomic,strong)NSString *pathOfDownloadFile;
@property (nonatomic,strong)NSArray *itemsOfPath;
@property (nonatomic,strong)NSString *pathOfRemoteUploadedFile;
@property (nonatomic,strong)NSString *pathOfLocalUploadedFile;

//Operations
@property(nonatomic,strong)NSURLSessionTask *downloadTask;
@property(nonatomic,strong)NSURLSessionTask *uploadTask;


//Read Folder actions
- (IBAction)readFolder:(id)sender;

//Download actions
- (IBAction)downloadImage:(id)sender;
- (IBAction)deleteDownloadedFile:(id)sender;

//Upload actions
- (IBAction)uploadImage:(id)sender;
- (IBAction)uploadImageWithSession:(id)sender;
- (IBAction)deleteUploadedFile:(id)sender;

//Close View
- (IBAction)closeView:(id)sender;

@end
