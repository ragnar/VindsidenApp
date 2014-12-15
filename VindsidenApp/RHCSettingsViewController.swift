//
//  RHCSettingsViewController.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 15/10/14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import UIKit
import VindsidenKit

@objc(RHCSettingsDelegate) protocol RHCSettingsDelegate {
    func rhcSettingsDidFinish( controller : RHCSettingsViewController) -> Void
}



@objc class RHCSettingsViewController: UITableViewController {

    var delegate: RHCSettingsDelegate?

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("SettingsCell", forIndexPath: indexPath) as UITableViewCell

        if indexPath.row == 0 {
            cell.textLabel?.text = NSLocalizedString("Stations", comment: "")
            cell.detailTextLabel?.text = "\(CDStation.numberOfVisibleStations())"
        } else {
            let unit = SpeedConvertion(rawValue: Datamanager.sharedManager().sharedDefaults.integerForKey("selectedUnit"))

            cell.textLabel?.text = NSLocalizedString("Units", comment: "")
            cell.detailTextLabel?.text = NSNumber.shortUnitNameString(unit!)
        }

        return cell
    }


    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            performSegueWithIdentifier("ShowStationPicker", sender: self)
        } else {
            performSegueWithIdentifier("ShowUnitSelector", sender: self)
        }
    }

    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let tv = UITextView(frame: CGRectZero)

        let appName = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleDisplayName") as String
        let appVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as String
        let appBuild = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as String
        var version = NSString(format: NSLocalizedString("%@ version %@.%@", comment: "Version string in settings view"), appName, appVersion, appBuild)
        tv.text = NSLocalizedString("LABEL_PERMIT", comment: "Værdata hentet med tillatelse fra\nhttp://vindsiden.no\n\n").stringByAppendingString(version)

        tv.editable = false
        tv.textAlignment = .Center
        tv.backgroundColor = UIColor.clearColor()
        tv.dataDetectorTypes = .Link
        tv.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        tv.textColor = UIColor(red: 0.298039, green:0.337255, blue:0.423529, alpha:1.0)
        tv.layer.shadowColor = UIColor.whiteColor().CGColor
        tv.layer.shadowOffset = CGSizeMake(0.0, 1.0)
        tv.layer.shadowOpacity = 1.0
        tv.layer.shadowRadius = 1.0
        tv.sizeToFit()
        return tv
    }

    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let tv = self.tableView(tableView, viewForFooterInSection: section)

        let height = tv?.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
        return height!
    }

    //MARK: - Actions


    @IBAction func done( sender: AnyObject ) {

        if let delegate = self.delegate {
            delegate.rhcSettingsDidFinish(self)
        } else {
            self.dismissViewControllerAnimated( true, completion: nil)
        }
    }
}
