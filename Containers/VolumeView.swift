//
//  VolumeView.swift
//  Containers
//
//  Created on 13/03/25.
//

import SwiftUI

struct VolumeView: View {
    @EnvironmentObject private var dockerSettings: DockerSettings
    @State private var volumes: [Volume] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var selectedVolume: Volume?
    @State private var showingActionSheet = false
    @State private var showingCreateSheet = false
    @State private var newVolumeName = ""

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading volumes...")
                    .padding()
            } else {
                List(volumes) { volume in
                    VolumeRow(volume: volume)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedVolume = volume
                            showingActionSheet = true
                        }
                }
                .overlay {
                    if volumes.isEmpty && !isLoading {
                        ContentUnavailableView(
                            "No Volumes",
                            systemImage: "folder",
                            description: Text("No volumes found. Create a volume to get started.")
                        )
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Create Volume", action: { showingCreateSheet = true })
                    Button("Refresh", action: refreshVolumes)
                } label: {
                    Label("Options", systemImage: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "Volume Actions",
            isPresented: $showingActionSheet,
            presenting: selectedVolume
        ) { volume in
            Button("Remove", role: .destructive) {
                performVolumeAction(volume: volume, action: .remove)
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateVolumeSheet(volumeName: $newVolumeName, onSubmit: createVolume)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .task {
            await loadVolumes()
        }
    }

    private func refreshVolumes() {
        Task {
            await loadVolumes()
        }
    }

    private func loadVolumes() async {
        isLoading = true
        errorMessage = nil

        do {
            volumes = try await dockerSettings.dockerClient.listVolumes()
        } catch {
            errorMessage = "Failed to load volumes: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    private enum VolumeAction {
        case remove
    }

    private func performVolumeAction(volume: Volume, action: VolumeAction) {
        Task {
            do {
                switch action {
                case .remove:
                    try await dockerSettings.dockerClient.removeVolume(name: volume.name)
                }

                // Refresh volume list after action
                await loadVolumes()
            } catch {
                errorMessage = "Failed to perform action: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    private func createVolume() {
        guard !newVolumeName.isEmpty else { return }

        Task {
            do {
                try await dockerSettings.dockerClient.createVolume(name: newVolumeName)
                newVolumeName = ""
                showingCreateSheet = false
                await loadVolumes()
            } catch {
                errorMessage = "Failed to create volume: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

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

struct CreateVolumeSheet: View {
    @Binding var volumeName: String
    @Environment(\.dismiss) private var dismiss
    var onSubmit: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Volume Name")) {
                    TextField("Name", text: $volumeName)
                        .autocorrectionDisabled()
                }

                Section(footer: Text("Only local driver is currently supported")) {
                    Text("Driver: local")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Create Volume")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onSubmit()
                    }
                    .disabled(volumeName.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 250)
    }
}

#Preview {
    VolumeView()
        .environmentObject(DockerSettings())
}
