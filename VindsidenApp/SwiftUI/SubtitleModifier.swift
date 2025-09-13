//
// Copyright © 2025 Ragnarök Apps. All rights reserved.
//

import SwiftUI

struct SubtitleModifier: ViewModifier {
    let title: Text
    let subtitle: Text

    init(title: Text, subtitle: Text) {
        self.title = title
        self.subtitle = subtitle
    }

    init(title: LocalizedStringResource, subtitle: LocalizedStringResource) {
        self.title = Text(title)
        self.subtitle = Text(subtitle)
    }

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .navigationTitle(title)
                .navigationSubtitle(subtitle)
                .navigationBarTitleDisplayMode(.large)
        } else {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.large)
        }
    }
}
