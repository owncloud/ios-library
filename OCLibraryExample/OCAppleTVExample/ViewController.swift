//
//  ViewController.swift
//  OCAppleTVExample
//
//  Created by Gonzalo Gonzalez on 3/12/15.
//  Copyright © 2015 ownCloud. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let kMovieCellIdentifier:String = "MovieCellIdentifier"
    
    //Movies
    var moviesList:NSMutableArray?
    
    @IBOutlet weak var viewMovieInfoCointainer: UIView?
    @IBOutlet weak var backgroundMovieInfoCointainer: UIImageView?
    
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var plotLabel: UILabel?
    @IBOutlet weak var actorsLabel: UILabel?
    @IBOutlet weak var directorLabel: UILabel?
    @IBOutlet weak var runtimeLabel: UILabel?
    @IBOutlet weak var yearLabel: UILabel?
    @IBOutlet weak var posterImage: UIImageView?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.moviesList = NSMutableArray()
        self.createTheMoviesList()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (self.moviesList?.count)!
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: MovieCell = collectionView.dequeueReusableCellWithReuseIdentifier(kMovieCellIdentifier, forIndexPath: indexPath) as! MovieCell

        let currentMovie:FilmsDto = (self.moviesList?.objectAtIndex(indexPath.row))! as! FilmsDto
        let currentPosterView = UIImageView(image: currentMovie.posterLocal)
        currentPosterView.contentMode = UIViewContentMode.ScaleAspectFit
        cell.backgroundView = currentPosterView
        
    return cell
    }
    
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell: MovieCell = collectionView.cellForItemAtIndexPath(indexPath) as! MovieCell
        cell.setSelectedStyle()
    }
    
    func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell: MovieCell = collectionView.cellForItemAtIndexPath(indexPath) as! MovieCell
        cell.setUnselectedStyle()
    }
    
    func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool{
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell: MovieCell = collectionView.cellForItemAtIndexPath(indexPath) as! MovieCell
        cell.setUnselectedStyle()
        
        let currentMovie:FilmsDto = (self.moviesList?.objectAtIndex(indexPath.row))! as! FilmsDto
        
        let vc = VideoPlayerViewController()
        vc.urlString = currentMovie.filmUrl
        self.presentViewController(vc, animated: true, completion: nil)
    }

    /*
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
            context.nextFocusedView?.layer.shadowColor = UIColor.blackColor().CGColor
            context.nextFocusedView?.layer.shadowRadius = 8.0
            context.nextFocusedView?.layer.shadowOffset = CGSizeMake(2,2)
            context.nextFocusedView?.layer.shadowOpacity = 1.0
            }, completion: nil)
    }
    
  /*  func collectionView(collectionView: UICollectionView, shouldUpdateFocusInContext context: UICollectionViewFocusUpdateContext) -> Bool {
        return true
    }

*/
    
    func collectionView(collectionView: UICollectionView, didUpdateFocusInContext context: UICollectionViewFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        
        print(context.nextFocusedIndexPath?.row)
        
        if (context.nextFocusedIndexPath != nil) {
            
            let currentMovie:FilmsDto = (self.moviesList?.objectAtIndex((context.nextFocusedIndexPath?.row)!))! as! FilmsDto
            
            //Movie info
            self.titleLabel?.text = currentMovie.title
            self.plotLabel?.text = currentMovie.plot
            self.actorsLabel?.text = currentMovie.actors
            self.directorLabel?.text = currentMovie.director
            self.yearLabel?.text = String(currentMovie.year)
            self.runtimeLabel?.text = currentMovie.runtime
            self.posterImage?.image = currentMovie.posterLocal
            
            //Image background
            
            self.backgroundMovieInfoCointainer?.image = currentMovie.posterLocal
            self.backgroundMovieInfoCointainer!.contentMode = UIViewContentMode.ScaleAspectFill
            self.backgroundMovieInfoCointainer?.alpha = 0.3
            
            /*let darkBlur = UIBlurEffect(style: UIBlurEffectStyle.Dark)
            let blurView = UIVisualEffectView(effect: darkBlur)
            blurView.frame = self.backgroundMovieInfoCointainer!.bounds
            self.backgroundMovieInfoCointainer!.addSubview(blurView)*/
        }
        
        
        
        
        
        
        

        
        
    }
    
    func createTheMoviesList() {
        
        let movie1:FilmsDto = FilmsDto()
        movie1.title = "Raiders of the Lost Ark"
        movie1.plot = "Archaeologist and adventurer Indiana Jones is hired by the US government to find the Ark of the Covenant before the Nazis."
        movie1.actors = "Harrison Ford, Karen Allen, Paul Freeman, Ronald Lacey"
        movie1.director = "Steven Spielberg"
        movie1.runtime = "115 min"
        movie1.year = 1981
        movie1.posterLocal = UIImage(named: "movie1.jpg")
        movie1.filmUrl = "http://docker.oc.solidgear.es:53417/remote.php/webdav/movie1.mp4"
        
        self.moviesList?.addObject(movie1)
        
        let movie2:FilmsDto = FilmsDto()
        movie2.title = "Indiana Jones and the Temple of Doom"
        movie2.plot = "After arriving in India, Indiana Jones is asked by a desperate village to find a mystical stone. He agrees, and stumbles upon a secret cult plotting a terrible plan in the catacombs of an ancient palace."
        movie2.actors = "Harrison Ford, Kate Capshaw, Jonathan Ke Quan, Amrish Puri"
        movie2.director = "Steven Spielberg"
        movie2.runtime = "118 min"
        movie2.year = 1984
        movie2.posterLocal = UIImage(named: "movie2.jpg")
        movie2.filmUrl = "http://docker.oc.solidgear.es:53417/remote.php/webdav/movie2.mp4"
        
        self.moviesList?.addObject(movie2)
        
        let movie3:FilmsDto = FilmsDto()
        movie3.title = "Indiana Jones and the Last Crusade"
        movie3.plot = "When Dr. Henry Jones Sr. suddenly goes missing while pursuing the Holy Grail, eminent archaeologist Indiana Jones must follow in his father's footsteps and stop the Nazis."
        movie3.actors = "Harrison Ford, Sean Connery, Denholm Elliott, Alison Doody"
        movie3.director = "Steven Spielberg"
        movie3.runtime = "127 min"
        movie3.year = 1989
        movie3.posterLocal = UIImage(named: "movie3.jpg")
        movie3.filmUrl = "http://docker.oc.solidgear.es:53417/remote.php/webdav/movie3.mp4"
        
        self.moviesList?.addObject(movie3)
        
        
        
    }

    

}

