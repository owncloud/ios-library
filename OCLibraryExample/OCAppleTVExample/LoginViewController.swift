//
//  LoginViewController.swift
//  OCLibraryExample
//
//  Created by Javier Gonzalez on 21/12/15.
//  Copyright © 2015 ownCloud. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var urlTextField: UITextField?
    @IBOutlet weak var userNameTextField: UITextField?
    @IBOutlet weak var passwordTextField: UITextField?
    @IBOutlet weak var acceptButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.urlTextField?.text = "http://docker.oc.solidgear.es:53417"
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func acceptButtonAction(sender: UIButton) {
        

        OCConnection.sharedInstance.isLoginCorrect ((self.urlTextField?.text)!, userName: (self.userNameTextField?.text!)!, password: (self.passwordTextField?.text!)!) { (success) -> Void in
            
            if success {
                
                let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let vc : ViewController = storyboard.instantiateViewControllerWithIdentifier("ViewController") as! ViewController
                
                vc.urlString = self.urlTextField?.text
                vc.userName = self.userNameTextField?.text
                vc.password = self.passwordTextField?.text
                
                self.presentViewController(vc, animated: true, completion: nil)
                
            } else {
                
                dispatch_async(dispatch_get_main_queue(), {
                    let alert = UIAlertController(title: "Error", message:"Wrong Credentials", preferredStyle: .Alert)
                    let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                    alert.addAction(cancelAction)
                    
                    self.presentViewController(alert, animated: true){
                    }
                })
            }
            
        }
        
        
        
        
        
        
        
        
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
