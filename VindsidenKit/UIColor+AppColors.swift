//
//  UIColor+AppColors.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 03/11/14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import Foundation

func RGBCOLOR( _ red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) -> UIColor {
    return UIColor(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: alpha)
}

public extension UIColor
{
    class func vindsidenMinColor() -> UIColor {
        return RGBCOLOR( 208.0, green: 221.0, blue: 0.0)
    }

    class func vindsidenAvgColor() -> UIColor {
        return RGBCOLOR( 58.0, green: 217.0, blue: 255.0)
    }

    class func vindsidenMaxColor() -> UIColor {
        return RGBCOLOR( 255.0, green: 73.0, blue: 62.0)
    }
}
