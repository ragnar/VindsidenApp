//
//  UIImage+Graph.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 12.05.15.
//  Copyright (c) 2015 RHC. All rights reserved.
//

import Foundation
import CoreGraphics



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
    let totalMinutes: TimeInterval
    let scale: CGFloat

    let earliestDate: Date
    let absoluteStartDate: Date
    let absoluteEndDate: Date
    let bounds: GraphBounds

    var plots = [CDPlot]()

    lazy var speedFormatter : NumberFormatter = {
        let _speedFormatter = NumberFormatter()
        _speedFormatter.numberStyle = NumberFormatter.Style.decimal
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

        let earliestDate: Date
        let latestDate: Date

        if plots.count > 0 {
            earliestDate = plots.last?.value(forKeyPath: "plotTime") as! Date
            latestDate = (plots.first?.value(forKeyPath: "plotTime") as! Date).addingTimeInterval(3600)
        } else {
            earliestDate = Date()
            latestDate = Date()
        }

        self.earliestDate = earliestDate
        absoluteStartDate = GraphImage.absoluteDate(earliestDate, isStart: true)!
        absoluteEndDate = GraphImage.absoluteDate(latestDate, isStart: false)!
        totalMinutes = self.absoluteEndDate.timeIntervalSince(self.absoluteStartDate)/60.0

        stepX = bounds.width/CGFloat(totalMinutes)
    }


    public func drawImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions( size, false, scale)
        let context = UIGraphicsGetCurrentContext()

        context!.drawPath(using: CGPathDrawingMode.stroke)

        drawSpeedLines(context)
        drawHourLines(context)
        drawGrid(context)
        drawHourText(context)
        drawSpeedText(context)
        drawGraphLines(context)
        drawWindArrows(context)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image!
    }


    final func drawGrid( _ context: CGContext! ) -> Void {
        context.saveGState()
        context.beginPath()

        UIColor.white.set()
        context.setAllowsAntialiasing(false)
        context.setLineWidth(1.0/scale)


        context.move(to: CGPoint(x: bounds.minX, y: bounds.maxY))
        context.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))

        context.move(to: CGPoint(x: bounds.minX, y: bounds.minY-5.0))
        context.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))

        context.drawPath(using: CGPathDrawingMode.stroke)

        context.restoreGState()
    }


    final func drawSpeedLines( _ context: CGContext! ) -> Void {
        context.saveGState();

        let plotMaxValue = self.plotMaxValue()
        var totSteps = min(5, plotMaxValue)
        totSteps = max( 5, totSteps)
        let plotStep = bounds.height/totSteps

        context.setAllowsAntialiasing(false)
        context.setLineWidth(1.0/scale)
        UIColor.white.set()

        context.beginPath()

        var y = bounds.maxY

        while ( y >= bounds.minY) {
            context.move(to: CGPoint(x: bounds.minX - (2.0/scale), y: y))
            context.addLine(to: CGPoint(x: bounds.minX, y: y))
            y = ceil(y-plotStep)
        }

        context.closePath()
        context.drawPath(using: CGPathDrawingMode.stroke)

        context.beginPath()

        y = ceil(bounds.maxY-plotStep)

        while ( y >= bounds.minY) {
            context.move(to: CGPoint(x: bounds.minX, y: y))
            context.addLine(to: CGPoint(x: bounds.maxX, y: y))
            y = ceil(y-plotStep)
        }

        UIColor.lightGray.set()

//        let lengths = [2.0, 3.0] as [CGFloat]
//        CGContextSetLineDash( context, 0.0, lengths, 2)
        context.setLineDash(phase: 0.0, lengths: [2.0, 3.0])
        context.drawPath(using: CGPathDrawingMode.stroke)

        context.restoreGState()
    }


    final func drawHourLines( _ context: CGContext! ) -> Void {
        context.saveGState();
        context.setLineWidth(1.0/scale);
        context.setAllowsAntialiasing(false);
        context.beginPath();
        UIColor.white.set()

        let hours = self.hours()


        for i in stride(from: 0, through: hours, by: 0.25) {
            let lineLength = CGFloat( 0 == fmod(i, 1) ? (4.0/scale) : (2.0/scale))
            let x = CGFloat(ceil(Double(bounds.minX) + (i*(Double(bounds.width)/hours))))

            context.move(to: CGPoint(x: x, y: bounds.maxY))
            context.addLine(to: CGPoint(x: x, y: bounds.maxY+lineLength))
        }

        context.closePath()
        context.drawPath(using: CGPathDrawingMode.stroke)
        context.restoreGState()
    }


    final func drawHourText( _ context: CGContext! ) {
        context.saveGState();
        context.setAllowsAntialiasing(true);

        let hours = self.hours()
        let drawAttr = [
            NSFontAttributeName : UIFont.systemFont(ofSize: 12.0/scale),
            NSForegroundColorAttributeName : UIColor.white
        ]

        for i in stride(from: 0, through: hours, by: 1) {
            let x = CGFloat(ceil(Double(bounds.minX) + (i*(Double(bounds.width)/hours))))
            let hs = String(format: "%02ld", hourComponentForDate(self.earliestDate.addingTimeInterval((3600*i)))) as NSString
            let labelBounds = hs.boundingRect(with: CGSize( width: 40.0, height: 21.0), options: .usesLineFragmentOrigin, attributes: drawAttr, context: nil)
            let point = CGPoint( x: x-ceil(labelBounds.width/2), y: bounds.maxY+(6.0/scale))

            hs.draw(at: point, withAttributes: drawAttr)
        }

        context.restoreGState()
    }


    func drawSpeedText( _ context: CGContext! ) {
        context.saveGState();
        context.setAllowsAntialiasing(true)

        let raw = AppConfig.sharedConfiguration.applicationUserDefaults.integer(forKey: "selectedUnit")
        let unit = SpeedConvertion(rawValue: raw)!

        let plotMaxValue = ceil(((plots as NSArray).value(forKeyPath: "@max.windMax") as! NSNumber).speedConvertion(to: unit)+1)
        var totSteps = min(5, plotMaxValue)
        totSteps = max( 5, totSteps)
        let plotStep = bounds.height/totSteps

        var drawAttr = [
            NSFontAttributeName : UIFont.systemFont(ofSize: 12.0/scale),
            NSForegroundColorAttributeName : UIColor.white
        ]

        var labelBounds = CGRect.zero

        var i: CGFloat = 0.0
        var y = bounds.maxY

        while ( y >= bounds.minY) {
            let hhs = NSNumber( value:Float(i*(plotMaxValue/totSteps)))

            if let hs = speedFormatter.string(from: hhs) {
                labelBounds = hs.boundingRect(with: CGSize( width: 40.0, height: 21.0), options: .usesLineFragmentOrigin, attributes: drawAttr, context: nil)
                let point = CGPoint( x: ceil(bounds.minX-labelBounds.width-5), y: ceil(y-(labelBounds.height/2)-(2/scale)) )
                hs.draw( at: point, withAttributes: drawAttr)
            }
            i += 1
            y = ceil(y-plotStep)
        }

        let unitString = NSNumber.shortUnitNameString(unit)!
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        drawAttr = [
            NSFontAttributeName : UIFont.boldSystemFont(ofSize: 12.0/scale),
            NSForegroundColorAttributeName : UIColor.white,
            NSParagraphStyleAttributeName : paragraphStyle
        ]

        labelBounds = unitString.boundingRect(with: CGSize( width: 40.0, height: 21.0), options: .usesLineFragmentOrigin, attributes: drawAttr, context: nil)
        labelBounds.origin.x = bounds.minX
        labelBounds.origin.y = bounds.minY - 18.0
        unitString.draw( in: labelBounds, withAttributes:drawAttr)

        context.restoreGState();
    }


    func drawGraphLines( _ context: CGContext!) {
        context.saveGState()
        context.setAllowsAntialiasing(true)
        context.beginPath()
        //CGContextSetShadowWithColor( context, CGSizeMake(0.0, 2.0), 2.0, UIColor(white: 0.0, alpha: 0.35).CGColor)

        let raw = AppConfig.sharedConfiguration.applicationUserDefaults.integer(forKey: "selectedUnit")
        let unit = SpeedConvertion(rawValue: raw)!

        let firstPlot = plots.first!
        var minPoints = [CGPoint]()
        var avgPoints = [CGPoint]()
        var maxPoints = [CGPoint]()

        let plotMaxValue = self.plotMaxValue()
        let interval = CGFloat(firstPlot.plotTime!.timeIntervalSince(self.absoluteStartDate)/60.0)
        var x = ceil(bounds.minX + (interval*self.stepX))


        for (idx, plot) in plots.enumerated() {
            if idx > 0 {
                let interval = CGFloat(plot.plotTime!.timeIntervalSince(self.absoluteStartDate)/60.0)
                x = ceil(bounds.minX + (interval*self.stepX))
            }

            let rMax = plot.windMax!.speedConvertion(to: unit)
            let yMax = bounds.maxY - (rMax / plotMaxValue) * bounds.height
            maxPoints.append(CGPoint(x: x, y: yMax))

            let rMin = plot.windMin!.speedConvertion(to: unit)
            let yMin = bounds.maxY - (rMin / plotMaxValue) * bounds.height
            minPoints.append(CGPoint(x: x, y: yMin))

            let rAvg = plot.windAvg!.speedConvertion(to: unit)
            let yAvg = bounds.maxY - (rAvg / plotMaxValue) * bounds.height
            avgPoints.append(CGPoint(x: x, y: yAvg))
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

        context.restoreGState();
    }


    func drawWindArrows( _ context: CGContext!) {
        context.saveGState()

        let firstPlot = plots.first!
        let interval = CGFloat(firstPlot.plotTime!.timeIntervalSince(self.absoluteStartDate)/60.0)
        var x = ceil(bounds.minX + (interval*self.stepX))

        for plot in plots {
            let interval = CGFloat(plot.plotTime!.timeIntervalSince(self.absoluteStartDate)/60.0)
            x = ceil(bounds.minX + (interval*self.stepX))

            let winddir = CGFloat(plot.windDir!.floatValue)
            let windspeed = CGFloat(plot.windAvg!.floatValue)
            let image = DrawArrow.drawArrow( atAngle: winddir, forSpeed:windspeed, highlighted:false, color: UIColor.white, hightlightedColor: UIColor.black)

            image?.draw(in: CGRect(x: x-8.0, y: bounds.maxY+10, width: 16.0, height: 16.0))
        }

        context.restoreGState();
    }


    // MARK: -


    func bezierPathWithPoints( _ points: [CGPoint] ) -> UIBezierPath {
        let bezierPath = self.quadCurvedPathWithPoints(points)
        bezierPath.lineJoinStyle = CGLineJoin.round
        bezierPath.lineCapStyle = CGLineCap.round
        bezierPath.lineWidth = 2.0/scale

        return bezierPath
    }


    final func quadCurvedPathWithPoints( _ points:[CGPoint]) -> UIBezierPath {
        let path = UIBezierPath()

        if points.count > 0 {

            var p1 = points.first!
            path.move(to: p1)

            if points.count == 2 {
                path.addLine(to: points.last!)
            } else {
                for i in 1..<points.count {
                    let p2 = points[i]
                    let midPoint = midPointForPoints(p1, p2)

                    path.addQuadCurve(to: midPoint, controlPoint: p1)
                    path.addQuadCurve(to: p2, controlPoint: controlPointForPoints(midPoint, p2))

                    p1 = p2
                }
            }
        }
        return path
    }


    final func midPointForPoints( _ p1:CGPoint, _ p2:CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    }


    final func controlPointForPoints( _ p1:CGPoint, _ p2:CGPoint) -> CGPoint {
        var controlPoint = midPointForPoints(p1, p2)
        let diffY = fabs(p2.y - controlPoint.y)

        if p1.y < p2.y {
            controlPoint.y += diffY
        } else if p1.y > p2.y {
            controlPoint.y -= diffY
        }
        
        return controlPoint
    }


    final func hourComponentForDate( _ date:Date) -> Int {
        let gregorian = Calendar(identifier: Calendar.Identifier.gregorian)
        let hourComponents = (gregorian as NSCalendar).components(.hour, from: date)
        return hourComponents.hour!
    }


    final func hours() -> Double {
        return Double(Int(self.absoluteEndDate.timeIntervalSince(self.absoluteStartDate)/3600))
    }


    func plotMaxValue() -> CGFloat {
        let raw = AppConfig.sharedConfiguration.applicationUserDefaults.integer(forKey: "selectedUnit")
        let unit = SpeedConvertion(rawValue: raw)!
        let plotMaxValue = ceil(((plots as NSArray).value(forKeyPath: "@max.windMax") as! NSNumber).speedConvertion(to: unit)+1)

        return plotMaxValue
    }


    class func absoluteDate( _ date: Date, isStart: Bool ) -> Date? {
        let gregorian = Calendar(identifier: Calendar.Identifier.gregorian)
        let inputComponents = (gregorian as NSCalendar).components([.year, .month, .day, .hour], from: date)

        var components = DateComponents()
        components.year = inputComponents.year
        components.month = inputComponents.month
        components.day = inputComponents.day
        components.hour = inputComponents.hour

        return gregorian.date(from: components)!
    }
}
