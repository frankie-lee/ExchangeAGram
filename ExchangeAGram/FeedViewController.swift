//
//  FeedViewController.swift
//  ExchangeAGram
//
//  Created by Frank Lee on 2014-10-14.
//  Copyright (c) 2014 franklee. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreData
import MapKit

class FeedViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!

    var feedArray: [AnyObject] = [] //empty array of any data type (we don't know)
    
    var locationManager: CLLocationManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //most precise location
        locationManager.requestAlwaysAuthorization() //Is it OK to give the location of the device
        
        locationManager.distanceFilter = 100.0 //how many distance should elapse before updating
        locationManager.startUpdatingLocation()
    }
    
    override func viewDidAppear(animated:Bool) {
        //We're about to fetch data from Coredata, in a less abstracted way
        let request = NSFetchRequest(entityName: "FeedItem") //get all the feedItems we have saved
        let appDelegate:AppDelegate = (UIApplication.sharedApplication().delegate as AppDelegate) //access to appdelegate instance
        let context:NSManagedObjectContext = appDelegate.managedObjectContext!
        
        feedArray = context.executeFetchRequest(request, error: nil)! //pass in request, get FeedItem entity from managedobjectcontext. We don't know what type it will return (that's why we use AnyObject)
        
        collectionView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Buttons
    
    @IBAction func profileTapped(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("profileSegue", sender: nil)
    }
    
    @IBAction func snapBarButtonItemTapped(sender: UIBarButtonItem) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            var cameraController = UIImagePickerController() //special type of UIImage Controller (pictures, movies)
            cameraController.delegate = self //when functions are called in UIImagePickerControllerDelegate protocol, sends to self (FeedViewController)
            cameraController.sourceType = UIImagePickerControllerSourceType.Camera
            
            let mediaTypes:[AnyObject]  = [kUTTypeImage] //abstract type (array). Identifier for a type of data (image data)
            cameraController.mediaTypes = mediaTypes
            cameraController.allowsEditing = false //don't allow editing to photos in application
            
            self.presentViewController(cameraController, animated: true, completion: nil)
        }
        
        else if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            var photoLibraryController = UIImagePickerController()
            photoLibraryController.delegate = self
            photoLibraryController.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            
            let mediaTypes:[AnyObject] = [kUTTypeImage] //hold any datatype?
            photoLibraryController.mediaTypes = mediaTypes
            photoLibraryController.allowsEditing = false
            self.presentViewController(photoLibraryController, animated: true, completion: nil)
        }
        
        else {
            var alertView = UIAlertController(title: "Alert", message: "Your Device does not support the camera or photo Library", preferredStyle: UIAlertControllerStyle.Alert)
            alertView.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alertView, animated: true, completion: nil)
        }
    }
    
    //UIImagePickerControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        let image = info[UIImagePickerControllerOriginalImage] as UIImage //key to access value (info dictionary)
        let imageData = UIImageJPEGRepresentation(image, 1.0) //convert UIImage instance into JPEG representation to NSDATA
        let thumbNailData = UIImageJPEGRepresentation(image, 0.1) //convert image to thumbnail
        
        let managedObjectContext = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext
        let entityDescription = NSEntityDescription.entityForName("FeedItem", inManagedObjectContext: managedObjectContext!)
        
        //managedObjectContext could be optional (nil) but we know it exists, so force unwrap
        
        let feedItem = FeedItem(entity: entityDescription!,insertIntoManagedObjectContext: managedObjectContext!)
        
        feedItem.image = imageData
        feedItem.caption = "Test Caption"
        feedItem.thumbnail = thumbNailData

        feedItem.latitude = locationManager.location.coordinate.latitude
        feedItem.longitude = locationManager.location.coordinate.longitude
        
        (UIApplication.sharedApplication().delegate as AppDelegate).saveContext() //save changes to coredata
        
        feedArray.append(feedItem) //add feedItem to Array
        
        //select image, stores as image in dictionary, dismiss view controller
        self.dismissViewControllerAnimated(true, completion: nil)
        
        self.collectionView.reloadData() //reloads the data in the collectionView
    }
    
    //UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    //Determine # of cells in our one section dynamically. (count the numbe of images, set the same amount of cells)
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return feedArray.count //number of items in feed array
    }
    
    //What to put in each cell (dequeueReusableCellWithReuseIdentifier)
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var cell:FeedCell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as FeedCell
        //identity which cell we're using, and what type (FeedCell from storyboard)
        

        let thisItem = feedArray[indexPath.row] as FeedItem   //Grab item from feedArray (bit of misnomer with .row for indexpath)
        cell.imageView.image = UIImage(data:thisItem.image)   //set the imageview to the image pulled from feedArray
        cell.captionLabel.text = thisItem.caption             //set the caption for that entity item (along with image)
    
        return cell
    }
    
    //UICollectionViewDelegate
    
    //sample code for creating viewcontrollers in code (for understanding).
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let thisItem = feedArray[indexPath.row] as FeedItem
        
        var filterVC = FilterViewController() //view controllers are instances too.
        filterVC.thisFeedItem = thisItem
        
        self.navigationController?.pushViewController(filterVC, animated:false) //self.navigationController is an optional. There's a chance you're not in a navigation controller stack.
    }
    
    //CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        println("locations = \(locations)")
    }
}


