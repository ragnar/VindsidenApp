//
//  RHEStationPickerViewController.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 05/09/14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import UIKit
import CoreData
import VindsidenKit



class RHEStationPickerViewController : UITableViewController, NSFetchedResultsControllerDelegate
{
    var changeIsUserDriven = false


    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    override func viewDidLoad()
    {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = self.editButtonItem()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("preferredContentSizeDidChange:"), name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }


    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)

        RHEVindsidenAPIClient.defaultManager().operationQueue.suspended = true
    }


    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        RHEVindsidenAPIClient.defaultManager().operationQueue.suspended = false
    }


    override func setEditing(editing: Bool, animated: Bool)
    {
        super.setEditing(editing, animated: animated)
        navigationItem.leftBarButtonItem?.enabled = !editing
    }


    func preferredContentSizeDidChange( notification: NSNotification )
    {
        tableView.reloadData()
    }


    func configureCell( cell: UITableViewCell, atIndexPath indexPath: NSIndexPath)
    {
        let station = fetchedResultsController.objectAtIndexPath(indexPath) as CDStation
        cell.textLabel?.text = station.stationName;
        cell.detailTextLabel?.text = station.city;

        if station.isHidden.boolValue {
            cell.imageView?.image = UIImage(named: "uncheckmark_icon", inBundle: nil, compatibleWithTraitCollection: self.traitCollection)
        } else {
            cell.imageView?.image = UIImage(named: "checkmark_icon", inBundle: nil, compatibleWithTraitCollection: self.traitCollection)
        }
    }


    // MARK: UITableView


    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        let sections = fetchedResultsController.sections as Array!
        return sections.count;
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let sections = fetchedResultsController.sections as Array!
        let sectionInfo = sections[section] as NSFetchedResultsSectionInfo

        return sectionInfo.numberOfObjects
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("StationCell", forIndexPath: indexPath) as UITableViewCell

        configureCell(cell, atIndexPath: indexPath)

        return cell;
    }


    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        return true
    }


    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        return true
    }


    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle
    {
        return .None
    }


    override func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        return false
    }


    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath)
    {
        if sourceIndexPath == destinationIndexPath {
            return
        }

        changeIsUserDriven = true

        var array = fetchedResultsController.fetchedObjects as [CDStation]
        let objectToMove = fetchedResultsController.objectAtIndexPath(sourceIndexPath) as CDStation
        array.removeAtIndex(sourceIndexPath.row)
        array.insert(objectToMove, atIndex: destinationIndexPath.row)

        var index = 0
        for object in array {
            object.order = index
            index += 1
        }

        let context = Datamanager.sharedManager().managedObjectContext!
        var error: NSError?

        if !context.save(&error) {
            println("Save failed: \(error!.localizedDescription)")
        }
    }


    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
    {
        cell.textLabel!.font = UIFont.preferredFontForTextStyle((cell.textLabel!.font.fontDescriptor().objectForKey("NSCTFontUIUsageAttribute") as String))
        cell.detailTextLabel!.font = UIFont.preferredFontForTextStyle((cell.detailTextLabel!.font.fontDescriptor().objectForKey("NSCTFontUIUsageAttribute") as String))
    }


    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let station = fetchedResultsController.objectAtIndexPath(indexPath) as CDStation
        //let cell = tableView.cellForRowAtIndexPath(indexPath)

        station.isHidden = NSNumber(bool: !station.isHidden.boolValue)
        //configureCell(cell!, atIndexPath: indexPath)

        let context = Datamanager.sharedManager().managedObjectContext!
        var error: NSError?

        if !context.save(&error) {
            println("Save failed: \(error!.localizedDescription)")
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: NSFetchedResultsController

    lazy var fetchedResultsController : NSFetchedResultsController = {
        NSFetchedResultsController.deleteCacheWithName("StationPicker")

        let contxt = Datamanager.sharedManager().managedObjectContext!

        let fetchRequest = NSFetchRequest(entityName: "CDStation")
        fetchRequest.fetchBatchSize = 20
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]

        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: contxt, sectionNameKeyPath: nil, cacheName: "StationPicker")
        controller.delegate = self

        let success = controller.performFetch(nil)
        if success == false {
            NSLog("Fetching stations failed")
            abort()
        }

        return controller
    }()


    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        if !changeIsUserDriven {
            tableView.beginUpdates()
        }
    }


    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    {
        if changeIsUserDriven {
            return
        }

        switch (type) {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Top)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Top)
        case .Update:
            configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }


    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        if !changeIsUserDriven {
            tableView.endUpdates()
        } else {
            tableView.reloadData()
        }

        changeIsUserDriven = false
    }
}

