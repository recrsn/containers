//
//  ContainerView.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 02/02/25.
//

import SwiftUI

enum ContainerAction {
    case start, stop, restart, pause, unpause, remove
}

struct ContainerView: View {
    @Environment(DockerContext.self) private var docker
    @State private var selectedContainer: Container?
    // Internal state for container selection
    @State private var showingCreateSheet = false
    @State private var newContainerConfig = CreateContainerConfig()
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationSplitView {
            VStack {
                if docker.containerLoading {
                    ProgressView("Loading containers...")
                        .padding()
                } else {
                    List(docker.containers, selection: $selectedContainer) { container in
                        ContainerRow(container: container)
                            .tag(container)
                    }
                    .overlay {
                        if docker.containers.isEmpty {
                            ContentUnavailableView(
                                "No Containers",
                                systemImage: "square.dashed",
                                description: Text(
                                    "No containers found. Pull an image and create a container to get started."
                                )
                            )
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Create Container") {
                            showingCreateSheet = true
                        }
                        Button("Refresh") {
                            Task {
                                do {
                                    try await docker.loadContainers()
                                } catch {
                                    Logger.shared.error(error, context: "Failed to load containers")
                                    errorMessage =
                                        "Failed to perform action: \(error.localizedDescription)"
                                    showError = true
                                }
                            }
                        }
                    } label: {
                        Label("Options", systemImage: "ellipsis.circle")
                    }
                    .disabled(!docker.isConnected)
                }
            }
        } detail: {
            if let container = selectedContainer {
                ContainerDetailView(container: container)
            } else {
                ContentUnavailableView(
                    "No Container Selected",
                    systemImage: "square.dashed",
                    description: Text("Select a container to view its details.")
                )
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateContainerSheet(config: $newContainerConfig)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
}

#Preview("Container List") {
    ContainerView()
        .environment(DockerContext.preview)
}
