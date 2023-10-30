//
//  PageControlView.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 27/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI

struct PageControl<SelectionValue> : View where SelectionValue: Hashable {
    var selection: Binding<SelectionValue?>
    var listOfItems: Binding<[SelectionValue]>

    @State private var currentPage: Int = 0
    @State private var numberOfPages: Int = 0

    public init(selection: Binding<SelectionValue?>?, listOfItems: Binding<[SelectionValue]>) {
        self.selection = selection ?? .constant(nil)
        self.listOfItems = listOfItems

        self.numberOfPages = listOfItems.count
        self.currentPage = listOfItems.wrappedValue.firstIndex(where: { $0 == self.selection.wrappedValue }) ?? 0
    }

    var body: some View {
        PageControlView(currentPage: $currentPage, numberOfPages: $numberOfPages)
            .onChange(of: selection.wrappedValue) { _, newValue in
                guard newValue != nil else {
                    return
                }

                numberOfPages = listOfItems.count
                currentPage = listOfItems.wrappedValue.firstIndex(where: { $0 == newValue }) ?? 0
            }
            .onChange(of: currentPage) { _, newValue in
                guard selection.wrappedValue != nil else {
                    return
                }

                selection.wrappedValue = listOfItems.wrappedValue[newValue]
            }
            .onChange(of: listOfItems.wrappedValue) {
                guard let selection = selection.wrappedValue else {
                    return
                }

                currentPage = listOfItems.wrappedValue.firstIndex(where: { $0 == selection }) ?? 0
                numberOfPages = listOfItems.count
            }
    }
}

struct PageControlView<T: FixedWidthInteger>: UIViewRepresentable {
    @Binding var currentPage: T
    @Binding var numberOfPages: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIPageControl {
        let uiView = UIPageControl()
        uiView.backgroundStyle = .prominent
        uiView.numberOfPages = numberOfPages
        uiView.currentPage = Int(currentPage)
        uiView.currentPageIndicatorTintColor = .accent
        uiView.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged), for: .valueChanged)
        return uiView
    }

    func updateUIView(_ uiView: UIPageControl, context: Context) {
        uiView.numberOfPages = numberOfPages
        uiView.currentPage = Int(currentPage)
    }
}

extension PageControlView {
    final class Coordinator: NSObject {
        var parent: PageControlView

        init(_ parent: PageControlView) {
            self.parent = parent
        }

        @objc func valueChanged(sender: UIPageControl) {
            withAnimation {
                parent.currentPage = sender.currentPage as! T
            }
        }
    }
}
