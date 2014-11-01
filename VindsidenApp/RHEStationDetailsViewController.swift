//
//  RHEStationDetailsViewController.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 26/10/14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import UIKit
import VindsidenKit

@objc(RHEStationDetailsDelegate) protocol RHEStationDetailsDelegate {
    func rheStationDetailsViewControllerDidFinish( controller: RHEStationDetailsViewController )
}


@objc(RHEStationDetailsViewController) class RHEStationDetailsViewController: UITableViewController {
    weak var delegate: RHEStationDetailsDelegate?
    var station: CDStation?
    var buttons = [NSLocalizedString("Go to yr.no", comment: ""), NSLocalizedString("View in Maps", comment: "")]

    lazy var regexRemoveHTMLTags: NSRegularExpression? = {
        var _regexRemoveHTMLTags = NSRegularExpression(pattern: "(<[^>]+>)", options: .CaseInsensitive, error: nil)
        return _regexRemoveHTMLTags
        }()



    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }


    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }



    override func viewDidLoad() {
        super.viewDidLoad()

        if let current = station {
            self.navigationItem.title = current.stationName
            if !current.webCamImage.isEmpty {
                buttons.append(NSLocalizedString("Show Camera", comment: ""))
            }
        }

        self.tableView.rowHeight = UITableViewAutomaticDimension

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("preferredContentSizeDidChange:"), name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }


    func preferredContentSizeDidChange( notification: NSNotification )
    {
        tableView.reloadData()
        tableView.beginUpdates()
        tableView.endUpdates()
    }


    // MARK: - TableView

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }


    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if 0 == section {
            return 6
        } else {
            return buttons.count
        }
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell :UITableViewCell

        if ( 0 == indexPath.section) {
            cell = tableView.dequeueReusableCellWithIdentifier("StationDetailsCell", forIndexPath: indexPath) as UITableViewCell
            configureCell(cell as RHCDStationDetailsCell, atIndexPath: indexPath)
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier("ButtonCell", forIndexPath: indexPath) as UITableViewCell
            cell.textLabel.textColor = self.view.tintColor;
            cell.textLabel.text = buttons[indexPath.row]
        }

        return cell
    }


    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if indexPath.section == 0 {
            if let actual = cell as? RHCDStationDetailsCell {
                actual.headerLabel.font = UIFont.preferredFontForTextStyle((actual.headerLabel.font.fontDescriptor().objectForKey("NSCTFontUIUsageAttribute") as String))
                actual.detailsLabel.font = UIFont.preferredFontForTextStyle((actual.detailsLabel.font.fontDescriptor().objectForKey("NSCTFontUIUsageAttribute") as String))
            }
        }
    }


    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("StationDetailsCell") as RHCDStationDetailsCell
            configureCell(cell, atIndexPath: indexPath)
            return cell.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
        }

        return UITableViewAutomaticDimension
    }


    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return (indexPath.section == 1)
    }


    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 1 {
                self.showMap(nil)
            }
        } else {
            switch (indexPath.row ) {
            case 0: gotoYR(nil)
            case 1: showMap(nil)
            default: showCamera(nil)
            }
        }
    }


    // MARK: -

    func configureCell( cell: RHCDStationDetailsCell, atIndexPath indexPath:NSIndexPath) -> Void {
        cell.headerLabel.textColor = self.view.tintColor;
        cell.detailsLabel.preferredMaxLayoutWidth = CGRectGetWidth(view.bounds) - 30.0

        if let current = station {
            switch ( indexPath.row )
            {
            case 0:
                cell.headerLabel.text = NSLocalizedString("Name", comment: "")
                cell.detailsLabel.text = current.stationName
            case 1:
                cell.headerLabel.text = NSLocalizedString("Place", comment: "")
                cell.detailsLabel.text = current.city
            case 2:
                cell.headerLabel.text = NSLocalizedString("Copyright", comment: "")
                cell.detailsLabel.text = current.copyright
            case 3:
                cell.headerLabel.text = NSLocalizedString("Info", comment: "")
                cell.detailsLabel.text = regexRemoveHTMLTags?.stringByReplacingMatchesInString(current.stationText, options: .allZeros, range: NSMakeRange(0, current.stationText.utf16Count), withTemplate: "").stringByReplacingOccurrencesOfString("\n", withString: "")
            case 4:
                cell.headerLabel.text = NSLocalizedString("Status", comment: "")
                cell.detailsLabel.text = regexRemoveHTMLTags?.stringByReplacingMatchesInString(current.statusMessage, options: .allZeros, range: NSMakeRange(0, current.statusMessage.utf16Count), withTemplate: "").stringByReplacingOccurrencesOfString("\n", withString: "")
            case 5:
                cell.headerLabel.text = NSLocalizedString("Camera", comment: "")
                cell.detailsLabel.text = regexRemoveHTMLTags?.stringByReplacingMatchesInString(current.webCamText, options: .allZeros, range: NSMakeRange(0, current.webCamText.utf16Count), withTemplate: "").stringByReplacingOccurrencesOfString("\n", withString: "")
            default:
                cell.headerLabel.text = NSLocalizedString("Unknown", comment: "")
            }

            if let text = cell.detailsLabel.text {
                if text.isEmpty {
                    cell.detailsLabel.text = " "
                }
            } else {
                cell.detailsLabel.text = " "
            }
        }
    }


    // MARK: - Actions


    @IBAction func done( sender: AnyObject?) {
        delegate?.rheStationDetailsViewControllerDidFinish(self)
    }

    @IBAction func gotoYR( sender: AnyObject? ) {

        if let current = station {
            if let yrurl = current.yrURL.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding) {
                let url = NSURL(string: yrurl)
                UIApplication.sharedApplication().openURL(url!)
            }
        }
    }


    @IBAction func showMap( sender: AnyObject? ) {

        if let current = station {
            let spotCord = CLLocationCoordinate2D(latitude: current.coordinateLat as CLLocationDegrees, longitude: current.coordinateLon as CLLocationDegrees)

            var query = "http://maps.apple.com/?t=h&z=10"

            if spotCord.latitude > 0 || spotCord.longitude > 0 {
                query += "&ll=\(spotCord.latitude),\(spotCord.longitude)"
            }

            if !current.city.isEmpty {
                query += "&q=\(current.city)"
            } else {
                query += "&q=\(current.stationName)"
            }

            if let mapurl = query.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding) {
                let url = NSURL(string: mapurl)
                UIApplication.sharedApplication().openURL(url!)
            }
        }
    }


    @IBAction func showCamera( sender: AnyObject? ) {
        if let current = station {
            let imageInfo = JTSImageInfo()
            imageInfo.imageURL = NSURL(string: current.webCamImage)

            if let view = sender as? UIView {
                imageInfo.referenceRect = view.frame
            }

            imageInfo.referenceView = self.view

            let controller = JTSImageViewController(imageInfo: imageInfo, mode: .Image, backgroundStyle: ._ScaledDimmedBlurred)
            controller.showFromViewController(self, transition: ._FromOriginalPosition)
        }
        
    }
}
