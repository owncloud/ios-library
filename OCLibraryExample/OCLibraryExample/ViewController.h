//
//  ViewController.h
//  OCLibraryExample
//
//  Created by Gonzalo Gonzalez on 21/11/13.
//  Copyright (c) 2013 ownCloud. All rights reserved.
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

//
@property (nonatomic,strong)NSString *pathOfDownloadFile;
@property (nonatomic,strong)NSArray *itemsOfPath;


//Read Folder actions
- (IBAction)readFolder:(id)sender;


//Download actions
- (IBAction)downloadImage:(id)sender;
- (IBAction)deleteDownloadedFile:(id)sender;

@end
