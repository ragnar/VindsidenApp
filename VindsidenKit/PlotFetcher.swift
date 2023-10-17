//
//  PlotFetcher.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 16.06.15.
//  Copyright © 2015 RHC. All rights reserved.
//

import Foundation
import OSLog

public final class PlotFetcher: NSObject {
    var characters:String = ""
    var result = [[String: String]]()
    var currentPlot = [String: String]()

    public func fetchForStationId( _ stationId: Int) async throws -> [[String : String]] {
        let request = URLRequest(url: URL(string: "http://vindsiden.no/xml.aspx?id=\(stationId)&hours=\(Int(AppConfig.Global.plotHistory))")!)
        let session = URLSession(configuration: .ephemeral)
        
        Logger.fetcher.debug("Fetching from: \(request)")

        let (data, _) = try await session.data(for: request)
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        return result
    }
}

extension PlotFetcher: XMLParserDelegate {
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if elementName == "Measurement" {
            currentPlot = [String: String]()
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
