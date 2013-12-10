//
//  AppDelegate.h
//  OCLibraryExample
//
//  Created by Gonzalo Gonzalez on 21/11/13.
//  Copyright (c) 2013 ownCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCCommunication.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

/*
 * Method to get a Singleton of the OCCommunication to manage all the communications
 */
+ (OCCommunication*)sharedOCCommunication;

@end
