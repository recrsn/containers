//
//  NetworkRow.swift
//  Containers
//
//  Created on 11/04/25.
//

import SwiftUI

struct NetworkRow: View {
    let network: Network

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(network.name)
                    .font(.headline)

                HStack(spacing: 12) {
                    Label(network.driver ?? "none", systemImage: "network")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let config = network.ipam.config?.first, let subnet = config.subnet {
                        Text(subnet)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing) {
                if let containers = network.containers {
                    Text("\(containers.count) containers")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("0 containers")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let created = network.created {
                    Text(formatDate(created))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withFullDate,
            .withFullTime,
            .withDashSeparatorInDate,
            .withFractionalSeconds
        ]

        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NetworkRow(network: PreviewData.network)
        .padding()
        .frame(width: 400)
}
