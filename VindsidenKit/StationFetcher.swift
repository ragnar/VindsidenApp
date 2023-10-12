//
//  StationFetcher.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 15.06.15.
//  Copyright © 2015 RHC. All rights reserved.
//

import Foundation
import OSLog

public class StationFetcher : NSObject {
    var characters: String = ""
    var result = [[String: String]]()
    var currentStation = [String: String]()

    @available(*, renamed: "fetch()")
    @objc public func fetch(_ completionHandler:@escaping (([[String:String]], Error?) -> Void)) {
        Task {
            do {
                let result = try await fetch()
                DispatchQueue.main.async {
                    completionHandler(result, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completionHandler([], error)
                }
            }
        }
    }

    @objc public func fetch() async throws -> [[String : String]] {
        let request = URLRequest(url: URL(string: "http://vindsiden.no//xml.aspx")!)
        let session = URLSession(configuration: .ephemeral)
        
        Logger.fetcher.debug("Fetching from: \(request)")
        
        let (data, _) = try await session.data(for: request)
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
                
        return result
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
