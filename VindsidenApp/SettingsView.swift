//
//  SettingsView.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 13/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import VindsidenKit
import Units

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: UserObservable

    var dismissAction: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Stations")) {
                    NavigationLink("Stations") {
                        StationPickerView()
                    }
                }

                Section(header: Text("Speed")) {
                    ForEach(WindUnit.allCases) { element in
                        Cell(name: element.name, value: element, unit: $settings.windUnit)
                            .onTapGesture(count: 1, perform: {
                                self.settings.windUnit = element
                            })
                    }
                }

                Section(header: Text("Temperature"), footer: VersionFooterView()) {
                    ForEach(TempUnit.allCases) { element in
                        Cell(name: element.name, value: element, unit: $settings.tempUnit)
                            .onTapGesture(count: 1, perform: {
                                self.settings.tempUnit = element
                            })
                    }
                }

            }
            .navigationTitle("Settings")
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
        .onDisappear(perform: {
            dismissAction()
        })
    }
}

struct VersionFooterView: View {
    let appName: String
    let appVersion: String
    let appBuild: String
    let version: NSString
    let text: String

    init() {
        self.appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
        self.appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        self.appBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        self.version = NSString(format: NSLocalizedString("%@ version %@.%@", comment: "Version string in settings view") as NSString, appName, appVersion, appBuild)

        self.text = NSLocalizedString("LABEL_PERMIT", comment: "Værdata hentet med tillatelse fra\nhttp://vindsiden.no\n\n") + (version as String)
    }

    var body: some View {
        HStack {
            Text(try! AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct Cell<T: UnitProtocol>: View {
    var name: String
    var value: T
    @Binding var unit: T

    var body: some View {
        HStack {
            Toggle(isOn: .constant(value == unit), label: {
                Text(verbatim: name)
            })
            .toggleStyle(CheckboxToggleStyle())
        }
        .contentShape(Rectangle())
    }
}


struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()

            if configuration.isOn {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                    .onTapGesture {
                        configuration.isOn.toggle()
                    }
            } else {
                Image(uiImage: UIImage())
                    .onTapGesture {
                        configuration.isOn.toggle()
                    }
            }
        }
    }
}
