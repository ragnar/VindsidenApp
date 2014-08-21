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
        static let todayRowHeight = 44.0

        struct CellIdentifiers {
            static let content = "todayViewCell"
            static let message = "Cell"
            static let showall = "ShowAll"
        }
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }


    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        // Custom initialization
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        let count = self.fetchedResultsController.fetchedObjects.count
        let height: CGFloat = 44.0 * CGFloat(count)
        preferredContentSize = CGSizeMake(320.0, height);
    }


    func widgetMarginInsetsForProposedMarginInsets( defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets
    {
        return UIEdgeInsetsMake( defaultMarginInsets.top, 30.0, defaultMarginInsets.bottom, 10)
    }


    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Perform any setup necessary in order to update the view.

        // If an error is encoutered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        if 1 == 1 {
            tableView.reloadData()
            completionHandler(NCUpdateResult.NewData)
        } else {
            completionHandler(NCUpdateResult.NoData)
        }
    }

    // TableView

    override func numberOfSectionsInTableView(tableView: UITableView!) -> Int
    {
        return self.fetchedResultsController.sections.count;
    }

    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int
    {
        let sectionInfo = self.fetchedResultsController.sections[section] as NSFetchedResultsSectionInfo
        return min( sectionInfo.numberOfObjects, TableViewConstants.baseRowCount+1)
    }

    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!
    {
        if indexPath.row == TableViewConstants.baseRowCount /*&&  list!.count != TableViewConstants.baseRowCount + 1*/ {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.showall, forIndexPath: indexPath) as UITableViewCell
            cell.textLabel.text = NSLocalizedString("Show All...", comment: "")
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as RHCTodayCell
            let stationInfo = self.fetchedResultsController.objectAtIndexPath(indexPath) as CDStation
            let tmpplot: CDPlot? = stationInfo.lastRegisteredPlot()

            if let plot = tmpplot {
                let image = DrawArrow.drawArrowAtAngle(plot.windDir, forSpeed: plot.windAvg, highlighted: false, color: UIColor.whiteColor(), hightlightedColor: UIColor.blackColor())

                let unit = SpeedConvertion.ToMetersPerSecond // NSUserDefaults.standardUserDefaults().integerForKey("selectedUnit")
                let speed = plot.windAvg.speedConvertionTo(unit)
                cell.speedLabel!.text = "\(speedFormatter.stringFromNumber(speed)) \(NSNumber.shortUnitNameString(unit))"
                cell.arrowImageView!.image = image
            } else {
                cell.speedLabel!.text = "—.—"
                //cell.arrowImageView.image = nil;
            }
            cell.nameLabel!.text = stationInfo.stationName

            return cell
        }
    }

    override func tableView(_: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.layer.backgroundColor = UIColor.clearColor().CGColor
    }

    override func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!)
    {
        let stationInfo = self.fetchedResultsController.objectAtIndexPath(indexPath) as CDStation

        let url = NSURL.URLWithString("vindsiden://station/\(stationInfo.stationId)")
        extensionContext.openURL(url, completionHandler: nil)
    }

    // NSFetchedResultsController

    var fetchedResultsController: NSFetchedResultsController {
        if let actual = _fetchedResultsController {
            return actual
        }

        let fetchRequest = NSFetchRequest(entityName: "CDStation")
        fetchRequest.fetchBatchSize = 3
        fetchRequest.fetchLimit = TableViewConstants.baseRowCount+1
        fetchRequest.predicate = NSPredicate(format: "isHidden = NO", argumentArray: nil)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]

        _fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: Datamanager.sharedManager().managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        _fetchedResultsController!.delegate = self

        let success = _fetchedResultsController!.performFetch(nil)
        if success == false {
            NSLog("Fetching stations failed")
            abort()
        }

        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController? = nil;


    func controllerDidChangeContent(controller: NSFetchedResultsController!) {
        if tableView.editing == false {
            tableView.reloadData()
        }
    }


    var speedFormatter : NSNumberFormatter {
        if let actual = _speedFormatter {
            return actual
        }

        _speedFormatter = NSNumberFormatter()
        _speedFormatter!.numberStyle = NSNumberFormatterStyle.DecimalStyle
        _speedFormatter!.maximumFractionDigits = 1
        _speedFormatter!.minimumFractionDigits = 1
        _speedFormatter!.minimumSignificantDigits = 1
        _speedFormatter!.notANumberSymbol = "—.—"
        _speedFormatter!.nilSymbol = "—.—"

        return _speedFormatter!
    }
    var _speedFormatter: NSNumberFormatter? = nil;
}

