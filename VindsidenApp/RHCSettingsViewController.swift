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
    func rhcSettingsDidFinish( _ controller : RHCSettingsViewController) -> Void
}



@objc class RHCSettingsViewController: UITableViewController {

    @objc var delegate: RHCSettingsDelegate?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as UITableViewCell

        if indexPath.row == 0 {
            cell.textLabel?.text = NSLocalizedString("Stations", comment: "")
            cell.detailTextLabel?.text = "\(CDStation.numberOfVisibleStationsInManagedObjectContext(DataManager.shared.viewContext()))"
        } else {
            let unit = SpeedConvertion(rawValue: AppConfig.sharedConfiguration.applicationUserDefaults.integer(forKey: "selectedUnit"))

            cell.textLabel?.text = NSLocalizedString("Units", comment: "")
            cell.detailTextLabel?.text = NSNumber.shortUnitNameString(unit!)
        }

        return cell
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            performSegue(withIdentifier: "ShowStationPicker", sender: self)
        } else {
            performSegue(withIdentifier: "ShowUnitSelector", sender: self)
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let tv = UITextView(frame: CGRect.zero)

        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let appBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        let version = NSString(format: NSLocalizedString("%@ version %@.%@", comment: "Version string in settings view") as NSString, appName, appVersion, appBuild)
        tv.text = NSLocalizedString("LABEL_PERMIT", comment: "Værdata hentet med tillatelse fra\nhttp://vindsiden.no\n\n") + (version as String)

        tv.isEditable = false
        tv.textAlignment = .center
        tv.backgroundColor = UIColor.clear
        tv.dataDetectorTypes = .link
        tv.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
        tv.textColor = UIColor(red: 0.298039, green:0.337255, blue:0.423529, alpha:1.0)
        tv.layer.shadowColor = UIColor.white.cgColor
        tv.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        tv.layer.shadowOpacity = 1.0
        tv.layer.shadowRadius = 1.0
        tv.sizeToFit()
        return tv
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let tv = self.tableView(tableView, viewForFooterInSection: section)

        let height = tv?.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        return height!
    }

    //MARK: - Actions


    @IBAction func done( _ sender: AnyObject ) {

        if let delegate = self.delegate {
            delegate.rhcSettingsDidFinish(self)
        } else {
            self.dismiss( animated: true, completion: nil)
        }
    }
}
