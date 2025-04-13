//
//  ContentView.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 02/02/25.
//

import SwiftUI

struct ContentView: View {
    @State private var errorMessage: String?
    @State private var showError = false

    @State private var selectedSection: Section? = .containers
    // No need for columnVisibility at this level anymore

    // Section selection is all we need at this level

    @Environment(DockerContext.self) private var docker

    enum Section: String, Identifiable, CaseIterable {
        case containers = "Containers"
        case images = "Images"
        case volumes = "Volumes"
        case networks = "Networks"
        case info = "Info"

        var id: String { self.rawValue }

        var iconName: String {
            switch self {
            case .containers: return "square.stack.3d.up"
            case .images: return "cube"
            case .volumes: return "folder"
            case .networks: return "network"
            case .info: return "info.circle"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebarView
                .navigationTitle("Containers")
        } detail: {
            if !docker.isConnected {
                ConnectionErrorView(error: docker.connectionError)
            } else if let selectedSection {
                switch selectedSection {
                case .containers:
                    ContainerView()
                        .navigationTitle("Containers")
                case .images:
                    ImageView()
                        .navigationTitle("Images")
                case .volumes:
                    VolumeView()
                        .navigationTitle("Volumes")
                case .networks:
                    NetworkView()
                        .navigationTitle("Networks")
                case .info:
                    if let info = docker.systemInfo {
                        DockerInfoView(info: info)
                            .navigationTitle("Docker Info")
                    } else {
                        ContentUnavailableView(
                            "Loading...",
                            systemImage: "info.circle",
                            description: Text("Docker system information is being loaded.")
                        )
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Selection",
                    systemImage: "square.dashed",
                    description: Text("Select a section from the sidebar to get started.")
                )
            }
        }
        .onAppear {
            Task {
                do {
                    try await docker.connect()
                    try await docker.refreshAll()
                } catch {
                    Logger.shared.error(error, context: "Failed to connect to Docker")
                    errorMessage = "Failed to connect to Docker: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
        .task {
            if docker.isConnected {
                do {
                    try await docker.refreshAll()
                } catch {
                    Logger.shared.error(error, context: "Failed to refresh Docker objects")
                    errorMessage = "Failed to refresh Docker objects: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        // No need to change column visibility at this level
    }

    private var sidebarView: some View {
        List(selection: $selectedSection) {
            NavigationLink(value: Section.containers) {
                Label {
                    HStack {
                        Text("Containers")
                        if docker.containerLoading {
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                } icon: {
                    Image(systemName: "square.stack.3d.up")
                }
            }

            NavigationLink(value: Section.images) {
                Label {
                    HStack {
                        Text("Images")
                        if docker.imageLoading {
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                } icon: {
                    Image(systemName: "cube")
                }
            }

            NavigationLink(value: Section.volumes) {
                Label {
                    HStack {
                        Text("Volumes")
                        if docker.volumeLoading {
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                } icon: {
                    Image(systemName: "folder")
                }
            }

            NavigationLink(value: Section.networks) {
                Label {
                    HStack {
                        Text("Networks")
                        if docker.networkLoading {
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                } icon: {
                    Image(systemName: "network")
                }
            }

            NavigationLink(value: Section.info) {
                Label {
                    HStack {
                        Text("Info")
                        if docker.isLoading {
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                } icon: {
                    Image(systemName: "info.circle")
                }
            }
        }
    }

}

#Preview {
    ContentView()
        .environment(DockerContext.preview)
}
