//
//  DKMapCompleteTF.swift
//  DKAutoCompleteTextField Example
//
//  Created by Darvish Kamalia on 10/12/15.
//  Copyright © 2015 Darvish Kamalia. All rights reserved.
//

import UIKit
import MapKit


@objc protocol DKMapCompleteTFDelegate {
    
    /*
        @function: didSelectLocationFromTable
        @param: locationSelected The location that the user chooses from the suggested location
        
        This function is called when the user selects a location from the suggested locations presented below the text field 
    
    */

    optional func didSelectLocationFromTable (locationSelected: MKMapItem)
    
    
    /*


        @function: searchDidReturnError
        @param: error The error that occured
        
        This function is called if the geocode search for the current text of the textfield returned an error.

        @warning: This function could potentially be called every time the user changes the characters in the textfield. Do not create pop-up dialogs of this error's description.

    */
    
    optional func searchDidReturnError(error: NSError)
    
}


/*
    
    @class: DKMapCompleteTF
    @discussion: A custom text field that provides uses geocoding to allow users to choose a location once they have
                entered part of an address 


*/
public class DKMapCompleteTF: UITextField, UITableViewDelegate, UITableViewDataSource {
    
    var completeTable: UITableView! = nil
    var currentResults : [MKMapItem] = []
    
    var minimumInputLengthForSearch = 5
    
    var ROW_HEIGHT: CGFloat = 40
    var MAX_HEIGHT: CGFloat = 100
    
    var DKDelegate: DKMapCompleteTFDelegate? = nil
    
    required public init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()
        
        notificationCenter.addObserverForName(UITextFieldTextDidChangeNotification, object: self, queue: mainQueue) { notification  in
            
            if (self.text!.characters.count > self.minimumInputLengthForSearch) {
                
                if( self.completeTable == nil) {
                    
                    self.initCompleteTable()
                }
                
                self.makeRequestWithString(self.text!)
                
            }
            
        }
        
        
        notificationCenter.addObserverForName(UITextFieldTextDidBeginEditingNotification, object: self, queue: mainQueue) { _ in
            
            
            if (self.completeTable == nil) {
                
                self.initCompleteTable()
                
            }
            
        }
    
    
    }
    
    required override public init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.blackColor()
        
     
    }
    

    
    func initCompleteTable() {
        
        
        completeTable = UITableView(frame: CGRect(x: self.frame.origin.x, y: self.frame.origin.y + self.frame.height, width: self.frame.width, height:0), style: UITableViewStyle.Plain)
        
        completeTable.registerNib(UINib(nibName: "MapAutoCompleteTVC", bundle: NSBundle(forClass: self.dynamicType)), forCellReuseIdentifier: "MapAutoCompleteCell")
        
        
        self.superview!.addSubview(completeTable)
        
        completeTable.dataSource = self
        completeTable.delegate = self
    }
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return ROW_HEIGHT
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("MapAutoCompleteCell")
        
        let currentResult = currentResults[indexPath.row]
        
        cell!.textLabel?.text = self.getStreetAddressStringFromPlacemark(currentResult.placemark)
        cell!.detailTextLabel?.text = self.getLocalityFromPlacemark(currentResult.placemark)
        
        return cell!
        
    }
    
    public
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        self.text = self.getStreetAddressStringFromPlacemark(currentResults[indexPath.row].placemark)
        self.completeTable.removeFromSuperview()
        self.completeTable = nil
    }
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.currentResults.count
    
    }
    
    
    public func makeRequestWithString(input: String) {
        
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = input
        
        let search = MKLocalSearch(request: request)
        
       let spinner = UIActivityIndicatorView(frame: CGRect(x: self.frame.origin.x, y: self.frame.origin.y + self.frame.height, width: self.frame.width, height: self.frame.height))
        spinner.startAnimating()
        
        self.completeTable.addSubview(spinner)
     
        
        search.startWithCompletionHandler { (searchResponse, searchError) -> Void in
            
            
            if (searchError == nil && searchResponse != nil) {
                
                
                self.currentResults = searchResponse!.mapItems
                
                
            }
            
            else if (searchError != nil) {
                
                self.DKDelegate?.searchDidReturnError?(searchError!)
                
            }
            
            let currentFrame = self.completeTable.frame
            
            var newHeight:CGFloat = 0
            
            if (self.currentResults.count < 5) {
                
                
                newHeight = CGFloat(self.currentResults.count) * self.ROW_HEIGHT
            }
                
            else {
                
                newHeight = self.MAX_HEIGHT
            }
            
            self.completeTable.frame = CGRect(x: currentFrame.origin.x, y: currentFrame.origin.y, width: currentFrame.width, height: newHeight)
            
            spinner.stopAnimating()
            self.completeTable.reloadData()
            
        }
    
        
    }
    
    public func getStreetAddressStringFromPlacemark (pm: CLPlacemark) -> String {
        
        var result = ""
        
        if (pm.subThoroughfare != nil) {
            
            result += " " + pm.subThoroughfare!
        }
        
        if (pm.thoroughfare != nil) {
            
            result += " " + pm.thoroughfare!
        }
        
        return result
        
        
    }
    
    public func getLocalityFromPlacemark (pm: CLPlacemark) -> String {
        
        var result = ""
        
        if (pm.subLocality != nil) {
            
            result += " " + pm.subLocality!
        }
        
        if (pm.locality != nil) {
            
            result += ", " + pm.locality!
        }
        
        if (pm.administrativeArea != nil) {
            
            result += " " + pm.administrativeArea!
        }
        
        return result
    
    }
    
    
    
    

}
