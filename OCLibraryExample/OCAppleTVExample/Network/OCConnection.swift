//
//  OCConnection.swift
//  OCLibraryExample
//
//  Created by Gonzalo Gonzalez on 17/12/15.
//  Copyright © 2015 ownCloud. All rights reserved.
//

import UIKit
import Alamofire

class OCConnection {
    
    class var sharedInstance: OCConnection {
        struct Static {
            static let instance: OCConnection = OCConnection()
        }
        return Static.instance
    }
    
    private init() {
        print("init");
    }
    
    func getVideoFilesOfRootFolder() {
        
     //   Alamofire.Method = "PROPFIND"

        
        
    
    }

}
