//
//  MovieCell.swift
//  OCLibraryExample
//
//  Created by Gonzalo Gonzalez on 3/12/15.
//  Copyright © 2015 ownCloud. All rights reserved.
//

import UIKit

class MovieCell: UICollectionViewCell {
    
     @IBOutlet weak var posterImageView: UIImageView!
    
    func setSelectedStyle () {
        
        self.backgroundColor = UIColor.blackColor()
    }
    
    func setUnselectedStyle () {
        
        self.backgroundColor = UIColor.clearColor()
    }
    
   
    
    
    
}
