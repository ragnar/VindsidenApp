//
//  PhotoView.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 17/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import UIKit

struct PhotoView: View {
    @Environment(\.dismiss) private var dismiss

    @State var opacity = 1.0
    @State var scaleAnchor: UnitPoint = .center

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    @State private var offset: CGPoint = .zero
    @State private var lastTranslation: CGSize = .zero

    let title: String
    let imageUrl: URL

    weak var backgroundView: UIView?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AsyncImage(url: imageUrl, transaction: .init(animation: .spring())) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .opacity(opacity)
                            .position(x: geometry.size.width / 2,
                                      y: geometry.size.height / 2)
                            .scaleEffect(scale, anchor: scaleAnchor)
                            .offset(x: offset.x, y: offset.y)
                            .gesture(makeDragGesture(size: geometry.size))
                            .gesture(makeMagnificationGesture(size: geometry.size))
                    case .failure(_):
                        Image(systemName: "wifi.slash")
                    case .empty:
                        ProgressView()

                    @unknown default:
                        Image(systemName: "wifi.slash")
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }

    private func makeMagnificationGesture(size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value

                // To minimize jittering
                if abs(1 - delta) > 0.01 {
                    scale *= delta
                }
            }
            .onEnded { _ in
                lastScale = 1
                if scale < 1 {
                    withAnimation {
                        scale = 1
                    }
                } else if scale > 3 {
                    withAnimation {
                        scale = 3
                    }
                }
                adjustMaxOffset(size: size)
            }
    }

    private func makeDragGesture(size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let diff = CGPoint(
                    x: value.translation.width - lastTranslation.width,
                    y: value.translation.height - lastTranslation.height
                )
                offset = .init(x: offset.x + diff.x, y: offset.y + diff.y)
                lastTranslation = value.translation
            }
            .onEnded { _ in
                adjustMaxOffset(size: size)
            }
    }

    private func adjustMaxOffset(size: CGSize) {
        let maxOffsetX = (size.width * (scale - 1)) / 2
        let maxOffsetY = (size.height * (scale - 1)) / 2

        var newOffsetX = offset.x
        var newOffsetY = offset.y

        if abs(newOffsetX) > maxOffsetX {
            newOffsetX = maxOffsetX * (abs(newOffsetX) / newOffsetX)
        }
        if abs(newOffsetY) > maxOffsetY {
            newOffsetY = maxOffsetY * (abs(newOffsetY) / newOffsetY)
        }

        let newOffset = CGPoint(x: newOffsetX, y: newOffsetY)
        if newOffset != offset {
            withAnimation {
                offset = newOffset
            }
        }
        self.lastTranslation = .zero
    }
}
