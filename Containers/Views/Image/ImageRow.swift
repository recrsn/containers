//
//  ImageRow.swift
//  Containers
//
//  Created on 11/04/25.
//

import SwiftUI

struct ImageRow: View {
    let image: ContainerImage

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(image.displayName)
                    .font(.headline)

                Text(image.shortId)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(formatSize(image.size))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(formatDate(image.created))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatSize(_ size: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    private func formatDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ImageRow(image: PreviewData.image)
        .padding()
        .frame(width: 400)
}
