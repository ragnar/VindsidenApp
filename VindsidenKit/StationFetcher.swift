//
//  StationFetcher.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 15.06.15.
//  Copyright © 2015 RHC. All rights reserved.
//

import Foundation
import OSLog

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
        Logger.fetcher.debug("")
        completionHandler(nil)
    }


    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        Logger.fetcher.debug("Error: \(String(describing: error?.localizedDescription))")
        self.privateSharedSession = nil
    }
}


open class StationFetcher : NSObject {

    var characters:String = ""
    var result = [[String:String]]()
    var currentStation = [String:String]()

    @objc open func fetch(_ completionHandler:@escaping (([[String:String]], Error?) -> Void)) {
        let request = URLRequest(url: URL(string: "http://vindsiden.no//xml.aspx")!)

        Logger.fetcher.debug("Fetching from: \(request)")

        let task = StationURLSession.sharedStationSession.sharedSession().dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard let data = data else {
                Logger.fetcher.debug("Error: \(String(describing: error))")
                DispatchQueue.main.async(execute: { () -> Void in
                    completionHandler( [[String:String]](), error)
                })
                return;
            }

            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()

            DispatchQueue.main.async(execute: { () -> Void in
                completionHandler(self.result, error)
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
