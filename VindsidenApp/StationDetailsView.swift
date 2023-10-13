//
//  StationDetailsView.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 13/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import UIKit

struct StationDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    let station: CDStation

    var body: some View {
        NavigationView {
            Form {
                Section {
                    InfoCell(title: "Name", value: station.stationName)
                    InfoCell(title: "Place", value: station.city)
                    InfoCell(title: "Copyright", value: station.copyright)
                    InfoCell(title: "Info", value: station.stationText)
                    InfoCell(title: "Status", value: station.statusMessage)
                    InfoCell(title: "Camera", value: station.webCamText)
                }

                Section {
                    LinkCell(title: "Go to yr.no", url: yrURL())
                    LinkCell(title: "View in Maps", url: mapsURL())
                }
            }
            .navigationTitle(station.stationName!)
            .listStyle(.insetGrouped)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    func yrURL() -> URL {
        guard
            let unwrapped = station.yrURL,
            let yrurl = unwrapped.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
            let url = URL(string: yrurl)
        else {
            fatalError("Unable to create url")
        }

        return url
    }

    func mapsURL() -> URL {
        let spotCord = station.coordinate
        var query = "http://maps.apple.com/?t=h&z=10"

        if spotCord.latitude > 0 || spotCord.longitude > 0 {
            query += "&ll=\(spotCord.latitude),\(spotCord.longitude)"
        }

        if let city = station.city, city.isEmpty == false {
            query += "&q=\(city)"
        } else if let stationName = station.stationName {
            query += "&q=\(stationName)"
        }

        guard
            let mapurl = query.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
            let url = URL(string: mapurl)
        else {
            fatalError("Unable to create url")
        }

        return url
    }
}

struct InfoCell: View {
    var title: LocalizedStringKey
    var value: String?

    lazy var regexRemoveHTMLTags: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "(<[^>]+>)", options: .caseInsensitive)
    }()

    var formatted: String {
        guard
            let value,
            let regexRemoveHTMLTags = try? NSRegularExpression(pattern: "(<[^>]+>)", options: .caseInsensitive)
        else {
            return ""
        }

        return regexRemoveHTMLTags.stringByReplacingMatches(in: value, options: [], range: NSMakeRange(0, value.utf16.count), withTemplate: "")
            .replacingOccurrences(of: "\n", with: "")
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.accentColor)
            Text(formatted)
                .font(.body)
        }
    }
}

struct LinkCell: View {
    var title: LocalizedStringKey
    var url: URL

    var body: some View {
        Link(title, destination: url)
            .font(.body)
    }
}

