//
//  FeedItem.swift
//  ExchangeAGram
//
//  Created by Frank Lee on 2014-11-07.
//  Copyright (c) 2014 franklee. All rights reserved.
//

import Foundation
import CoreData

@objc(FeedItem)
class FeedItem: NSManagedObject {

    @NSManaged var caption: String
    @NSManaged var image: NSData
    @NSManaged var thumbnail: NSData
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber

}
