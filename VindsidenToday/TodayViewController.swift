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

    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }


    let dateTransformer = SORelativeDateTransformer()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    var showingAll: Bool = false {
        didSet {
            resetContentSize()
        }
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        resetContentSize()
        tableView.reloadData()
    }

    // MARK: - NotificationCenter

    func widgetMarginInsetsForProposedMarginInsets( defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets
    {
        return UIEdgeInsetsZero;
    }


    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!)
    {
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

    // MARK: - TableView

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        let sections = fetchedResultsController.sections as Array!
        return sections.count;
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let sections = fetchedResultsController.sections as Array!
        let sectionInfo = sections[section] as NSFetchedResultsSectionInfo

        let rows:Int = showingAll ? sectionInfo.numberOfObjects : min(sectionInfo.numberOfObjects, TableViewConstants.baseRowCount + 1)
        return rows
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let itemCount = (fetchedResultsController.fetchedObjects as Array!).count

        if !showingAll && indexPath.row == TableViewConstants.baseRowCount &&  itemCount != TableViewConstants.baseRowCount + 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.showall, forIndexPath: indexPath) as UITableViewCell
            cell.textLabel!.text = NSLocalizedString("Show All...", comment: "")
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.message, forIndexPath: indexPath) as RHCTodayCell
            let stationInfo = self.fetchedResultsController.objectAtIndexPath(indexPath) as CDStation
            let tmpplot: CDPlot? = stationInfo.lastRegisteredPlot()

            if let plot = tmpplot {
                let image = DrawArrow.drawArrowAtAngle(plot.windDir, forSpeed: plot.windAvg, highlighted: false, color: UIColor.whiteColor(), hightlightedColor: UIColor.blackColor())

                let raw = Datamanager.sharedManager().sharedDefaults!.integerForKey("selectedUnit")
                let unit = SpeedConvertion.fromRaw(raw)

                if let realUnit = unit {
                    let speed = plot.windAvg.speedConvertionTo(realUnit)
                    cell.speedLabel!.text = "\(speedFormatter.stringFromNumber(speed)) \(NSNumber.shortUnitNameString(realUnit))"
                }
                cell.arrowImageView!.image = image
                cell.updatedLabel!.text = dateTransformer.transformedValue(plot.plotTime) as? String
            } else {
                cell.speedLabel!.text = "—.—"
                cell.updatedLabel!.text = NSLocalizedString("Not updated", comment: "")
            }
            cell.nameLabel!.text = stationInfo.stationName
            return cell
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        let itemCount = (fetchedResultsController.fetchedObjects as Array!).count
        var size : CGFloat

        if !showingAll && indexPath.row == TableViewConstants.baseRowCount &&  itemCount != TableViewConstants.baseRowCount + 1 {
            size = CGFloat(TableViewConstants.todayRowHeight)
        } else {
            let font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
            size = (font.pointSize*2.0)+TableViewConstants.todayRowPadding
        }
        return max(CGFloat(TableViewConstants.todayRowHeight), size)
    }


    override func tableView(_: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
    {
        cell.layer.backgroundColor = UIColor.clearColor().CGColor

        let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect.notificationCenterVibrancyEffect())
        vibrancyView.frame = cell.contentView.bounds

        let view = UIView(frame: vibrancyView.bounds)
        view.backgroundColor = UIColor.lightGrayColor()
        vibrancyView.contentView.addSubview(view)
        cell.selectedBackgroundView = vibrancyView
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
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

        let stationInfo = self.fetchedResultsController.objectAtIndexPath(indexPath) as CDStation

        let url = NSURL.URLWithString("vindsiden://station/\(stationInfo.stationId)?todayView=1")
        extensionContext?.openURL(url, completionHandler:  nil)
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


    func controllerDidChangeContent(controller: NSFetchedResultsController!) {
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
        //_speedFormatter!.minimumSignificantDigits = 1
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
        let rowCount = showingAll ? itemCount : min(itemCount, TableViewConstants.baseRowCount + 1)
        let font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        var size = (font.pointSize*2)+TableViewConstants.todayRowPadding

        size = max(TableViewConstants.todayRowHeight, size)

        if !showingAll {
            return CGFloat(Double(rowCount-1) * Double(size)) + TableViewConstants.todayRowHeight
        } else {
            return CGFloat(Double(rowCount) * Double(size))
        }
    }
}
