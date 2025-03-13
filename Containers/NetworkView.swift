//
//  NetworkView.swift
//  Containers
//
//  Created on 13/03/25.
//

import SwiftUI

struct NetworkView: View {
    @EnvironmentObject private var dockerSettings: DockerSettings
    @State private var networks: [Network] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var selectedNetwork: Network?
    @State private var showingActionSheet = false
    @State private var showingCreateSheet = false
    @State private var newNetworkName = ""
    @State private var newNetworkDriver = "bridge"
    @State private var newNetworkSubnet = ""
    @State private var newNetworkGateway = ""

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading networks...")
                    .padding()
            } else {
                List(networks) { network in
                    NetworkRow(network: network)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedNetwork = network
                            showingActionSheet = true
                        }
                }
                .overlay {
                    if networks.isEmpty && !isLoading {
                        ContentUnavailableView(
                            "No Networks",
                            systemImage: "network",
                            description: Text("No networks found. Create a network to get started.")
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
            }
        }
        .confirmationDialog(
            "Network Actions",
            isPresented: $showingActionSheet,
            presenting: selectedNetwork
        ) { network in
            Button("Remove", role: .destructive) {
                performNetworkAction(network: network, action: .remove)
            }
            Button("Inspect", action: {
                // Future enhancement: show network details
            })
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
            await loadNetworks()
        }
    }

    private func refreshNetworks() {
        Task {
            await loadNetworks()
        }
    }

    private func loadNetworks() async {
        isLoading = true
        errorMessage = nil

        do {
            networks = try await dockerSettings.dockerClient.listNetworks()
        } catch {
            errorMessage = "Failed to load networks: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    private enum NetworkAction {
        case remove
    }

    private func performNetworkAction(network: Network, action: NetworkAction) {
        Task {
            do {
                switch action {
                case .remove:
                    try await dockerSettings.dockerClient.removeNetwork(id: network.id)
                }

                // Refresh network list after action
                await loadNetworks()
            } catch {
                errorMessage = "Failed to perform action: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    private func createNetwork() {
        guard !newNetworkName.isEmpty else { return }

        Task {
            do {
                let subnet = newNetworkSubnet.isEmpty ? nil : newNetworkSubnet
                let gateway = newNetworkGateway.isEmpty ? nil : newNetworkGateway

                _ = try await dockerSettings.dockerClient.createNetwork(
                    name: newNetworkName,
                    driver: newNetworkDriver,
                    subnet: subnet,
                    gateway: gateway
                )

                // Reset form fields
                newNetworkName = ""
                newNetworkDriver = "bridge"
                newNetworkSubnet = ""
                newNetworkGateway = ""

                showingCreateSheet = false
                await loadNetworks()
            } catch {
                errorMessage = "Failed to create network: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

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

struct CreateNetworkSheet: View {
    @Binding var networkName: String
    @Binding var networkDriver: String
    @Binding var networkSubnet: String
    @Binding var networkGateway: String
    @Environment(\.dismiss) private var dismiss
    var onSubmit: () -> Void

    private let networkDrivers = ["bridge", "host", "overlay", "macvlan", "ipvlan", "none"]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Configuration")) {
                    TextField("Name", text: $networkName)
                        .autocorrectionDisabled()

                    Picker("Driver", selection: $networkDriver) {
                        ForEach(networkDrivers, id: \.self) { driver in
                            Text(driver).tag(driver)
                        }
                    }
                }

                Section(header: Text("Network Configuration"), footer: Text("Optional CIDR notation (e.g., 172.16.0.0/16)")) {
                    TextField("Subnet", text: $networkSubnet)
                        .autocorrectionDisabled()

                    TextField("Gateway", text: $networkGateway)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Create Network")
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
                    .disabled(networkName.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    NetworkView()
        .environmentObject(DockerSettings())
}
