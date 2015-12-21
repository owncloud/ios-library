//
//  VideoPlayerViewController.swift
//  OCLibraryExample
//
//  Created by Javier Gonzalez on 16/12/15.
//  Copyright © 2015 ownCloud. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit


class VideoPlayerViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func playVideo(urlString:String, userName:String, password:String) {
        // Do any additional setup after loading the view
        
        let url = NSURL(string: urlString)
        //let url = NSURL(string: "http://www.ebookfrenzy.com/ios_book/movie/movie.mov")
        //let url = NSURL(fileURLWithPath: "/Users/Javi/Downloads/movie3.mp4")
        
        let headers:NSMutableDictionary = NSMutableDictionary();
        headers.setObject("Mozilla/5.0 (iOS) ownCloud-iOS/3.4.6", forKey: "User-Agent")
        
        //Login
        let PasswordString = "\(userName):\(password)"
        let PasswordData = PasswordString.dataUsingEncoding(NSUTF8StringEncoding)
        let base64EncodedCredential = PasswordData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
    
        headers.setObject("Basic \(base64EncodedCredential)", forKey: "Authorization")
        
        let asset:AVURLAsset = AVURLAsset(URL: url!, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        
        let playerItem:AVPlayerItem = AVPlayerItem(asset: asset)
        
        let player = AVPlayer(playerItem: playerItem)
        let playerController = AVPlayerViewController()
        
        playerController.player = player
        self.addChildViewController(playerController)
        self.view.addSubview(playerController.view)
        playerController.view.frame = self.view.frame
        
        player.play()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
