//
//  NetworkView.swift
//  Containers
//
//  Created on 13/03/25.
//

import SwiftUI

struct NetworkView: View {
    @Environment(DockerContext.self) private var docker
    @State private var selectedNetwork: Network?
    // Internal state for network selection
    @State private var showingCreateSheet = false
    @State private var newNetworkName = ""
    @State private var newNetworkDriver = "bridge"
    @State private var newNetworkSubnet = ""
    @State private var newNetworkGateway = ""
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationSplitView {
            VStack {
                if docker.networkLoading {
                    ProgressView("Loading networks...")
                        .padding()
                } else {
                    List(docker.networks, selection: $selectedNetwork) { network in
                        NetworkRow(network: network)
                            .tag(network)
                    }
                    .overlay {
                        if docker.networks.isEmpty {
                            ContentUnavailableView(
                                "No Networks",
                                systemImage: "network",
                                description: Text(
                                    "No networks found. Create a network to get started.")
                            )
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Create Network", action: { showingCreateSheet = true })
                        Button("Refresh", action: refreshNetworks)
                    } label: {
                        Label("Options", systemImage: "ellipsis.circle")
                    }
                    .disabled(!docker.isConnected)
                }
            }
        } detail: {
            if let network = selectedNetwork {
                NetworkDetailView(network: network)
            } else {
                ContentUnavailableView(
                    "No Network Selected",
                    systemImage: "square.dashed",
                    description: Text("Select a network to view its details.")
                )
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateNetworkSheet(
                networkName: $newNetworkName,
                networkDriver: $newNetworkDriver,
                networkSubnet: $newNetworkSubnet,
                networkGateway: $newNetworkGateway,
                onSubmit: createNetwork
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .task {
            if docker.isConnected {
                do {
                    try await docker.loadNetworks()
                    if let first = docker.networks.first {
                        selectedNetwork = first
                    }
                } catch {
                    Logger.shared.error(error, context: "Failed to load networks")
                    errorMessage = "Failed to load networks: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    private func refreshNetworks() {
        Task {
            do {
                try await docker.loadNetworks()
            } catch {
                Logger.shared.error(error, context: "Failed to refresh networks")
                errorMessage = "Failed to refresh networks: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    private func createNetwork() {
        guard !newNetworkName.isEmpty else { return }

        Task {
            do {
                try await docker.createNetwork(name: newNetworkName, driver: newNetworkDriver)

                // Reset form fields
                newNetworkName = ""
                newNetworkDriver = "bridge"
                newNetworkSubnet = ""
                newNetworkGateway = ""

                showingCreateSheet = false
            } catch {
                Logger.shared.error(error, context: "Failed to create network: \(newNetworkName)")
                errorMessage = "Failed to create network: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

#Preview("Network List") {
    NetworkView()
        .environment(DockerContext.preview)
}
