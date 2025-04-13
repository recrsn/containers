//
//  NetworkDetailView.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 16/03/25.
//

import SwiftUI

struct NetworkDetailView: View {
    let network: Network
    @Environment(DockerContext.self) private var docker: DockerContext
    @State private var showingRemoveAlert = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header section
                HStack {
                    VStack(alignment: .leading) {
                        Text(network.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        HStack {
                            Label(network.driver ?? "none", systemImage: "network")
                                .foregroundStyle(.secondary)

                            Text("•")
                                .foregroundStyle(.secondary)

                            Text(network.scope)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(.bottom)

                Divider().padding(.vertical)

                // Details
                Group {
                    DetailRow(label: "ID", value: network.id)
                        .textSelection(.enabled)

                    if let created = network.created {
                        DetailRow(label: "Created", value: formatDate(created))
                    }

                    if let isInternal = network.isInternal {
                        DetailRow(label: "Internal", value: isInternal ? "Yes" : "No")
                    }

                    // IPAM Configuration
                    Text("IPAM Configuration")
                        .font(.headline)
                        .padding(.top, 8)

                    DetailRow(label: "IPAM Driver", value: network.ipam.driver ?? "default")

                    if let ipamConfig = network.ipam.config, !ipamConfig.isEmpty {
                        ForEach(0..<ipamConfig.count, id: \.self) { i in
                            let config = ipamConfig[i]

                            VStack(alignment: .leading, spacing: 8) {
                                if let subnet = config.subnet {
                                    DetailRow(label: "Subnet", value: subnet)
                                }

                                if let gateway = config.gateway {
                                    DetailRow(label: "Gateway", value: gateway)
                                }

                                if let ipRange = config.ipRange {
                                    DetailRow(label: "IP Range", value: ipRange)
                                }
                            }
                            .padding(.bottom, 4)
                        }
                    }

                    // Connected Containers
                    if let containers = network.containers, !containers.isEmpty {
                        Text("Connected Containers")
                            .font(.headline)
                            .padding(.top, 8)

                        ForEach(Array(containers.keys), id: \.self) { containerId in
                            if let container = containers[containerId] {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(container.name ?? containerId.prefix(12).description)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    if let ipv4 = container.ipv4Address {
                                        DetailRow(label: "IPv4", value: ipv4)
                                    }

                                    if let ipv6 = container.ipv6Address {
                                        DetailRow(label: "IPv6", value: ipv6)
                                    }

                                    if let mac = container.macAddress {
                                        DetailRow(label: "MAC", value: mac)
                                    }
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.bottom, 4)
                            }
                        }
                    }

                    // Options
                    if let options = network.options, !options.isEmpty {
                        Text("Options")
                            .font(.headline)
                            .padding(.top, 8)

                        ForEach(options.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            DetailRow(label: key, value: value)
                        }
                    }

                    // Labels
                    if let labels = network.labels, !labels.isEmpty {
                        Text("Labels")
                            .font(.headline)
                            .padding(.top, 8)

                        ForEach(labels.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            DetailRow(label: key, value: value)
                        }
                    }
                }

                Spacer()

                ActionButtonRow {
                    ActionButton(
                        title: "Remove",
                        icon: "trash",
                        role: .destructive,
                        tint: .red,
                        action: { showingRemoveAlert = true }
                    )
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Network Details")
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .alert("Remove Network", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                removeNetwork()
            }
        } message: {
            Text(
                "Are you sure you want to remove the network '\(network.name)'? This action cannot be undone."
            )
        }
    }

    private func removeNetwork() {
        Task {
            do {
                try await docker.removeNetwork(id: network.id)
            } catch {
                errorMessage = "Failed to remove network: \(error.localizedDescription)"
                showError = true
            }
        }
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

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        return dateFormatter.string(from: date)
    }
}

#Preview("Network Detail") {
    NavigationStack {
        NetworkDetailView(network: PreviewData.network)
            .environment(DockerContext.preview)
    }
}
