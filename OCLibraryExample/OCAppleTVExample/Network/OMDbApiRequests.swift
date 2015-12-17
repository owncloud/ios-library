//
//  OMDbApiRequests.swift
//  OCLibraryExample
//
//  Created by Javier Gonzalez on 17/12/15.
//  Copyright © 2015 ownCloud. All rights reserved.
//

import UIKit
import Alamofire

class OMDbApiRequests: NSObject {
    
    
    func readJSONByFileName(fileUrl: String) {
        
        
        //1. Remove the extension
        let fileNameWithoutExtension = NSURL(fileURLWithPath: fileUrl).URLByDeletingPathExtension!.lastPathComponent
        
        //2. Split by " "
        let fullNameArr = fileNameWithoutExtension!.componentsSeparatedByString(" ")
        var constructedStringToRequest = ""
        
        //3. Replace the " " by "+"
        for var i = 0; i < fullNameArr.count; i++ {
            constructedStringToRequest = constructedStringToRequest + fullNameArr[i]
            
            if i < fullNameArr.count-1 {
                constructedStringToRequest = constructedStringToRequest + "+"
            }
            
        }
        
        Alamofire.request(.GET, "http://www.omdbapi.com/?t=" + constructedStringToRequest + "&y=&plot=short&r=json")
            .responseJSON { response in
                //print(response.request)  // original URL request
                //print(response.response) // URL response
                //print(response.data)     // server data
                //print(response.result)   // result of response serialization
                
                if let JSON = response.result.value {
                    print("JSON: \(JSON)")
                }
        }
    }
    

}

