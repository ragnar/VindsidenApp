//
//  RHCRotatingNavigationController.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 03.09.15.
//  Copyright © 2015 RHC. All rights reserved.
//

import UIKit

class RHCRotatingNavigationController: UINavigationController {

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .landscape
    }


    override var shouldAutorotate : Bool {
        return true
    }


    override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
        return .landscapeLeft
    }
}
