//
//  TodayViewController.swift
//  VindsidenToday
//
//  Created by Ragnar Henriksen on 10.06.14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import UIKit
import NotificationCenter
import CoreData
import VindsidenKit


class TodayViewController: UITableViewController, NCWidgetProviding, NSFetchedResultsControllerDelegate
{
    struct TableViewConstants {
        static let todayRowHeight :CGFloat = 46.0
        struct CellIdentifiers {
            static let message = "Cell"
        }
    }


    deinit {
        _fetchedResultsController = nil
        DLOG("")
    }


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        extensionContext?.widgetLargestAvailableDisplayMode = .Expanded

        tableView.tableFooterView = UIView()

        resetContentSize()
        tableView.reloadData()
        updateContentWithCompletionHandler()
    }


    // MARK: - NotificationCenter


    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        DLOG("")
        completionHandler(.NewData)
        updateContentWithCompletionHandler(completionHandler)
    }


    func widgetActiveDisplayModeDidChange(activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        DLOG("mode: \(activeDisplayMode), size: \(maxSize)")

        let cellHeight = infoCellHeight()

        var adjustedHeight = preferredViewHeight

        while ( adjustedHeight > maxSize.height) {
            adjustedHeight -= cellHeight
        }

        tableView.reloadData()

        let size = CGSize(width: maxSize.width, height: min(maxSize.height, adjustedHeight))
        preferredContentSize = size
    }

    // MARK: - TableView


    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let sections = fetchedResultsController.sections as Array!
        return sections.count;
    }


    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sections = fetchedResultsController.sections as Array!
        let sectionInfo = sections[section]

        if extensionContext?.widgetActiveDisplayMode == .Compact {
            return min(sectionInfo.numberOfObjects, 2)
        }
        return sectionInfo.numberOfObjects
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.message, forIndexPath: indexPath) as! RHCTodayCell
        let stationInfo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! CDStation

        if let plot = stationInfo.lastRegisteredPlot() {

            let winddir = CGFloat(plot.windDir!.floatValue)
            let windspeed = CGFloat(plot.windAvg!.floatValue)
            let image = DrawArrow.drawArrowAtAngle( winddir, forSpeed:windspeed, highlighted:false, color: UIColor.vindsidenTodayTextColor(), hightlightedColor: UIColor.blackColor())

            let raw = AppConfig.sharedConfiguration.applicationUserDefaults.integerForKey("selectedUnit")
            let unit = SpeedConvertion(rawValue: raw)

            if let realUnit = unit {
                let speed = plot.windAvg!.speedConvertionTo(realUnit)
                if let speedString = speedFormatter.stringFromNumber(speed) {
                    cell.speedLabel.text = speedString
                    cell.unitLabel.text = NSNumber.shortUnitNameString(realUnit)
                } else {
                    cell.speedLabel.text = "—.—"
                }
            }
            cell.arrowImageView.image = image
            cell.updatedLabel.text = AppConfig.sharedConfiguration.relativeDate(plot.plotTime) as String
        } else {
            cell.speedLabel.text = "—.—"
            cell.updatedLabel.text = NSLocalizedString("LABEL_NOT_UPDATED", tableName: nil, bundle: NSBundle.mainBundle(), value: "LABEL_NOT_UPDATED", comment: "Not updated")
        }
        cell.nameLabel.text = stationInfo.stationName
        return cell
    }


    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return infoCellHeight()
    }


    override func tableView(_: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.layer.backgroundColor = UIColor.clearColor().CGColor
        cell.configureSelectedBackgroundView()
    }

    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        let stationInfo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! CDStation

        let url = NSURL(string: "vindsiden://station/\(stationInfo.stationId!)?todayView=1")
        if let actual = url {
            extensionContext?.openURL( actual, completionHandler:  nil)
        }
    }


    // MARK: - NSFetchedResultsController


    var fetchedResultsController: NSFetchedResultsController {
        if let actual = _fetchedResultsController {
            return actual
        }

        let fetchRequest = NSFetchRequest(entityName: "CDStation")
        fetchRequest.fetchBatchSize = 3
        fetchRequest.predicate = NSPredicate(format: "isHidden = NO", argumentArray: nil)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]

        _fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: Datamanager.sharedManager().managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        _fetchedResultsController!.delegate = self

        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            NSLog("Fetching stations failed")
            abort()
        }

        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController? = nil;


    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if tableView.editing == false {
            tableView.reloadData()
        }
    }


    // MARK: -


    lazy var speedFormatter : NSNumberFormatter = {
        let _speedFormatter = NSNumberFormatter()
        _speedFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        _speedFormatter.maximumFractionDigits = 1
        _speedFormatter.minimumFractionDigits = 1
        _speedFormatter.notANumberSymbol = "—.—"
        _speedFormatter.nilSymbol = "—.—"

        return _speedFormatter
    }()


    func resetContentSize() {
        var preferredSize = preferredContentSize
        preferredSize.height = preferredViewHeight
        preferredSize.width = 320.0;
        preferredContentSize = preferredSize
    }


    var preferredViewHeight: CGFloat {
        let itemCount = (fetchedResultsController.fetchedObjects as Array!).count
        let rowCount = itemCount

        let infoHeight = TableViewConstants.todayRowHeight
        return (infoHeight*CGFloat(rowCount)) - 1.0
    }


    func infoCellHeight() -> CGFloat {
        return TableViewConstants.todayRowHeight

        // Gives autolayout error
//        let cell = infoCell
//        cell.nameLabel?.text = "123"
//        cell.updatedLabel?.text = "123"
//        cell.layoutIfNeeded()
//
//        let infoSize = cell.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
//        return max(infoSize.height, 50)
    }


    lazy var infoCell: RHCTodayCell = {
        return self.tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.message) as! RHCTodayCell
    }()


    // MARK: - Fetch


    func updateContentWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)? = nil) {
        DLOG("Updating content")
        WindManager.sharedManager.fetch { (fetchResult: UIBackgroundFetchResult) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
                completionHandler?(.NewData)
                return
            })
        }

        //_fetchedResultsController = nil
    }
}
