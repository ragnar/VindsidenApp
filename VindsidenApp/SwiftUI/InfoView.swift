//
//  InfoView.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 31/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI

struct InfoView: View {
    var label: LocalizedStringKey
    var value: String

    var body: some View {
        VStack(alignment: .center) {
            Text(label)
                .font(.footnote)
            Text(value)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding([.top, .bottom], 6)
        .background(RoundedRectangle(cornerRadius: 12)
            .foregroundStyle(.regularMaterial)
        )
        .foregroundStyle(.primary)
    }
}

#Preview {
    InfoView(label: "Wind max", value: "13,2 m/s")
        .frame(width: 220)
}
