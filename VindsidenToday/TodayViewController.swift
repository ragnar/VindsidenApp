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

        DataManager.shared.cleanupPlots()

        extensionContext?.widgetLargestAvailableDisplayMode = .expanded

        tableView.tableFooterView = UIView()

        resetContentSize()
        tableView.reloadData()
        updateContentWithCompletionHandler()
    }


    // MARK: - NotificationCenter


    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        DLOG("")
        completionHandler(.newData)
        updateContentWithCompletionHandler(completionHandler)
    }


    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
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


    override func numberOfSections(in tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }

        return 0
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let sectionInfo = sections[section]

            if extensionContext?.widgetActiveDisplayMode == .compact {
                return min(sectionInfo.numberOfObjects, 2)
            }
            return sectionInfo.numberOfObjects
        }

        return 0
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TableViewConstants.CellIdentifiers.message, for: indexPath) as! RHCTodayCell
        let stationInfo = self.fetchedResultsController.object(at: indexPath) as! CDStation

        if let plot = stationInfo.lastRegisteredPlot() {

            let winddir = CGFloat(plot.windDir!.floatValue)
            let windspeed = CGFloat(plot.windAvg!.floatValue)
            let image = DrawArrow.drawArrow( atAngle: winddir, forSpeed:windspeed, highlighted:false, color: UIColor.vindsidenTodayTextColor(), hightlightedColor: UIColor.black)

            let raw = AppConfig.sharedConfiguration.applicationUserDefaults.integer(forKey: "selectedUnit")
            let unit = SpeedConvertion(rawValue: raw)

            if let realUnit = unit {
                let speed = plot.windAvg!.speedConvertion(to: realUnit)
                if let speedString = speedFormatter.string(from: NSNumber(value: Float(speed))) {
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
            cell.updatedLabel.text = NSLocalizedString("LABEL_NOT_UPDATED", tableName: nil, bundle: Bundle.main, value: "LABEL_NOT_UPDATED", comment: "Not updated")
        }
        cell.nameLabel.text = stationInfo.stationName
        return cell
    }


    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return infoCellHeight()
    }


    override func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.layer.backgroundColor = UIColor.clear.cgColor
        cell.configureSelectedBackgroundView()
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let stationInfo = self.fetchedResultsController.object(at: indexPath) as! CDStation

        let url = URL(string: "vindsiden://station/\(stationInfo.stationId!)?todayView=1")
        if let actual = url {
            extensionContext?.open( actual, completionHandler:  nil)
        }
    }


    // MARK: - NSFetchedResultsController


    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> {
        if let actual = _fetchedResultsController {
            return actual
        }

        let fetchRequest = CDStation.fetchRequest()
        fetchRequest.fetchBatchSize = 3
        fetchRequest.predicate = NSPredicate(format: "isHidden = NO", argumentArray: nil)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]

        _fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataManager.shared.viewContext(), sectionNameKeyPath: nil, cacheName: nil)
        _fetchedResultsController!.delegate = self

        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            NSLog("Fetching stations failed")
            abort()
        }

        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? = nil


    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if tableView.isEditing == false {
            tableView.reloadData()
        }
    }


    // MARK: -


    lazy var speedFormatter : NumberFormatter = {
        let _speedFormatter = NumberFormatter()
        _speedFormatter.numberStyle = NumberFormatter.Style.decimal
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
        return self.tableView.dequeueReusableCell(withIdentifier: TableViewConstants.CellIdentifiers.message) as! RHCTodayCell
    }()


    // MARK: - Fetch


    func updateContentWithCompletionHandler(_ completionHandler: ((NCUpdateResult) -> Void)? = nil) {
        DLOG("Updating content")
        WindManager.sharedManager.fetch { (fetchResult: UIBackgroundFetchResult) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadData()
                completionHandler?(.newData)
                return
            })
        }

        //_fetchedResultsController = nil
    }
}
