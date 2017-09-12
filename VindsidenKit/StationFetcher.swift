//
//  StationFetcher.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 15.06.15.
//  Copyright © 2015 RHC. All rights reserved.
//

import Foundation


class StationURLSession : NSObject, URLSessionDataDelegate {
    class var sharedStationSession: StationURLSession {
        struct Singleton {
            static let sharedAppSession = StationURLSession()
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


open class StationFetcher : NSObject {

    var characters:String = ""
    var result = [[String:String]]()
    var currentStation = [String:String]()

    open func fetch(_ completionHandler:@escaping (([[String:String]], Error?) -> Void)) {

        NotificationCenter.default.post(name: AppConfig.Notifications.networkRequestStart, object: nil)

        let request = URLRequest(url: URL(string: "http://vindsiden.no//xml.aspx")!)
        let task = StationURLSession.sharedStationSession.sharedSession().dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard let data = data else {
                DLOG("Error: \(String(describing: error))")
                DispatchQueue.main.async(execute: { () -> Void in
                    completionHandler( [[String:String]](), error)
                    NotificationCenter.default.post(name: AppConfig.Notifications.networkRequestEnd, object: nil)
                })
                return;
            }

            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()

            DispatchQueue.main.async(execute: { () -> Void in
                completionHandler(self.result, error)
                NotificationCenter.default.post(name: AppConfig.Notifications.networkRequestEnd, object: nil)
            })
        }) //as! (Data?, URLResponse?, Error?) -> Void)

        task.resume()
    }


    open class func invalidate() -> Void {
        StationURLSession.sharedStationSession.sharedSession().invalidateAndCancel()
    }
}


extension StationFetcher: XMLParserDelegate {
     public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if elementName == "Station" {
            currentStation = [String:String]()
        }
        characters = ""
    }


    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Station" {
            result.append(currentStation)
        } else {
            currentStation[elementName] = characters
        }
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        characters += string
    }
}
