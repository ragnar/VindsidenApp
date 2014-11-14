//
//  UIColor+AppColors.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 03/11/14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import Foundation

func RGBCOLOR( red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) -> UIColor {
    return UIColor(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: alpha)
}

public extension UIColor
{
    class func vindsidenGloablTintColor() -> UIColor {
        return RGBCOLOR( 227.0, 60.0, 13.0)
    }
}