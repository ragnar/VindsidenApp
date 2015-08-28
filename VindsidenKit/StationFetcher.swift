//
//  StationFetcher.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 15.06.15.
//  Copyright © 2015 RHC. All rights reserved.
//

import Foundation


class StationURLSession : NSObject, NSURLSessionDataDelegate {
    class var sharedPlotSession: StationURLSession {
        struct Singleton {
            static let sharedAppSession = StationURLSession()
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


public class StationFetcher : NSObject {

    var characters:String = ""
    var result = [[String:String]]()
    var currentStation = [String:String]()

    public func fetch(completionHandler:(([[String:String]], NSError?) -> Void)) {

        let request = NSURLRequest(URL: NSURL(string: "http://vindsiden.no//xml.aspx")!)
        let task = StationURLSession.sharedPlotSession.sharedSession.dataTaskWithRequest(request) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            guard let data = data else {
                DLOG("Error: \(error)")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler( [[String:String]](), error)
                })
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


extension StationFetcher: NSXMLParserDelegate {
     public func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if elementName == "Station" {
            currentStation = [String:String]()
        }
        characters = ""
    }


    public func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Station" {
            result.append(currentStation)
        } else {
            currentStation[elementName] = characters
        }
    }

    public func parser(parser: NSXMLParser, foundCharacters string: String) {
        characters += string
    }
}
