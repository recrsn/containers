//
//  VolumeView.swift
//  Containers
//
//  Created on 13/03/25.
//

import SwiftUI

struct VolumeView: View {
    @Environment(DockerContext.self) private var docker
    @State private var selectedVolume: Volume?
    // Internal state for volume selection
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showingCreateSheet = false
    @State private var newVolumeName = ""

    var body: some View {
        NavigationSplitView {
            VStack {
                if docker.volumeLoading {
                    ProgressView("Loading volumes...")
                        .padding()
                } else {
                    List(docker.volumes, selection: $selectedVolume) { volume in
                        VolumeRow(volume: volume)
                            .tag(volume)
                    }
                    .overlay {
                        if docker.volumes.isEmpty {
                            ContentUnavailableView(
                                "No Volumes",
                                systemImage: "folder",
                                description: Text(
                                    "No volumes found. Create a volume to get started.")
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
                    .disabled(!docker.isConnected)
                }
            }
        } detail: {
            if let volume = selectedVolume {
                VolumeDetailView(volume: volume)
            } else {
                ContentUnavailableView(
                    "No Volume Selected",
                    systemImage: "square.dashed",
                    description: Text("Select a volume to view its details.")
                )
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
            if docker.isConnected {
                do {
                    try await docker.loadVolumes()
                    if let first = docker.volumes.first, selectedVolume == nil {
                        selectedVolume = first
                    }
                } catch {
                    Logger.shared.error(error, context: "Failed to load volumes")
                    errorMessage = "Failed to load volumes: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    private func refreshVolumes() {
        Task {
            do {
                try await docker.loadVolumes()
            } catch {
                Logger.shared.error(error, context: "Failed to refresh volumes")
                errorMessage = "Failed to refresh volumes: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    private func createVolume() {
        guard !newVolumeName.isEmpty else { return }

        Task {
            do {
                try await docker.createVolume(name: newVolumeName)
                newVolumeName = ""
                showingCreateSheet = false
            } catch {
                Logger.shared.error(error, context: "Failed to create volume: \(newVolumeName)")
                errorMessage = "Failed to create volume: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

#Preview("Volume List") {
    VolumeView()
        .environment(DockerContext.preview)
}
