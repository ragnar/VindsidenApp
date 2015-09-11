//
//  RHCRotatingNavigationController.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 03.09.15.
//  Copyright © 2015 RHC. All rights reserved.
//

import UIKit

class RHCRotatingNavigationController: UINavigationController {

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Landscape
    }


    override func shouldAutorotate() -> Bool {
        return true
    }


    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        return .LandscapeLeft
    }
}
