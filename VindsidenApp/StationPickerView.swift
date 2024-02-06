//
//  StationPickerView.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 13/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import SwiftData
import VindsidenKit

private struct IdentifiableString: Identifiable {
    var id: String {
        return string
    }

    let string: String
}

struct StationPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode

    @State private var activeSheetName: IdentifiableString? = nil

    @Query(sort: [SortDescriptor(\Station.order), SortDescriptor(\Station.stationName)])
    private var stations: [Station]

    var body: some View {
        List {
            ForEach(stations) { station in
                HStack {
                    PickerCell(name: station.stationName!,
                               value: .constant(station.isHidden == false))
                    .disabled(editMode?.wrappedValue.isEditing ?? false)
                    .onTapGesture(count: 1, perform: {
                        if editMode?.wrappedValue.isEditing ?? false {
                            return
                        }

                        station.isHidden.toggle()
                        try? modelContext.save()

                        if station.isHidden {
                            DataManager.shared.removeStationFromIndex(station)
                        } else {
                            DataManager.shared.addStationToIndex(station)
                        }
                    })
                    Spacer()
                    Text(verbatim: station.city!)
                        .foregroundStyle(.secondary)
                    Button(action: {
                        activeSheetName = IdentifiableString(string: station.stationName!)
                    }, label: {
                        Image(systemName: "info.circle")
                    })
                }
            }
            .onMove(perform: moveStations)
        }
        .toolbar {
            EditButton()
        }
        .navigationTitle("Stations")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeSheetName) { name in
            StationDetailsView(stationName: name.string)
        }
    }

    func moveStations(_ indexes: IndexSet, _ i: Int) {
        var modifying = stations
        var order: Int16 = 1

        modifying.move(fromOffsets: indexes, toOffset: i)

        modifying.forEach { station in
            station.order = order
            order += 1
        }

        do {
            try modelContext.save()
        } catch {
            print("SAVING FAILED")
        }
    }
}

struct PickerCell: View {
    var name: String
    @Binding var value: Bool

    var body: some View {
        HStack {
            Toggle(isOn: $value, label: {
                Text(verbatim: name)
            })
            .toggleStyle(LeadingCheckboxToggleStyle())
        }
        .contentShape(Rectangle())
    }
}

struct LeadingCheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        return HStack {
            if configuration.isOn {
                Image(systemName: "checkmark")
                    .frame(width: 36, height: 36, alignment: .center)
                    .foregroundColor(.accentColor)
                    .onTapGesture {
                        configuration.isOn.toggle()
                    }
            } else {
                Image(uiImage: UIImage())
                    .frame(width: 36, height: 36, alignment: .center)
                    .onTapGesture {
                        configuration.isOn.toggle()
                    }
            }

            configuration.label
            Spacer()
        }
    }
}
