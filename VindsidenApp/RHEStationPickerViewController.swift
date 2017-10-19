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


    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = self.editButtonItem
        NotificationCenter.default.addObserver(self, selector: #selector(RHEStationPickerViewController.preferredContentSizeDidChange(_:)), name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }


    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        navigationItem.leftBarButtonItem?.isEnabled = !editing
    }


    @objc func preferredContentSizeDidChange( _ notification: Notification ) {
        tableView.reloadData()
    }


    func configureCell( _ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let station = fetchedResultsController.object(at: indexPath) as! CDStation
        cell.textLabel?.text = station.stationName;
        cell.detailTextLabel?.text = station.city;

        if let hidden = station.isHidden, hidden == true {
            cell.imageView?.image = UIImage(named: "uncheckmark_icon", in: nil, compatibleWith: self.traitCollection)
        } else {
            cell.imageView?.image = UIImage(named: "checkmark_icon", in: nil, compatibleWith: self.traitCollection)
        }
    }


    // MARK: UITableView


    override func numberOfSections(in tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }

        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let sectionInfo = sections[section] as NSFetchedResultsSectionInfo

            return sectionInfo.numberOfObjects
        }

        return 0
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StationCell", for: indexPath) as UITableViewCell

        configureCell(cell, atIndexPath: indexPath)

        return cell;
    }


    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }


    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }


    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }


    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }


    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath == destinationIndexPath {
            return
        }

        changeIsUserDriven = true

        var array = fetchedResultsController.fetchedObjects as! [CDStation]
        let objectToMove = fetchedResultsController.object(at: sourceIndexPath) as! CDStation
        array.remove(at: sourceIndexPath.row)
        array.insert(objectToMove, at: destinationIndexPath.row)

        var index = 0
        for object in array {
            object.order = NSNumber(value: index)
            index += 1
        }

        let context = DataManager.shared.viewContext()

        do {
            try context.save()
        } catch let error as NSError {
            print("Save failed: \(error.localizedDescription)")
        }
    }


    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: (UIFontTextStyle(rawValue: cell.textLabel?.font.fontDescriptor.object(forKey: UIFontDescriptor.AttributeName(rawValue: "NSCTFontUIUsageAttribute")) as! String)))
        cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: (UIFontTextStyle(rawValue: cell.detailTextLabel?.font.fontDescriptor.object(forKey: UIFontDescriptor.AttributeName(rawValue: "NSCTFontUIUsageAttribute")) as! String)))
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let station = fetchedResultsController.object(at: indexPath) as! CDStation

        if let hidden = station.isHidden {
            station.isHidden = NSNumber(value: !hidden.boolValue as Bool)
        }

        if let hidden = station.isHidden, hidden.boolValue == false {
            DataManager.shared.addStationToIndex(station)
        } else {
            DataManager.shared.removeStationFromIndex(station)
        }


        let context = DataManager.shared.viewContext()

        do {
            try context.save()
        } catch let error as NSError {
            print("Save failed: \(error.localizedDescription)")
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }


    // MARK: NSFetchedResultsController


    lazy var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult> = {
        NSFetchedResultsController<NSFetchRequestResult>.deleteCache(withName: "StationPicker")

        let contxt = DataManager.shared.viewContext()

        let fetchRequest = CDStation.fetchRequest()
        fetchRequest.fetchBatchSize = 20
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]

        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: contxt, sectionNameKeyPath: nil, cacheName: "StationPicker")
        controller.delegate = self

        do {
            try controller.performFetch()
        } catch {
            NSLog("Fetching stations failed")
            abort()
        }

        return controller
    }()


    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if !changeIsUserDriven {
            tableView.beginUpdates()
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if changeIsUserDriven {
            return
        }

        switch (type) {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .top)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .top)
        case .update:
            if let cell = tableView.cellForRow(at: indexPath!) {
                configureCell(cell, atIndexPath: indexPath!)
            }
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        }
    }


    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if !changeIsUserDriven {
            tableView.endUpdates()
        } else {
            tableView.reloadData()
        }

        changeIsUserDriven = false
    }
}

