//
//  UIImage+Graph.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 12.05.15.
//  Copyright (c) 2015 RHC. All rights reserved.
//

import Foundation


public final class GraphImage {
    struct GraphBounds {
        var minX: CGFloat
        var minY: CGFloat
        var maxX: CGFloat
        var maxY: CGFloat
        var width: CGFloat {
            get {
                return maxX-minX
            }
        }
        var height: CGFloat {
            get {
                return maxY-minY
            }
        }
    }


    let size: CGSize
    let stepX: CGFloat
    let totalMinutes: NSTimeInterval
    let scale: CGFloat

    let earliestDate: NSDate
    let absoluteStartDate: NSDate
    let absoluteEndDate: NSDate
    let bounds: GraphBounds

    var plots = [CDPlot]()

    lazy var speedFormatter : NSNumberFormatter = {
        let _speedFormatter = NSNumberFormatter()
        _speedFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        _speedFormatter.maximumFractionDigits = 1
        _speedFormatter.minimumFractionDigits = 1
        _speedFormatter.notANumberSymbol = "—.—"
        _speedFormatter.nilSymbol = "—.—"

        return _speedFormatter
        }()


    public init( size:CGSize, scale: CGFloat, plots: [CDPlot] = [CDPlot]() ) {
        self.size = size
        self.scale = scale
        self.plots = plots

        bounds = GraphBounds(minX: 20.0, minY: 20.0, maxX: size.width-6.0, maxY: size.height-30.0)

        let earliestDate: NSDate
        let latestDate: NSDate

        if plots.count > 0 {
            earliestDate = plots.last?.valueForKeyPath("plotTime") as! NSDate
            latestDate = (plots.first?.valueForKeyPath("plotTime") as! NSDate).dateByAddingTimeInterval(3600)
        } else {
            earliestDate = NSDate()
            latestDate = NSDate()
        }

        self.earliestDate = earliestDate
        absoluteStartDate = GraphImage.absoluteDate(earliestDate, isStart: true)!
        absoluteEndDate = GraphImage.absoluteDate(latestDate, isStart: false)!
        totalMinutes = self.absoluteEndDate.timeIntervalSinceDate(self.absoluteStartDate)/60.0

        stepX = bounds.width/CGFloat(totalMinutes)
    }


    public func drawImage() -> UIImage {

        UIGraphicsBeginImageContextWithOptions( size, false, scale)
        let context = UIGraphicsGetCurrentContext()

        drawSpeedLines(context)
        drawHourLines(context)
        drawGrid(context)
        drawHourText(context)
        drawSpeedText(context)
        drawGraphLines(context)
        drawWindArrows(context)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }


    final func drawGrid( context: CGContext! ) -> Void {
        CGContextSaveGState(context)
        CGContextBeginPath(context)

        UIColor.whiteColor().set()
        CGContextSetAllowsAntialiasing( context, false)
        CGContextSetLineWidth( context, 1.0/scale)


        CGContextMoveToPoint( context, bounds.minX, bounds.maxY)
        CGContextAddLineToPoint( context, bounds.maxX, bounds.maxY)

        CGContextMoveToPoint( context, bounds.minX, bounds.minY-5.0)
        CGContextAddLineToPoint( context, bounds.minX, bounds.maxY)

        CGContextDrawPath( context, kCGPathStroke)

        CGContextRestoreGState(context)
    }


    final func drawSpeedLines( context: CGContext! ) -> Void {
        CGContextSaveGState(context);

        let plotMaxValue = self.plotMaxValue()
        var totSteps = min(5, plotMaxValue)
        totSteps = max( 5, totSteps)
        let plotStep = bounds.height/totSteps

        CGContextSetAllowsAntialiasing( context, false)
        CGContextSetLineWidth( context, 1.0/scale)
        UIColor.whiteColor().set()

        CGContextBeginPath(context)

        for ( var y = bounds.maxY; y >= bounds.minY; y=ceil(y-plotStep)) {
            CGContextMoveToPoint( context, bounds.minX - (2.0/scale), y)
            CGContextAddLineToPoint( context, bounds.minX, y)
        }

        CGContextClosePath(context)
        CGContextDrawPath( context, kCGPathStroke)

        CGContextBeginPath(context)

        for ( var y = ceil(bounds.maxY-plotStep); y >= bounds.minY; y=ceil(y-plotStep)) {
            CGContextMoveToPoint( context, bounds.minX, y)
            CGContextAddLineToPoint( context, bounds.maxX, y)
        }

        UIColor.lightGrayColor().set()

        let lengths = [2.0, 3.0] as [CGFloat]
        CGContextSetLineDash( context, 0.0, lengths, 2)
        CGContextDrawPath( context, kCGPathStroke)

        CGContextRestoreGState(context)
    }


    final func drawHourLines( context: CGContext! ) -> Void {
        CGContextSaveGState(context);
        CGContextSetLineWidth( context, 1.0/scale);
        CGContextSetAllowsAntialiasing( context, false);
        CGContextBeginPath(context);
        UIColor.whiteColor().set()

        let hours = self.hours()

        for ( var i = 0.0; i <= hours; i+=0.25 ) {
            let lineLength = CGFloat( 0 == fmod(i, 1) ? (4.0/scale) : (2.0/scale))
            let x = CGFloat(ceil(Double(bounds.minX) + (i*(Double(bounds.width)/hours))))

            CGContextMoveToPoint( context, x, bounds.maxY)
            CGContextAddLineToPoint( context, x, bounds.maxY+lineLength)
        }

        CGContextClosePath(context)
        CGContextDrawPath( context, kCGPathStroke)
        CGContextRestoreGState(context)
    }


    final func drawHourText( context: CGContext! ) {
        CGContextSaveGState(context);
        CGContextSetAllowsAntialiasing( context, true);

        let hours = self.hours()
        let drawAttr = [
            NSFontAttributeName : UIFont.systemFontOfSize(12.0/scale),
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]

        for ( var i = 0.0; i <= hours; i++ ) {
            let x = CGFloat(ceil(Double(bounds.minX) + (i*(Double(bounds.width)/hours))))
            let hs = String(format: "%02ld", hourComponentForDate(self.earliestDate.dateByAddingTimeInterval((3600*i)))) as NSString
            let labelBounds = hs.boundingRectWithSize(CGSizeMake( 40.0, 21.0), options: .UsesLineFragmentOrigin, attributes: drawAttr, context: nil)
            let point = CGPointMake( x-ceil(CGRectGetWidth(labelBounds)/2), bounds.maxY+(6.0/scale))

            hs.drawAtPoint(point, withAttributes: drawAttr)
        }

        CGContextRestoreGState(context)
    }


    func drawSpeedText( context: CGContext! ) {
        CGContextSaveGState(context);
        CGContextSetAllowsAntialiasing( context, true)

        let raw = AppConfig.sharedConfiguration.applicationUserDefaults.integerForKey("selectedUnit")
        let unit = SpeedConvertion(rawValue: raw)!

        let plotMaxValue = ceil(((plots as NSArray).valueForKeyPath("@max.windMax") as! NSNumber).speedConvertionTo(unit)+1)
        var totSteps = min(5, plotMaxValue)
        totSteps = max( 5, totSteps)
        let plotStep = bounds.height/totSteps

        var drawAttr = [
            NSFontAttributeName : UIFont.systemFontOfSize(12.0/scale),
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]

        var labelBounds = CGRectZero

        var i: CGFloat = 0.0
        for ( var y = bounds.maxY; y >= bounds.minY; y=ceil(y-plotStep)) {
            if let hs = speedFormatter.stringFromNumber(i*(plotMaxValue/totSteps)) {
                labelBounds = hs.boundingRectWithSize(CGSizeMake( 40.0, 21.0), options: .UsesLineFragmentOrigin, attributes: drawAttr, context: nil)
                let point = CGPointMake( ceil(bounds.minX-CGRectGetWidth(labelBounds)-5), ceil(y-(CGRectGetHeight(labelBounds)/2)-(2/scale)) )
                hs.drawAtPoint( point, withAttributes: drawAttr)
            }
            i++;
        }

        let unitString = NSNumber.shortUnitNameString(unit)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .Left

        drawAttr = [
            NSFontAttributeName : UIFont.boldSystemFontOfSize(12.0/scale),
            NSForegroundColorAttributeName : UIColor.whiteColor(),
            NSParagraphStyleAttributeName : paragraphStyle
        ]

        labelBounds = unitString.boundingRectWithSize(CGSizeMake( 40.0, 21.0), options: .UsesLineFragmentOrigin, attributes: drawAttr, context: nil)
        labelBounds.origin.x = bounds.minX
        labelBounds.origin.y = bounds.minY - 18.0
        unitString.drawInRect( labelBounds, withAttributes:drawAttr)

        CGContextRestoreGState(context);
    }


    func drawGraphLines( context: CGContext!) {
        CGContextSaveGState(context)
        CGContextSetAllowsAntialiasing( context, true)
        CGContextBeginPath(context)
        //CGContextSetShadowWithColor( context, CGSizeMake(0.0, 2.0), 2.0, UIColor(white: 0.0, alpha: 0.35).CGColor)

        let raw = AppConfig.sharedConfiguration.applicationUserDefaults.integerForKey("selectedUnit")
        let unit = SpeedConvertion(rawValue: raw)!

        let firstPlot = plots.first!
        var minPoints = [CGPoint]()
        var avgPoints = [CGPoint]()
        var maxPoints = [CGPoint]()

        let plotMaxValue = self.plotMaxValue()
        let interval = CGFloat(firstPlot.plotTime.timeIntervalSinceDate(self.absoluteStartDate)/60.0)
        var x = ceil(bounds.minX + (interval*self.stepX))


        for (idx, plot) in plots.enumerate() {
            if idx > 0 {
                let interval = CGFloat(plot.plotTime.timeIntervalSinceDate(self.absoluteStartDate)/60.0)
                x = ceil(bounds.minX + (interval*self.stepX))
            }

            let rMax = plot.windMax.speedConvertionTo(unit)
            let yMax = bounds.maxY - (rMax / plotMaxValue) * bounds.height
            maxPoints.append(CGPointMake(x, yMax))

            let rMin = plot.windMin.speedConvertionTo(unit)
            let yMin = bounds.maxY - (rMin / plotMaxValue) * bounds.height
            minPoints.append(CGPointMake(x, yMin))

            let rAvg = plot.windAvg.speedConvertionTo(unit)
            let yAvg = bounds.maxY - (rAvg / plotMaxValue) * bounds.height
            avgPoints.append(CGPointMake(x, yAvg))
        }

        UIColor.vindsidenMinColor().set()

        let minBezier = self.bezierPathWithPoints(minPoints)
        minBezier.stroke()

        UIColor.vindsidenAvgColor().set()

        let avgBezier = self.bezierPathWithPoints(avgPoints)
        avgBezier.stroke()

        UIColor.vindsidenMaxColor().set()

        let maxBezier = self.bezierPathWithPoints(maxPoints)
        maxBezier.stroke()

        CGContextRestoreGState(context);
    }


    func drawWindArrows( context: CGContext!) {
        CGContextSaveGState(context)

        let firstPlot = plots.first!
        let interval = CGFloat(firstPlot.plotTime.timeIntervalSinceDate(self.absoluteStartDate)/60.0)
        var x = ceil(bounds.minX + (interval*self.stepX))

        for plot in plots {
            let interval = CGFloat(plot.plotTime.timeIntervalSinceDate(self.absoluteStartDate)/60.0)
            x = ceil(bounds.minX + (interval*self.stepX))

            let winddir = CGFloat(plot.windDir.floatValue)
            let windspeed = CGFloat(plot.windAvg.floatValue)
            let image = DrawArrow.drawArrowAtAngle( winddir, forSpeed:windspeed, highlighted:false, color: UIColor.whiteColor(), hightlightedColor: UIColor.blackColor())

            image.drawInRect(CGRectMake(x-8.0, bounds.maxY+10, 16.0, 16.0))
        }

        CGContextRestoreGState(context);
    }


    // MARK: -


    func bezierPathWithPoints( points: [CGPoint] ) -> UIBezierPath {
        let bezierPath = self.quadCurvedPathWithPoints(points)
        bezierPath.lineJoinStyle = kCGLineJoinRound
        bezierPath.lineCapStyle = kCGLineCapRound
        bezierPath.lineWidth = 2.0/scale

        return bezierPath
    }


    final func quadCurvedPathWithPoints( points:[CGPoint]) -> UIBezierPath {
        let path = UIBezierPath()

        if points.count > 0 {

            var p1 = points.first!
            path.moveToPoint(p1)

            if points.count == 2 {
                path.addLineToPoint(points.last!)
            } else {
                for( var i = 1; i < points.count; i++ ) {
                    let p2 = points[i]
                    let midPoint = midPointForPoints(p1, p2)

                    path.addQuadCurveToPoint(midPoint, controlPoint: p1)
                    path.addQuadCurveToPoint(p2, controlPoint: controlPointForPoints(midPoint, p2))

                    p1 = p2
                }
            }
        }
        return path
    }


    final func midPointForPoints( p1:CGPoint, _ p2:CGPoint) -> CGPoint {
        return CGPointMake((p1.x + p2.x) / 2, (p1.y + p2.y) / 2)
    }


    final func controlPointForPoints( p1:CGPoint, _ p2:CGPoint) -> CGPoint {
        var controlPoint = midPointForPoints(p1, p2)
        let diffY = fabs(p2.y - controlPoint.y)

        if p1.y < p2.y {
            controlPoint.y += diffY
        } else if p1.y > p2.y {
            controlPoint.y -= diffY
        }
        
        return controlPoint
    }


    final func hourComponentForDate( date:NSDate) -> Int {
        let gregorian = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        let hourComponents = gregorian.components(.Hour, fromDate: date)
        return hourComponents.hour
    }


    final func hours() -> Double {
        return Double(Int(self.absoluteEndDate.timeIntervalSinceDate(self.absoluteStartDate)/3600))
    }


    func plotMaxValue() -> CGFloat {
        let raw = AppConfig.sharedConfiguration.applicationUserDefaults.integerForKey("selectedUnit")
        let unit = SpeedConvertion(rawValue: raw)!
        let plotMaxValue = ceil(((plots as NSArray).valueForKeyPath("@max.windMax") as! NSNumber).speedConvertionTo(unit)+1)

        return plotMaxValue
    }


    class func absoluteDate( date: NSDate, isStart: Bool ) -> NSDate? {
        if  let gregorian = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) {
            let inputComponents = gregorian.components([.Year, .Month, .Day, .Hour], fromDate: date)

            let components = NSDateComponents()
            components.year = inputComponents.year
            components.month = inputComponents.month
            components.day = inputComponents.day
            components.hour = inputComponents.hour

            return gregorian.dateFromComponents(components)!
        }
        return nil
    }
}
