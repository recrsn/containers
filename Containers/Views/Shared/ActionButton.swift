//
//  ActionButton.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 15/03/25.
//

import SwiftUI

struct ActionButton: View {
    let title: String
    let icon: String
    let role: ButtonRole?
    let tint: Color?
    let action: () -> Void

    init(
        title: String, icon: String, role: ButtonRole? = nil, tint: Color? = .secondary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.role = role
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button(role: role, action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: 40, maxHeight: 40)
            .padding(8)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
    }
}

#Preview {
    HStack {
        ActionButton(
            title: "Start", icon: "play.fill", role: .destructive, tint: .green, action: {})
        ActionButton(title: "Pause", icon: "pause.fill", action: {})
        ActionButton(title: "Restart", icon: "arrow.clockwise", action: {})
        ActionButton(title: "Create", icon: "plus", action: {})
        ActionButton(title: "Remove", icon: "trash", tint: .red, action: {})
    }.fixedSize(horizontal: false, vertical: true)
}
