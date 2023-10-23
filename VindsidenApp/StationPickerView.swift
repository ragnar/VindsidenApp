//
//  StationPickerView.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 13/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import VindsidenKit


struct StationPickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.editMode) private var editMode

    @FetchRequest(sortDescriptors: [
        NSSortDescriptor(key: "order", ascending: true),
        NSSortDescriptor(key: "stationName", ascending: true),
    ])
    private var stations: FetchedResults<CDStation>

    var body: some View {
        List {
            ForEach(stations) { station in
                HStack {
                    PickerCell(name: station.stationName!,
                               value: .constant(!(station.isHidden?.boolValue ?? false)))
                    .disabled(editMode?.wrappedValue.isEditing ?? false)
                    .onTapGesture(count: 1, perform: {
                        if editMode?.wrappedValue.isEditing ?? false {
                            return
                        }

                        guard var isHidden = station.isHidden?.boolValue else {
                            return
                        }

                        isHidden.toggle()

                        station.isHidden = NSNumber(booleanLiteral: isHidden)
                        try? viewContext.save()
                    })
                    Spacer()
                    Text(verbatim: station.city!)
                        .foregroundStyle(.secondary)
                }
            }
            .onMove(perform: moveNotes)
        }
        .toolbar {
            EditButton()
        }
        .navigationTitle("Stations")
        .navigationBarTitleDisplayMode(.inline)
    }

    func moveNotes(_ indexes: IndexSet, _ i: Int) {
        guard
            let from = indexes.first,
            indexes.count == 1,
            from != i
        else { 
            return
        }

        var undo = viewContext.undoManager
        var resetUndo = false

        if undo == nil {
            viewContext.undoManager = .init()
            undo = viewContext.undoManager
            resetUndo = true
        }

        defer {
            if resetUndo {
                viewContext.undoManager = nil
            }
        }

        do {
            try viewContext.performAndWait {
                undo?.beginUndoGrouping()
                let moving = stations[from]

                if from > i { // moving up
                    stations[i..<from].forEach {
                        $0.orderIndex = $0.orderIndex + 1
                    }
                    moving.orderIndex = Int(i)
                }

                if from < i { // moving down
                    stations[(from+1)..<i].forEach {
                        $0.orderIndex = $0.orderIndex - 1
                    }
                    moving.orderIndex = Int(i)
                }

                undo?.endUndoGrouping()
                try viewContext.save()
            }
        } catch {
            undo?.endUndoGrouping()
            viewContext.undo()

            fatalError(error.localizedDescription)
        }
    }
}

extension CDStation {
    var orderIndex: Int {
        set {
            order = NSNumber(integerLiteral: newValue)
        }
        get {
            return order?.intValue ?? 0
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
