//
//  PlotFetcher.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 16.06.15.
//  Copyright © 2015 RHC. All rights reserved.
//

import Foundation


class PlotURLSession : NSObject, NSURLSessionDataDelegate {
    class var sharedPlotSession: PlotURLSession {
        struct Singleton {
            static let sharedAppSession = PlotURLSession()
        }

        return Singleton.sharedAppSession
    }

    private var privateSharedSession: NSURLSession?

    override init() {
        super.init()
    }

    func sharedSession() -> NSURLSession {

        if let _sharedSession = privateSharedSession {
            return _sharedSession
        } else {
            privateSharedSession = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration(), delegate: self, delegateQueue: nil)
            return privateSharedSession!
        }
    }

    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void) {
        DLOG("")
        completionHandler(nil)
    }

    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        DLOG("Error: \(error?.localizedDescription)")
        self.privateSharedSession = nil
    }
}


public class PlotFetcher : NSObject {

    var characters:String = ""
    var result = [[String:String]]()
    var currentPlot = [String:String]()

    public func fetchForStationId( stationId: Int, completionHandler:(([[String:String]], NSError?) -> Void)) {

        NSNotificationCenter.defaultCenter().postNotificationName(AppConfig.Notification.networkRequestStart, object: nil)

        let request = NSURLRequest(URL: NSURL(string: "http://vindsiden.no//xml.aspx?id=\(stationId)&hours=\(Int(AppConfig.Global.plotHistory-1))")!)
        DLOG("\(request)")

        let task = PlotURLSession.sharedPlotSession.sharedSession().dataTaskWithRequest(request) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            guard let data = data else {
                DLOG("Error: \(error)")
                completionHandler( [[String:String]](), error)
                NSNotificationCenter.defaultCenter().postNotificationName(AppConfig.Notification.networkRequestEnd, object: nil)
                return;
            }

            let parser = NSXMLParser(data: data)
            parser.delegate = self
            parser.parse()

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionHandler(self.result, error)
                NSNotificationCenter.defaultCenter().postNotificationName(AppConfig.Notification.networkRequestEnd, object: nil)
            })
        }

        task.resume()
    }


    public class func invalidate() -> Void {
        PlotURLSession.sharedPlotSession.sharedSession().invalidateAndCancel()
    }
}


extension PlotFetcher: NSXMLParserDelegate {
    public func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if elementName == "Measurement" {
            currentPlot = [String:String]()
        }
        characters = ""
    }


    public func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Measurement" {
            result.append(currentPlot)
        } else {
            currentPlot[elementName] = characters
        }
    }

    public func parser(parser: NSXMLParser, foundCharacters string: String) {
        characters += string
    }
}