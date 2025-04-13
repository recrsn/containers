//
//  VolumeRow.swift
//  Containers
//
//  Created on 13/03/25.
//

import SwiftUI

struct VolumeRow: View {
    let volume: Volume

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(volume.name)
                    .font(.headline)

                Label(volume.driver, systemImage: "gearshape")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                if let size = volume.usageData?.size {
                    Text(formatSize(size))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let created = volume.createdAt {
                    Text(formatDate(created))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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

    private func formatDate(_ dateString: String) -> String {
        // Docker returns dates in RFC3339 format
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    VolumeRow(volume: PreviewData.volume)
}
