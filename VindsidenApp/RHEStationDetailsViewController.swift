//
//  RHEStationDetailsViewController.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 26/10/14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import UIKit
import VindsidenKit
import JTSImageViewController

@objc(RHEStationDetailsDelegate) protocol RHEStationDetailsDelegate {
    func rheStationDetailsViewControllerDidFinish( _ controller: RHEStationDetailsViewController )
}


@objc(RHEStationDetailsViewController) class RHEStationDetailsViewController: UITableViewController {
    @objc weak var delegate: RHEStationDetailsDelegate?
    @objc var station: CDStation?
    var buttons = [NSLocalizedString("Go to yr.no", comment: ""), NSLocalizedString("View in Maps", comment: "")]

    lazy var regexRemoveHTMLTags: NSRegularExpression? = {
            var _regexRemoveHTMLTags: NSRegularExpression?
            do {
                _regexRemoveHTMLTags = try NSRegularExpression(pattern: "(<[^>]+>)", options: .caseInsensitive)
            } catch _ {
                _regexRemoveHTMLTags = nil
            }
        return _regexRemoveHTMLTags
        }()



    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }


    deinit {
        NotificationCenter.default.removeObserver(self)
    }



    override func viewDidLoad() {
        super.viewDidLoad()

        if let current = station {
            self.navigationItem.title = current.stationName

            if let image = current.webCamImage, !image.isEmpty {
                buttons.append(NSLocalizedString("Show Camera", comment: ""))
            }
        }

        self.tableView.rowHeight = UITableView.automaticDimension

        NotificationCenter.default.addObserver(self, selector: #selector(RHEStationDetailsViewController.preferredContentSizeDidChange(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }


    @objc func preferredContentSizeDidChange( _ notification: Notification )
    {
        tableView.reloadData()
        tableView.beginUpdates()
        tableView.endUpdates()
    }


    // MARK: - TableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if 0 == section {
            return 6
        } else {
            return buttons.count
        }
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell :UITableViewCell

        if ( 0 == indexPath.section) {
            cell = tableView.dequeueReusableCell(withIdentifier: "StationDetailsCell", for: indexPath) as UITableViewCell
            configureCell(cell as! RHCDStationDetailsCell, atIndexPath: indexPath)
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath) as UITableViewCell
            cell.textLabel?.textColor = self.view.tintColor;
            cell.textLabel?.text = buttons[indexPath.row]
        }

        return cell
    }


    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        if indexPath.section == 0 {
            if let actual = cell as? RHCDStationDetailsCell {
                actual.headerLabel.font = UIFont.preferredFont(forTextStyle: (UIFont.TextStyle(rawValue: actual.headerLabel.font.fontDescriptor.object(forKey: UIFontDescriptor.AttributeName(rawValue: "NSCTFontUIUsageAttribute")) as! String)))
                actual.detailsLabel.font = UIFont.preferredFont(forTextStyle: (UIFont.TextStyle(rawValue: actual.detailsLabel.font.fontDescriptor.object(forKey: UIFontDescriptor.AttributeName(rawValue: "NSCTFontUIUsageAttribute")) as! String)))
            }
        }
    }


    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StationDetailsCell") as! RHCDStationDetailsCell
            configureCell(cell, atIndexPath: indexPath)
            return cell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        }

        return UITableView.automaticDimension
    }


    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return (indexPath.section == 1)
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
        tableView.deselectRow(at: indexPath, animated: true)
    }


    // MARK: -

    func configureCell( _ cell: RHCDStationDetailsCell, atIndexPath indexPath:IndexPath) -> Void {
        cell.headerLabel.textColor = self.view.tintColor;
        cell.detailsLabel.preferredMaxLayoutWidth = view.bounds.width - 30.0
        cell.detailsLabel.text = ""

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
                if let stationText = current.stationText {
                    cell.detailsLabel.text = regexRemoveHTMLTags?.stringByReplacingMatches(in: stationText, options: [], range: NSMakeRange(0, stationText.utf16.count), withTemplate: "").replacingOccurrences(of: "\n", with: "")
                }
            case 4:
                cell.headerLabel.text = NSLocalizedString("Status", comment: "")
                if let statusMessage = current.statusMessage {
                    cell.detailsLabel.text = regexRemoveHTMLTags?.stringByReplacingMatches(in: statusMessage, options: [], range: NSMakeRange(0, statusMessage.utf16.count), withTemplate: "").replacingOccurrences(of: "\n", with: "")
                }
            case 5:
                cell.headerLabel.text = NSLocalizedString("Camera", comment: "")
                if let webCamText = current.webCamText {
                    cell.detailsLabel.text = regexRemoveHTMLTags?.stringByReplacingMatches(in: webCamText, options: [], range: NSMakeRange(0, webCamText.utf16.count), withTemplate: "").replacingOccurrences(of: "\n", with: "")
                }
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


    @IBAction func done( _ sender: AnyObject?) {
        delegate?.rheStationDetailsViewControllerDidFinish(self)
    }

    @IBAction func gotoYR( _ sender: AnyObject? ) {

        if let current = station {
            if let unwrapped = current.yrURL, let yrurl = unwrapped.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                let url = URL(string: yrurl)
                UIApplication.shared.open(url!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }
        }
    }


    @IBAction func showMap( _ sender: AnyObject? ) {

        if let current = station {
            let spotCord = current.coordinate

            var query = "http://maps.apple.com/?t=h&z=10"

            if spotCord.latitude > 0 || spotCord.longitude > 0 {
                query += "&ll=\(spotCord.latitude),\(spotCord.longitude)"
            }

            if let city = current.city, !city.isEmpty {
                query += "&q=\(city)"
            } else if let stationName = current.stationName {
                query += "&q=\(stationName)"
            }

            if let mapurl = query.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                let url = URL(string: mapurl)
                UIApplication.shared.open(url!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }
        }
    }


    @IBAction func showCamera( _ sender: AnyObject? ) {
        if let current = station {
            let imageInfo = JTSImageInfo()

            guard let webCamImage = current.webCamImage else {
                return;
            }

            imageInfo.imageURL = URL(string: webCamImage)

            if let view = sender as? UIView {
                imageInfo.referenceRect = view.frame
            }

            imageInfo.referenceView = self.view

            let controller = JTSImageViewController(imageInfo: imageInfo, mode: JTSImageViewControllerMode.image, backgroundStyle: [.blurred, .scaled])
            controller?.show(from: self, transition: .fromOriginalPosition)
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
