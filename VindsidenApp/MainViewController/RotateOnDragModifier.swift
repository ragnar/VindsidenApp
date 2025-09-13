//
//  RotateOnDragModifier.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 17/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI

struct RotateOnDragModifier: ViewModifier {
    @State private var angle: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .animation(.interactiveSpring(), value: angle)
            .simultaneousGesture(
                DragGesture()
                    .onChanged { gesture in
                        angle = gesture.translation.height  / 20
                    }
                    .onEnded { _ in
                        angle = 0
                    }
            )
    }
}
