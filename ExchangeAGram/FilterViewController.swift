//
//  FilterViewController.swift
//  ExchangeAGram
//
//  Created by Frank Lee on 2014-10-16.
//  Copyright (c) 2014 franklee. All rights reserved.
//

import UIKit
import Foundation

class FilterViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var thisFeedItem: FeedItem!
    var collectionView: UICollectionView!
    let kIntensity = 0.7
    var context:CIContext = CIContext(options: nil)
    var filters:[CIFilter] = []
    let placeHolderImage = UIImage(named: "Placeholder")
    let tmp = NSTemporaryDirectory() //store cache items temporarily
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        let layout = UICollectionViewFlowLayout() //determines the way items are organized in our collectionView
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) //cells are not drawn right beside each other
        layout.itemSize = CGSize(width: 150.0, height: 150.0)
        
        //setup instance for collectionView
        
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        
        //setup datasource and delegate
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.whiteColor()
        
        //This will register our FilterCell Class with the collection view, so that it knows which cell we will be using.
        
        collectionView.registerClass(FilterCell.self, forCellWithReuseIdentifier: "MyCell")
        
        //add the view (this becomes a subview of that view)
        
        self.view.addSubview(collectionView)
        
        filters = photoFilters()
        
    }
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.filters.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //this can be done now that FilterCell.self has been registered.
        let cell:FilterCell = collectionView.dequeueReusableCellWithReuseIdentifier("MyCell", forIndexPath: indexPath) as FilterCell
        
        cell.imageView.image = placeHolderImage             //placeholder image cells while loading
        //changed to only load one instance of UIImage to save processing time
        
        let filterQueue:dispatch_queue_t = dispatch_queue_create("filter queue", nil)   //All UI changes should be made on the main thread.

        //Load the filter rows async
        dispatch_async(filterQueue, { () -> Void in
            //let filterImage = self.filteredImageFromImage(self.thisFeedItem.thumbnail, filter: self.filters[indexPath.row]) OLD
            
            let filterImage = self.getCachedImage(indexPath.row)
            
            //get back to main queue (thread)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                cell.imageView.image = filterImage
            })
        })
        
        return cell
    }
    
    //UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        createUIAlertController(indexPath)

    }
    
    
    //Helper Function
    func photoFilters () -> [CIFilter] {
        
        let blur = CIFilter(name: "CIGaussianBlur")
        let instant = CIFilter(name: "CIPhotoEffectInstant")
        let noir = CIFilter(name: "CIPhotoEffectNoir")
        let transfer = CIFilter(name: "CIPhotoEffectTransfer")
        let unsharpen = CIFilter(name: "CIUnsharpMask")
        let monochrome = CIFilter(name: "CIColorMonochrome")
        
        let colorControls = CIFilter(name: "CIColorControls")
        colorControls.setValue(0.5, forKey: kCIInputSaturationKey)
        
        let sepia = CIFilter(name: "CISepiaTone")
        sepia.setValue(kIntensity, forKey: kCIInputIntensityKey)
        
        let colorClamp = CIFilter(name: "CIColorClamp")
        colorClamp.setValue(CIVector(x: 0.9, y: 0.9, z: 0.9, w: 0.9), forKey: "inputMaxComponents")
        colorClamp.setValue(CIVector(x: 0.2, y: 0.2, z: 0.2, w: 0.2), forKey: "inputMinComponents")
        
        let composite = CIFilter(name: "CIHardLightBlendMode")
        composite.setValue(sepia.outputImage, forKey: kCIInputImageKey)
        
        let vignette = CIFilter(name: "CIVignette")
        vignette.setValue(composite.outputImage, forKey: kCIInputImageKey)
        
        vignette.setValue(kIntensity * 2, forKey: kCIInputIntensityKey)
        vignette.setValue(kIntensity * 30, forKey: kCIInputRadiusKey)
        
        return [blur, instant, noir, transfer, unsharpen, monochrome, colorControls, sepia, colorClamp, composite, vignette]
    }
    
    func filteredImageFromImage (imageData: NSData, filter: CIFilter) -> UIImage {
        let unfilteredImage = CIImage(data: imageData)
        filter.setValue(unfilteredImage, forKey: kCIInputImageKey)
        let filteredImage:CIImage = filter.outputImage
        
        let extent = filteredImage.extent()
        let cgImage:CGImageRef = context.createCGImage(filteredImage, fromRect: extent)
        
        let finalImage = UIImage(CGImage: cgImage)
        
        return finalImage!
    }
    
    //UIAlertController Helper Functions
    func createUIAlertController (indexPath: NSIndexPath) {
        
        let alert = UIAlertController(title: "Photo options", message: "Please choose an option", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Add Caption!"
            textField.secureTextEntry = false
        }
        
        let textField = alert.textFields![0] as UITextField
        
        let photoAction = UIAlertAction(title: "Post Photo to Facebook With Caption", style: UIAlertActionStyle.Destructive) { (UIAlertAction) -> Void in
            self.shareToFacebook(indexPath)
            
            var text = textField.text
            self.saveFilterToCoreData(indexPath, caption: text) //uses self. because it's in an enclosure {}
        }
        
        alert.addAction(photoAction)
        
        let saveFilterAction = UIAlertAction(title: "Save Filter without posting on Facebook", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            var text = textField.text
            self.saveFilterToCoreData(indexPath, caption:text)
        }
        
        alert.addAction(saveFilterAction)
        
        let cancelAction = UIAlertAction(title: "Select another Filter", style: UIAlertActionStyle.Cancel) { (UIAlertAction) -> Void in
            
        }
        
        alert.addAction(cancelAction)
        
        self.presentViewController(alert, animated: true, completion: nil) //pop view controller off current navigation stack
        
    }
    
    func saveFilterToCoreData(indexPath: NSIndexPath, caption: String) {
        
        let filterImage = self.filteredImageFromImage(self.thisFeedItem.image, filter: self.filters[indexPath.row])
        
        let imageData = UIImageJPEGRepresentation(filterImage, 1.0)
        self.thisFeedItem.image = imageData
        
        let thumbNailData = UIImageJPEGRepresentation(filterImage, 0.1)
        self.thisFeedItem.thumbnail = thumbNailData
        
        self.thisFeedItem.caption = caption
        
        (UIApplication.sharedApplication().delegate as AppDelegate).saveContext()
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func shareToFacebook (indexPath: NSIndexPath) {
        //passes filtered image
        let filterImage = self.filteredImageFromImage(self.thisFeedItem.image, filter: self.filters[indexPath.row])
        
        let photos:NSArray = [filterImage]
        var params = FBPhotoParams()  //encapsulate info we're going to share
        params.photos = photos
        
        //calling function allowing us to pass in our photo (call result error from connecting to their API)
        FBDialogs.presentShareDialogWithPhotoParams(params, clientState: nil) { (call, result, error) -> Void in
            if (result? != nil) {
                println(result)
            } else {
                println(error)
            }
        }
    }

    //caching functions
    
    func cacheImage(imageNumber: Int) {
        let fileName = "\(imageNumber)-\(thisFeedItem.hashValue)"

        let uniquePath = tmp.stringByAppendingPathComponent(fileName)
        
        //check if filename exists at filepath, if not then ... generate filter
        if !NSFileManager.defaultManager().fileExistsAtPath(fileName) {
            
            let data = self.thisFeedItem.thumbnail
            let filter = self.filters[imageNumber]
            let image = filteredImageFromImage(data, filter: filter)
            UIImageJPEGRepresentation(image, 1.0).writeToFile(uniquePath, atomically: true)
            
            //save the file using uniquePath wit hthe appended fileName (imagenumber)
            //atomically true. Very small number of use cases where it's false.
        }
    }
    
    func getCachedImage (imageNumber: Int) -> UIImage {
        let fileName = "\(imageNumber)-\(thisFeedItem.hashValue)"

        let uniquePath = tmp.stringByAppendingPathComponent(fileName)
        
        var image:UIImage
        
        if NSFileManager.defaultManager().fileExistsAtPath(uniquePath) {
            image = UIImage(contentsOfFile: uniquePath)!
        } else {
            self.cacheImage(imageNumber)
            image = UIImage(contentsOfFile: uniquePath)!
        }
        
        return image
    }
}
















