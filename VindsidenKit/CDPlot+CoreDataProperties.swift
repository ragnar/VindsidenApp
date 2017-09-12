//
//  CDPlot+CoreDataProperties.swift
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

public extension CDPlot {

    @NSManaged var plotTime: Date?
    @NSManaged var tempAir: NSNumber?
    @NSManaged var tempWater: NSNumber?
    @NSManaged var windAvg: NSNumber?
    @NSManaged var windDir: NSNumber?
    @NSManaged var windMax: NSNumber?
    @NSManaged var windMin: NSNumber?
    @NSManaged var dataId: NSNumber?
    @NSManaged var station: CDStation?

}
