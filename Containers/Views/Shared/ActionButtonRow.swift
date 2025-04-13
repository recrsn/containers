//
//  ActionButtonRow.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 15/03/25.
//

import SwiftUI

struct ActionButtonRow<Content: View>: View {
    var content: Content

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack {
            content
        }.fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    ActionButtonRow {
        ActionButton(title: "Play", icon: "play.fill", action: {})
        ActionButton(title: "Pause", icon: "pause.fill", action: {})
        ActionButton(title: "Restart", icon: "arrow.clockwise", action: {})
    }
}
