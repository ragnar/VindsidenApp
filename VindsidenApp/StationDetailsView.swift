//
//  StationDetailsView.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 13/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import UIKit
import SwiftData

struct StationDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query var stations: [Station]
    @State var isShowingCamera: Bool = false

    let stationName: String

    init(stationName: String) {
        self.stationName = stationName
        self._stations = Query(filter: #Predicate<VindsidenKit.Station> { $0.stationName == stationName })
    }

    var body: some View {
        NavigationView {
            Form {
                Group {
                    if let station = stations.first {
                        Section {
                            InfoCell(title: "Name", value: station.stationName)
                            InfoCell(title: "Place", value: station.city)
                            InfoCell(title: "Copyright", value: station.copyright)
                            InfoCell(title: "Info", value: station.stationText)
                            InfoCell(title: "Status", value: station.statusMessage)
                            InfoCell(title: "Camera", value: station.webCamText)
                        }

                        Section {
                            if station.webCamURL?.isEmpty == false {
                                LinkCell(title: "Show image", url: webcamURL())
                                    .environment(\.openURL, OpenURLAction { url in
                                        isShowingCamera.toggle()
                                        return .handled
                                    })
                            }

                            if station.yrURL?.isEmpty == false {
                                LinkCell(title: "Go to yr.no", url: yrURL())
                            }
                            LinkCell(title: "View in Maps", url: mapsURL())
                        }
                    } else {
                        Section {
                            InfoCell(title: "Name", value: stationName)
                        }
                    }
                }
            }
            .navigationTitle(stationName)
            .listStyle(.insetGrouped)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingCamera, content: {
            PhotoView(title: stationName, imageUrl: webcamURL())
                .edgesIgnoringSafeArea(.all)
        })
    }

    func webcamURL() -> URL {
        guard 
            let station = stations.first,
            let webCamURL = station.webCamImage,
            let url = URL(string: webCamURL)
        else {
            fatalError("Unable to create url")
        }

        return url
    }

    func yrURL() -> URL {
        guard
            let station = stations.first,
            let unwrapped = station.yrURL,
            let yrurl = unwrapped.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
            let url = URL(string: yrurl)
        else {
            fatalError("Unable to create url")
        }

        return url
    }

    func mapsURL() -> URL {
        guard let station = stations.first else {
            fatalError("Unable to create url")
        }

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

