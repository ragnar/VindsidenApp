//
//  RHCUnitSelectorViewController.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 07/09/14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import UIKit
import VindsidenKit


class RHCUnitSelectorViewController : UITableViewController
{


    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("preferredContentSizeDidChange:"), name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }


    func preferredContentSizeDidChange( notification: NSNotification )
    {
        tableView.reloadData()
    }

    // MARK: TableView

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 5
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("UnitCell", forIndexPath: indexPath) as UITableViewCell

        let unit = SpeedConvertion(rawValue: indexPath.row+1)
        cell.textLabel.text = NSNumber.longUnitNameString(unit!)

        if Datamanager.sharedManager().sharedDefaults.integerForKey("selectedUnit") == indexPath.row+1 {
            cell.accessoryType = .Checkmark;
        } else {
            cell.accessoryType = .None;
        }
        
        return cell;
    }

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
    {
        cell.textLabel.font = UIFont.preferredFontForTextStyle((cell.textLabel.font.fontDescriptor().objectForKey("NSCTFontUIUsageAttribute") as String))
    }


    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return NSLocalizedString("Choose unit", tableName: nil, bundle: NSBundle.mainBundle(), value: "Choose unit", comment: "Choose unit")
    }


    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        Datamanager.sharedManager().sharedDefaults.setInteger(indexPath.row+1, forKey: "selectedUnit")
        Datamanager.sharedManager().sharedDefaults.synchronize()
        tableView.reloadData()
    }
}
