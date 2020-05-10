//
//  RHCLandscapeGraphViewController.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 21/09/14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import UIKit
import VindsidenKit


@objc(RHCLandscapeGraphViewController)
class RHCLandscapeGraphViewController: UIViewController
{
    @IBOutlet weak var graphView: RHEGraphView?
    @IBOutlet weak var stationName: UILabel?

    @objc var station: CDStation?
    @objc var plots: [CDPlot]?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        graphView?.copyright = station?.copyright
        graphView?.plots = plots
        stationName?.text = station?.stationName
    }

}
