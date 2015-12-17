//
//  OCConnection.swift
//  OCLibraryExample
//
//  Created by Gonzalo Gonzalez on 17/12/15.
//  Copyright © 2015 ownCloud. All rights reserved.
//

import UIKit


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
        
        let request = NSMutableURLRequest(URL: NSURL(string: "http://docker.oc.solidgear.es:53417/remote.php/webdav/")!)
        request.HTTPMethod = "PROPFIND"
        
        //HEADERS
        request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.addValue("1", forHTTPHeaderField: "Depth")
        let bodyString: String = "<?xml version=\"1.0\" encoding=\"utf-8\" ?><a:propfind xmlns:a=\"DAV:\" xmlns:oc=\"http://owncloud.org/ns\"><a:prop><a:getlastmodified/></a:prop><a:prop><a:getcontenttype/></a:prop><a:prop><a:getcontentlength/></a:prop><a:prop><a:getetag/></a:prop><a:prop><a:resourcetype/></a:prop><a:prop><oc:permissions/></a:prop></a:propfind>"
        request.HTTPBody = bodyString.dataUsingEncoding(NSUTF8StringEncoding)
        
        let credentials: String = "Basic b2N0djpvY3R2"
        request.addValue(credentials, forHTTPHeaderField: "Authorization")
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
            
            
            if let unwrappedError = error {
                print(error)
                }
            else {
                if let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) {
                    print(responseString)
                    
                    
                    
                }

            }
            
        }
        
        task.resume()
        
 


        
        
        
    
    }

}
