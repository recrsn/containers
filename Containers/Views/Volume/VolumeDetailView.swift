//
//  VolumeDetailView.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 11/04/25.
//

import OSLog
import SwiftUI

struct VolumeDetailView: View {
    let volume: Volume
    @Environment(DockerContext.self) private var docker
    @State private var showingRemoveAlert = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header section
                HStack {
                    VStack(alignment: .leading) {
                        Text(volume.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Label(volume.driver, systemImage: "gearshape")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.bottom)

                ActionButtonRow {
                    ActionButton(
                        title: "Remove",
                        icon: "trash",
                        role: .destructive,
                        tint: .red,
                        action: { showingRemoveAlert = true }
                    )
                }

                Divider().padding(.vertical)

                // Details
                Group {
                    DetailRow(label: "Mount Point", value: volume.mountpoint)
                        .textSelection(.enabled)

                    DetailRow(label: "Scope", value: volume.scope)

                    if let created = volume.createdAt {
                        DetailRow(label: "Created", value: formatDate(created))
                    }

                    if let size = volume.usageData?.size {
                        DetailRow(label: "Size", value: formatSize(size))
                    }

                    if let refCount = volume.usageData?.refCount {
                        DetailRow(label: "Reference Count", value: "\(refCount)")
                    }

                    if let options = volume.options, !options.isEmpty {
                        Text("Options")
                            .font(.headline)
                            .padding(.top, 8)

                        ForEach(options.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            DetailRow(label: key, value: value)
                        }
                    }

                    if let status = volume.status, !status.isEmpty {
                        Text("Status")
                            .font(.headline)
                            .padding(.top, 8)

                        ForEach(status.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            DetailRow(label: key, value: value)
                        }
                    }

                    if let labels = volume.labels, !labels.isEmpty {
                        Text("Labels")
                            .font(.headline)
                            .padding(.top, 8)

                        ForEach(labels.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            DetailRow(label: key, value: value)
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Volume Details")
        .alert("Remove Volume", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                Task {
                    await removeVolume()
                }
            }
        } message: {
            Text("Are you sure you want to remove this volume? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
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

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        return dateFormatter.string(from: date)
    }

    private func removeVolume() async {
        do {
            try await docker.removeVolume(name: volume.name)
        } catch {
            Logger.shared.error(error, context: "Failed to remove volume: \(volume.name)")
            errorMessage = "Failed to remove volume: \(error.localizedDescription)"
            showError = true
        }
    }
}

#Preview {
    VolumeDetailView(volume: PreviewData.volume)
        .environment(DockerContext.preview)
}
