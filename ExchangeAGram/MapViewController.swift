//
//  MapViewController.swift
//  ExchangeAGram
//
//  Created by Frank Lee on 2014-11-07.
//  Copyright (c) 2014 franklee. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let request = NSFetchRequest(entityName: "FeedItem")
        let appDelegate:AppDelegate = (UIApplication.sharedApplication().delegate as AppDelegate)
        
        let context:NSManagedObjectContext = appDelegate.managedObjectContext! //don't need to specify NSManagedObjectContext type, it's inferred
        var error:NSError?
        
        //get back on the feedItems stored
        let itemArray = context.executeFetchRequest(request, error: &error) //address of error. nil is ok too.
        
        println(error) //debug checking
        
        if itemArray!.count > 0 {
            for item in itemArray! {
                let location = CLLocationCoordinate2D(latitude: Double(item.latitude), longitude: Double(item.longitude))
                let span = MKCoordinateSpanMake(0.05, 0.05)
                let region = MKCoordinateRegionMake(location, span)
                mapView.setRegion(region, animated: true)
                let annotation = MKPointAnnotation()
                annotation.setCoordinate(location)
                annotation.title = item.caption
                mapView.addAnnotation(annotation)
            }
        }
        
        
        //Adding an annotation (a red pin) and then center the map around that pin.
//        let location = CLLocationCoordinate2D(latitude: 48.868639224587, longitude: 2.37119161036255)
//        let span = MKCoordinateSpanMake(0.05, 0.05) //amount of map
//        
//        let region = MKCoordinateRegionMake(location, span) //paris location
//        
//        mapView.setRegion(region, animated: true) //set the region to the mapView
//        
//        let annotation = MKPointAnnotation() //annotation instance
//        
//        annotation.setCoordinate(location) //where you drop the coordinate
//        annotation.title = "Canal Saint-Martin"
//        annotation.subtitle = "Paris"
//        
//        mapView.addAnnotation(annotation)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
