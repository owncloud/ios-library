//
//  OMDbApiRequests.swift
//  OCLibraryExample
//
//  Created by Javier Gonzalez on 17/12/15.
//  Copyright © 2015 ownCloud. All rights reserved.
//

import UIKit
import Alamofire

class OMDbApiRequests {
    
    class var sharedInstance: OMDbApiRequests {
        struct Static {
            static let instance: OMDbApiRequests = OMDbApiRequests()
        }
        return Static.instance
    }
    
    private init() {
        print("init");
    }

    
    func getDataOfFilm (currentFilm:FilmsDto, completionHandler:(success:Bool, film: FilmsDto?) -> Void) {
        
        var film: FilmsDto = currentFilm
        
        //1. Remove the extension
        let fileNameWithoutExtension = NSURL(fileURLWithPath:currentFilm.filmUrl!).URLByDeletingPathExtension!.lastPathComponent
        
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
                
                if response.result.isSuccess {
                    
                    let JSON: NSDictionary = response.result.value as! NSDictionary

                    print(JSON)
                    
                    if let actors: String = JSON["Actors"] as? String {
                      film.actors = actors
                    }
                    
                    if let awards: String = JSON["Awards"] as? String {
                        film.awards = awards
                    }
                    
                    if let director: String = JSON["Director"] as? String {
                        film.director = director
                    }
                    
                    if let genre: String = JSON["Genre"] as? String {
                        film.genre = genre
                    }
                    
                    if let poster: String = JSON["Poster"] as? String {
                        film.posterUrl = poster
                    }
                    
                    if let country: String = JSON["Country"] as? String {
                        film.country = country
                    }
                    
                    if let language: String = JSON["Language"] as? String {
                        film.language = language
                    }
                    
                    if let language: String = JSON["Language"] as? String {
                        film.language = language
                    }
                    
                    if let metascore: String = JSON["Metascore"] as? String {
                         film.metascore = metascore
                    }
                    
                    if let plot: String = JSON["Plot"] as? String {
                        film.plot = plot
                    }
                    
                    if let rated: String = JSON["Rated"] as? String {
                        film.rated = rated
                    }
                    
                    if let released: String = JSON["Released"] as? String {
                        film.released = released
                    }
                    
                    if let released: String = JSON["Released"] as? String {
                        film.released = released
                    }
                    
                    if let runtime: String = JSON["Runtime"] as? String {
                        film.runtime = runtime
                    }
                    
                    if let title: String = JSON["Title"] as? String {
                        film.title = title
                    }
                    
                    if let filmType: String = JSON["Type"] as? String {
                        film.type = filmType
                    }
                    
                    if let writer: String = JSON["Writer"] as? String {
                        film.writer = writer
                    }
                    
                    if let year: String = JSON["Year"] as? String {
                        film.year = year
                    }
                    
                    if let imdbID: String = JSON["imdbID"] as? String {
                        film.imdbId = imdbID
                    }
                    
                    if let imdbRating: String = JSON["imdbRating"] as? String {
                        film.imdbRating = imdbRating
                    }
                    
                    if let imdbVotes: String = JSON["imdbVotes"] as? String {
                        film.imdbVotes = imdbVotes
                    }


                    completionHandler(success: true, film: film)
                    
                    
                }else{
                     print("Request failed with error: \(response.result.error)")
                }
                

               /* switch response.result {
                case .Success(let JSON):
                   // let dict: NSDictionary = JSON as! NSDictionary
                    
                 //   print("Success with JSON: \(dict)")
                    
                   // film.actors = JSON["Actors"].String
 
                    
                case .Failure(let error):
                    print("Request failed with error: \(error)")

                }*/
                
               
                
                //print(response.request)  // original URL request
                //print(response.response) // URL response
                //print(response.data)     // server data
                //print(response.result)   // result of response serialization
                
                /*if let JSON = response.result.value {
                    print("JSON: \(JSON)")
                }*/
        }
    }
    

}

