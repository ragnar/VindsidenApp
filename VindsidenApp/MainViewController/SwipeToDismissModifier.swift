//
//  SwipeToDismissModifier.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 17/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI

struct SwipeToDismissModifier: ViewModifier {
    var onDismiss: () -> Void
    var onChange: (_ height: CGFloat) -> Void

    @State private var offset: CGSize = .zero
    @State private var isDismissed = false

    let range = 30.0 ... 170

    func body(content: Content) -> some View {
        content
            .offset(y: offset.height)
            .animation(.interactiveSpring(), value: offset)
            .simultaneousGesture(
                DragGesture()
                    .onChanged { gesture in
                        if isDismissed {
                            return
                        }
                        if gesture.translation.width < 50 {
                            offset = gesture.translation
                        }

                        let v = Double(abs(offset.height))
                            .clamped(to: range)
                            .map(from: range, to: 0.15 ... 1.0)

                        withAnimation(.interactiveSpring()) {
                            onChange(1 - v)
                        }
                    }
                    .onEnded { _ in
                        if abs(offset.height) > 170 {
                            isDismissed = true
                            onDismiss()
                        } else {
                            offset = .zero
                            withAnimation(.interactiveSpring()) {
                                onChange(0.85)
                            }
                        }
                    }
            )
    }
}


extension Double {
    public func map(from: ClosedRange<Double>, to: ClosedRange<Double>) -> Double {
        return ((self - from.lowerBound) / (from.upperBound - from.lowerBound)) * (to.upperBound - to.lowerBound) + to.lowerBound
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return max(range.lowerBound, min(self, range.upperBound))
    }
}
