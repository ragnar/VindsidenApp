//
//  CDStation+CoreDataProperties.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 15.06.15.
//  Copyright © 2015 RHC. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

public extension CDStation {

    @NSManaged var city: String?
    @NSManaged var coordinateLat: NSNumber?
    @NSManaged var coordinateLon: NSNumber?
    @NSManaged var copyright: String?
    @NSManaged var isHidden: NSNumber?
    @NSManaged var lastMeasurement: Date?
    @NSManaged var lastRefreshed: Date?
    @NSManaged var order: NSNumber?
    @NSManaged var stationId: NSNumber?
    @NSManaged var stationName: String?
    @NSManaged var stationText: String?
    @NSManaged var statusMessage: String?
    @NSManaged var webCamImage: String?
    @NSManaged var webCamText: String?
    @NSManaged var webCamURL: String?
    @NSManaged var yrURL: String?
    @NSManaged var plots: NSSet?

}
