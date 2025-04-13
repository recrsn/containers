//
//  ContainerDetailView.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 15/03/25.
//

import SwiftUI

struct ContainerDetailView: View {
    let container: Container
    @Environment(DockerContext.self) private var docker: DockerContext
    @State private var showingRemoveAlert = false
    @State private var errorMessage: String?
    @State private var showError = false

    private var formattedDate: String {
        let date = Date(timeIntervalSince1970: TimeInterval(container.created))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    private var statusColor: Color {
        guard let state = container.state else {
            return .gray
        }

        switch state {
        case .running:
            return .green
        case .paused:
            return .yellow
        case .restarting:
            return .blue
        case .exited, .dead:
            return .red
        default:
            return .gray
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header section
                HStack {
                    VStack(alignment: .leading) {
                        Text(container.displayName)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        HStack {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 12, height: 12)

                            Text(container.status)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(.bottom)

                // Action buttons
                ActionButtonRow {
                    if container.state == .exited || container.state == .created {
                        ActionButton(
                            title: "Start", icon: "play.fill",
                            tint: .green,
                            action: {
                                startContainer()
                            })
                    }

                    if container.state == .running {
                        ActionButton(
                            title: "Stop", icon: "stop.fill",
                            role: .cancel,
                            tint: .red,
                            action: {
                                stopContainer()
                            })

                        ActionButton(
                            title: "Pause", icon: "pause.fill",
                            action: {
                                pauseContainer()
                            })

                        ActionButton(
                            title: "Restart", icon: "arrow.clockwise",
                            action: {
                                restartContainer()
                            }
                        )
                        .tint(.blue)
                    }

                    if container.state == .paused {
                        ActionButton(
                            title: "Resume", icon: "play.resume.fill",
                            tint: .green,
                            action: {
                                unpauseContainer()
                            })
                    }

                    ActionButton(
                        title: "Remove", icon: "trash",
                        role: .destructive,
                        tint: .red,
                        action: {
                            showingRemoveAlert = true
                        })
                }

                Divider().padding(.vertical)

                // Details
                Group {
                    DetailRow(label: "ID", value: container.id)
                    DetailRow(label: "Image", value: container.image)
                    DetailRow(label: "Command", value: container.command)
                    DetailRow(label: "Created", value: formattedDate)

                    if let ports = container.ports, !ports.isEmpty {
                        Text("Ports")
                            .font(.headline)
                            .padding(.top, 8)

                        ForEach(ports, id: \.privatePort) { port in
                            PortRow(port: port)
                        }
                    }

                    if let labels = container.labels, !labels.isEmpty {
                        Text("Labels")
                            .font(.headline)
                            .padding(.top, 8)

                        LabelsView(labels: labels)
                            .frame(height: min(CGFloat(labels.count * 44 + 30), 300))
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Container Details")
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .alert("Remove Container", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                removeContainer()
            }
        } message: {
            Text(
                "Are you sure you want to remove the container '\(container.displayName)'? This action cannot be undone."
            )
        }
    }

    private func startContainer() {
        Task {
            do {
                try await docker.startContainer(id: container.id)
            } catch {
                errorMessage = "Failed to start container: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    private func stopContainer() {
        Task {
            do {
                try await docker.stopContainer(id: container.id)
            } catch {
                errorMessage = "Failed to stop container: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    private func restartContainer() {
        Task {
            do {
                try await docker.restartContainer(id: container.id)
            } catch {
                errorMessage = "Failed to restart container: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    private func pauseContainer() {
        Task {
            do {
                try await docker.pauseContainer(id: container.id)
            } catch {
                errorMessage = "Failed to pause container: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    private func unpauseContainer() {
        Task {
            do {
                try await docker.unpauseContainer(id: container.id)
            } catch {
                errorMessage = "Failed to resume container: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    private func removeContainer() {
        Task {
            do {
                try await docker.removeContainer(id: container.id)
            } catch {
                errorMessage = "Failed to remove container: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

#Preview("Container Detail") {
    ContainerDetailView(container: PreviewData.container)
        .environment(DockerContext.preview)
}
