//
//  TodayViewController.swift
//  VindsidenToday
//
//  Created by Ragnar Henriksen on 10.06.14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import UIKit
import NotificationCenter
import VindsidenKit


class TodayViewController: UITableViewController, NCWidgetProviding, NSFetchedResultsControllerDelegate
{
    struct TableViewConstants {
        static let baseRowCount = 3
        static let todayRowHeight :CGFloat = 44.0
        static let todayRowPadding :CGFloat = 20.0
        struct CellIdentifiers {
            static let message = "Cell"
            static let showall = "ShowAll"
        }
    }


    deinit {
        _fetchedResultsController = nil
        DLOG("")
    }


    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }


    var showingAll: Bool = false {
        didSet {
            resetContentSize()
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()

        resetContentSize()
        tableView.reloadData()
        updateContentWithCompletionHandler()
    }


    // MARK: - NotificationCenter


    func widgetMarginInsetsForProposedMarginInsets( defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero;
    }


    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        DLOG("")
        completionHandler(.NewData)
        updateContentWithCompletionHandler(completionHandler: completionHandler)
    }


    // MARK: - TableView


    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let sections = fetchedResultsController.sections as Array!
        return sections.count;
    }


    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sections = fetchedResultsController.sections as Array!
        let sectionInfo = sections[section] as! NSFetchedResultsSectionInfo

        let rows:Int = showingAll ? sectionInfo.numberOfObjects : min(sectionInfo.numberOfObjects, TableViewConstants.baseRowCount + 1)
        return rows
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let itemCount = (fetchedResultsController.fetchedObjects as Array!).count

        if !showingAll && indexPath.row == TableViewConstants.baseRowCount &&  itemCount != TableViewConstants.baseRowCount + 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.showall, forIndexPath: indexPath) as! UITableViewCell
            cell.textLabel?.text = NSLocalizedString("Show All...", tableName: nil, bundle: NSBundle.mainBundle(), value: "Show all...", comment: "Show all")
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.message, forIndexPath: indexPath) as! RHCTodayCell
            var stationInfo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! CDStation
            var tmpplot: CDPlot? = stationInfo.lastRegisteredPlot()

            if let plot = tmpplot {
                let winddir = CGFloat(plot.windDir.floatValue)
                let windspeed = CGFloat(plot.windAvg.floatValue)
                let image = DrawArrow.drawArrowAtAngle( winddir, forSpeed:windspeed, highlighted:false, color: UIColor.whiteColor(), hightlightedColor: UIColor.blackColor())

                let raw = AppConfig.sharedConfiguration.applicationUserDefaults.integerForKey("selectedUnit")
                let unit = SpeedConvertion(rawValue: raw)

                if let realUnit = unit {
                    let speed = plot.windAvg.speedConvertionTo(realUnit)
                    if let speedString = speedFormatter.stringFromNumber(speed) {
                        cell.speedLabel.text = "\(speedString) \(NSNumber.shortUnitNameString(realUnit))"
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
    }


    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let itemCount = (fetchedResultsController.fetchedObjects as Array!).count

        if !showingAll && indexPath.row == TableViewConstants.baseRowCount &&  itemCount != TableViewConstants.baseRowCount + 1 {
            return showCellHeight()
        } else {
            return infoCellHeight()
        }
    }


    override func tableView(_: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.layer.backgroundColor = UIColor.clearColor().CGColor
        cell.configureSelectedBackgroundView()
    }

    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        if !showingAll && indexPath.row == TableViewConstants.baseRowCount {
            showingAll = true
            let itemCount = (fetchedResultsController.fetchedObjects as Array!).count

            tableView.beginUpdates()

            let indexPathForRemoval = NSIndexPath(forRow: TableViewConstants.baseRowCount, inSection: 0)
            tableView.deleteRowsAtIndexPaths([indexPathForRemoval], withRowAnimation: .Fade)

            var insertedIndexPaths = Array<NSIndexPath>()

            for idx in TableViewConstants.baseRowCount..<itemCount {
                insertedIndexPaths.append(NSIndexPath(forRow: idx, inSection: 0))
            }

            tableView.insertRowsAtIndexPaths(insertedIndexPaths, withRowAnimation: .Fade)

            tableView.endUpdates()
            
            return
        }

        let stationInfo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! CDStation

        let url = NSURL(string: "vindsiden://station/\(stationInfo.stationId)?todayView=1")
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

        _fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: Datamanager.sharedManager().managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        _fetchedResultsController!.delegate = self

        let success = _fetchedResultsController!.performFetch(nil)
        if success == false {
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
        let infoHeight = infoCellHeight()
        let showHeight = showCellHeight()
        let itemCount = (fetchedResultsController.fetchedObjects as Array!).count
        let rowCount = showingAll ? itemCount : min(itemCount, TableViewConstants.baseRowCount + 1)

        if !showingAll {
            if itemCount > TableViewConstants.baseRowCount {
                return infoHeight*CGFloat(rowCount-1) + showHeight - 1.0
            } else {
                return infoHeight*CGFloat(rowCount) - 1.0
            }
        } else {
            return infoHeight*CGFloat(rowCount) - 1.0
        }
    }


    func infoCellHeight() -> CGFloat {
        let infoCell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.message) as! RHCTodayCell
        infoCell.nameLabel?.text = "123"
        infoCell.updatedLabel?.text = "123"
        infoCell.layoutIfNeeded()

        let infoSize = infoCell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        return infoSize.height
    }


    func showCellHeight() -> CGFloat {
        let infoCell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.showall) as! UITableViewCell
        infoCell.textLabel?.text = "123"
        infoCell.layoutIfNeeded()

        let infoSize = infoCell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        return infoSize.height
    }


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
