//
//  ContainerRow.swift
//  Containers
//
//  Created on 11/04/25.
//

import SwiftUI

struct ContainerRow: View {
    let container: Container

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(container.displayName)
                    .font(.headline)

                Text(container.image)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            statusIndicator
                .padding(.trailing, 8)
        }
        .padding(.vertical, 4)
    }

    private var statusIndicator: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            Text(container.status)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var statusColor: Color {
        guard let state = container.state else {
            return .gray
        }

        switch state {
        case .running:
            return .green
        case .paused:
            return .yellow
        case .restarting:
            return .blue
        case .exited, .dead:
            return .red
        default:
            return .gray
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ContainerRow(container: PreviewData.container)
        .padding()
}
