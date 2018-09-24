//
//  PlotFetcher.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 16.06.15.
//  Copyright © 2015 RHC. All rights reserved.
//

import Foundation


class PlotURLSession : NSObject, URLSessionDataDelegate {
    class var sharedPlotSession: PlotURLSession {
        struct Singleton {
            static let sharedAppSession = PlotURLSession()
        }

        return Singleton.sharedAppSession
    }

    fileprivate var privateSharedSession: Foundation.URLSession?

    override init() {
        super.init()
    }

    func sharedSession() -> Foundation.URLSession {

        if let _sharedSession = privateSharedSession {
            return _sharedSession
        } else {
            privateSharedSession = Foundation.URLSession(configuration: URLSessionConfiguration.ephemeral, delegate: self, delegateQueue: nil)
            return privateSharedSession!
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        DLOG("")
        completionHandler(nil)
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        DLOG("Error: \(String(describing: error?.localizedDescription))")
        self.privateSharedSession = nil
    }
}


open class PlotFetcher : NSObject {

    var characters:String = ""
    var result = [[String:String]]()
    var currentPlot = [String:String]()

    open func fetchForStationId( _ stationId: Int, completionHandler:@escaping (([[String:String]], Error?) -> Void)) {

        NotificationCenter.default.post(name: AppConfig.Notifications.networkRequestStart, object: nil)

        let request = URLRequest(url: URL(string: "http://vindsiden.no/xml.aspx?id=\(stationId)&hours=\(Int(AppConfig.Global.plotHistory-1))")!)
        DLOG("\(request)")

        let task = PlotURLSession.sharedPlotSession.sharedSession().dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard let data = data else {
                DLOG("Error: \(String(describing: error))")
                completionHandler( [[String:String]](), error)
                NotificationCenter.default.post(name: AppConfig.Notifications.networkRequestEnd, object: nil)
                return;
            }

            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()

            DispatchQueue.main.async(execute: { () -> Void in
                completionHandler(self.result, error)
                NotificationCenter.default.post(name: AppConfig.Notifications.networkRequestEnd, object: nil)
            })
        })

        task.resume()
    }


    open class func invalidate() -> Void {
        PlotURLSession.sharedPlotSession.sharedSession().invalidateAndCancel()
    }
}


extension PlotFetcher: XMLParserDelegate {
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if elementName == "Measurement" {
            currentPlot = [String:String]()
        }
        characters = ""
    }


    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Measurement" {
            result.append(currentPlot)
        } else {
            currentPlot[elementName] = characters
        }
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        characters += string
    }
}
