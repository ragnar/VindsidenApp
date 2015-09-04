//
//  RHCNavigationViewController.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 18/09/14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import UIKit


@objc(RHCNavigationViewController)
class RHCNavigationViewController : UINavigationController
{

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Portrait
    }


    override func shouldAutorotate() -> Bool {
        return false
    }


    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        return .Portrait
    }
}
