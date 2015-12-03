//
//  ViewController.swift
//  OCAppleTVExample
//
//  Created by Gonzalo Gonzalez on 3/12/15.
//  Copyright © 2015 ownCloud. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let kMovieCellIdentifier: String = "MovieCellIdentifier"
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: MovieCell = collectionView.dequeueReusableCellWithReuseIdentifier(kMovieCellIdentifier, forIndexPath: indexPath) as! MovieCell
        cell.backgroundColor = UIColor.blackColor()
    
    return cell
    }
    
  /*  func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell: MovieCell = collectionView.cellForItemAtIndexPath(indexPath) as! MovieCell
        cell.setSelectedStyle()
    }
    
    func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell: MovieCell = collectionView.cellForItemAtIndexPath(indexPath) as! MovieCell
        cell.setUnselectedStyle()
    }
    
    func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool{
        return true
    }*/
    
  /*  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell: MovieCell = collectionView.cellForItemAtIndexPath(indexPath) as! MovieCell
        cell.setSelectedStyle()
    }

    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell: MovieCell = collectionView.cellForItemAtIndexPath(indexPath) as! MovieCell
        cell.setUnselectedStyle()
    }*/
    
    func indexPathForPreferredFocusedViewInCollectionView(collectionView: UICollectionView) -> NSIndexPath? {
        return NSIndexPath(forRow: 0, inSection: 0)
    }
    
    func collectionView(collectionView: UICollectionView, canFocusItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            context.previouslyFocusedView?.transform = CGAffineTransformIdentity
            context.previouslyFocusedView?.layer.shadowColor = UIColor.clearColor().CGColor
            context.nextFocusedView?.transform = CGAffineTransformMakeScale(1.2, 1.2)
            context.nextFocusedView?.layer.shadowColor = UIColor.blueColor().CGColor
            context.nextFocusedView?.layer.shadowRadius = 8.0
            context.nextFocusedView?.layer.shadowOffset = CGSizeMake(2,2)
            context.nextFocusedView?.layer.shadowOpacity = 1.0
            }, completion: nil)
    }
    
  /*  func collectionView(collectionView: UICollectionView, shouldUpdateFocusInContext context: UICollectionViewFocusUpdateContext) -> Bool {
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didUpdateFocusInContext context: UICollectionViewFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
       
    }*/
    

    

}

