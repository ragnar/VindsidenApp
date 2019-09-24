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
        NotificationCenter.default.removeObserver(self)
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(RHCUnitSelectorViewController.preferredContentSizeDidChange(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }


    @objc func preferredContentSizeDidChange( _ notification: Notification )
    {
        tableView.reloadData()
    }

    // MARK: TableView

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 5
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UnitCell", for: indexPath) as UITableViewCell

        let unit = SpeedConvertion(rawValue: indexPath.row+1)
        cell.textLabel?.text = NSNumber.longUnitNameString(unit!)

        if AppConfig.sharedConfiguration.applicationUserDefaults.integer(forKey: "selectedUnit") == indexPath.row+1 {
            cell.accessoryType = .checkmark;
        } else {
            cell.accessoryType = .none;
        }
        
        return cell;
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: (UIFont.TextStyle(rawValue: cell.textLabel?.font.fontDescriptor.object(forKey: UIFontDescriptor.AttributeName(rawValue: "NSCTFontUIUsageAttribute")) as! String)))
    }


    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return NSLocalizedString("Choose unit", tableName: nil, bundle: Bundle.main, value: "Choose unit", comment: "Choose unit")
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        AppConfig.sharedConfiguration.applicationUserDefaults.set(indexPath.row+1, forKey: "selectedUnit")
        AppConfig.sharedConfiguration.applicationUserDefaults.synchronize()
        tableView.reloadData()
    }
}
