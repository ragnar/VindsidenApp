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

    override init() {
        super.init()
    }

    lazy var sharedSession: NSURLSession = {
        var _sharedSession = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration(), delegate: self, delegateQueue: nil)
        return _sharedSession
        }()

    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void) {
        DLOG("")
        completionHandler(nil)
    }
}


public class PlotFetcher : NSObject {

    var characters:String = ""
    var result = [[String:String]]()
    var currentPlot = [String:String]()

    public func fetchForStationId( stationId: Int, completionHandler:(([[String:String]], NSError?) -> Void)) {

        let request = NSURLRequest(URL: NSURL(string: "http://vindsiden.no//xml.aspx?id=\(stationId)&hours=\(Int(AppConfig.Global.plotHistory-1))")!)
        DLOG("\(request)")

        let task = PlotURLSession.sharedPlotSession.sharedSession.dataTaskWithRequest(request) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            guard let data = data else {
                DLOG("Error: \(error)")
                completionHandler( [[String:String]](), error)
                return;
            }

            let parser = NSXMLParser(data: data)
            parser.delegate = self
            parser.parse()

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionHandler(self.result, error)
            })
        }

        task.resume()
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