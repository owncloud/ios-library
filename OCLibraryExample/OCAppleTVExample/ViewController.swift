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
    var moviesList: [FilmsDto] = []
    
    @IBOutlet weak var viewMovieInfoCointainer: UIView?
    @IBOutlet weak var backgroundMovieInfoCointainer: UIImageView?
    @IBOutlet weak var filmsCollectionView: UICollectionView?
    
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var plotLabel: UILabel?
    @IBOutlet weak var actorsLabel: UILabel?
    @IBOutlet weak var directorLabel: UILabel?
    @IBOutlet weak var runtimeLabel: UILabel?
    @IBOutlet weak var yearLabel: UILabel?
    @IBOutlet weak var posterImage: UIImageView?
    
    var urlString: String?
    var userName: String?
    var password: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.loadFilmList()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadFilmList (){
        
        OCConnection.sharedInstance.getVideoFilesOfRootFolder (self.urlString!, userName: self.userName!, password: self.password!) { (success, films) -> Void in
            
            if success{
                
                self.moviesList = films!
                
                for current:FilmsDto in self.moviesList {
                    
                    OMDbApiRequests.sharedInstance.getDataOfFilm(current, completionHandler: { (success, film) -> Void in
                        
                        dispatch_async(dispatch_get_main_queue(),{
                            self.filmsCollectionView?.reloadData()
                        })
                        
                    })
               
                }
                
            }
            
        }
        
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.moviesList.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: MovieCell = collectionView.dequeueReusableCellWithReuseIdentifier(kMovieCellIdentifier, forIndexPath: indexPath) as! MovieCell

        let currentMovie:FilmsDto = self.moviesList[indexPath.row]
        
        if currentMovie.posterUrl != nil {
            
            cell.posterImageView.downloadedFrom(link: currentMovie.posterUrl!, contentMode: .ScaleAspectFill)
            
        }else{

           cell.posterImageView.image = currentMovie.posterLocal
           
        }
        

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
        
        let currentMovie:FilmsDto = (self.moviesList[indexPath.row])
        
        let vc = VideoPlayerViewController()
        self.presentViewController(vc, animated: true, completion: nil)
        vc.playVideo(currentMovie.filmUrl!, userName: self.userName!, password: self.password!)
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
        
        print(context.nextFocusedIndexPath?.row.description)
        
        if (context.nextFocusedIndexPath != nil) {
            
            let currentMovie:FilmsDto = self.moviesList[(context.nextFocusedIndexPath?.row)!]
            
            
            //Movie info
            self.titleLabel?.text = currentMovie.title
            self.plotLabel?.text = currentMovie.plot
            self.actorsLabel?.text = currentMovie.actors
            self.directorLabel?.text = currentMovie.director
            self.yearLabel?.text = currentMovie.year //(currentMovie.year)?.description
            self.runtimeLabel?.text = currentMovie.runtime
            
            
            if currentMovie.posterUrl != nil{
                self.posterImage?.downloadedFrom(link: currentMovie.posterUrl!, contentMode: .ScaleToFill)
            }else{
                self.posterImage?.image = currentMovie.posterLocal
            }
            
//            
//            let gradient: CAGradientLayer = CAGradientLayer()
//            gradient.frame = view.bounds
//            gradient.colors = [UIColor.whiteColor().CGColor, UIColor.blackColor().CGColor]
//            self.posterImage!.layer.insertSublayer(gradient, atIndex: 0)
//            
            //Image background
            
            if currentMovie.posterUrl != nil{
                self.backgroundMovieInfoCointainer?.downloadedFrom(link: currentMovie.posterUrl!, contentMode: .ScaleToFill)
            }else{
                self.backgroundMovieInfoCointainer?.image = currentMovie.posterLocal
            }
            
            self.backgroundMovieInfoCointainer!.contentMode = UIViewContentMode.ScaleAspectFill
           // self.backgroundMovieInfoCointainer?.alpha = 0.3
            
            /*let darkBlur = UIBlurEffect(style: UIBlurEffectStyle.Dark)
            let blurView = UIVisualEffectView(effect: darkBlur)
            blurView.frame = self.backgroundMovieInfoCointainer!.bounds
            self.backgroundMovieInfoCointainer!.addSubview(blurView)*/
        }
        
    }

}

extension UIImageView {
    func downloadedFrom(link link:String, contentMode mode: UIViewContentMode) {
        guard
            let url = NSURL(string: link)
            else {return}
        contentMode = mode
        NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, _, error) -> Void in
            guard
                let data = data where error == nil,
                let image = UIImage(data: data)
                else { return }
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.image = image
            }
        }).resume()
    }
}


