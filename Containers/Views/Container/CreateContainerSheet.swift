//
//  CreateContainerSheet.swift
//  Containers
//
//  Created on 11/04/25.
//

import SwiftUI

struct CreateContainerSheet: View {
    @Binding var config: CreateContainerConfig
    @Environment(\.dismiss) private var dismiss
    @Environment(DockerContext.self) private var docker
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Configuration")) {
                    TextField("Name (optional)", text: $config.name)
                    TextField("Image", text: $config.image)
                        .autocorrectionDisabled()
                    TextField("Command (optional)", text: $config.command)
                        .autocorrectionDisabled()
                }

                Section(
                    header: Text("Port Mappings"),
                    footer: Text("Format: HOST_PORT:CONTAINER_PORT, one per line")
                ) {
                    TextEditor(text: $config.ports)
                        .frame(height: 100)
                        .font(.body.monospaced())
                        .autocorrectionDisabled()
                }

                Section(
                    header: Text("Environment Variables"),
                    footer: Text("One per line, format: KEY=VALUE")
                ) {
                    TextEditor(text: $config.environment)
                        .frame(height: 100)
                        .font(.body.monospaced())
                        .autocorrectionDisabled()
                }

                Section {
                    Toggle("Start container immediately", isOn: $config.startImmediately)
                }
            }
            .navigationTitle("Create Container")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createContainer()
                    }
                    .disabled(config.image.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func createContainer() {
        Task {
            do {
                // Create container
                let containerId = try await docker.createContainer(config: config)

                // Start container if requested
                if config.startImmediately {
                    try await docker.startContainer(id: containerId)
                }

                // Reset form and refresh containers
                try await docker.loadContainers()
                dismiss()
            } catch {
                Logger.shared.error(error, context: "Failed to create container")
                errorMessage = "Failed to create container: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

// Extension to convert UI config to Docker API request
extension CreateContainerConfig {
    func toCreateRequest() -> ContainerCreateRequest {
        // Parse ports
        var portBindings: [String: [ContainerCreateRequest.HostConfig.PortBinding]]?
        if !ports.isEmpty {
            portBindings = [:]

            // Process each port mapping line
            for portMapping in ports.split(separator: "\n") {
                let parts = portMapping.split(separator: ":")
                if parts.count == 2 {
                    let hostPort = String(parts[0].trimmingCharacters(in: .whitespaces))
                    let containerPort = String(parts[1].trimmingCharacters(in: .whitespaces))

                    // Create port binding
                    let binding = ContainerCreateRequest.HostConfig.PortBinding(
                        hostIp: nil,
                        hostPort: hostPort
                    )

                    // Add to bindings
                    portBindings?["\(containerPort)/tcp"] = [binding]
                }
            }
        }

        // Parse environment variables
        var envVars: [String]?
        if !environment.isEmpty {
            envVars =
                environment
                .split(separator: "\n")
                .map { String($0.trimmingCharacters(in: .whitespaces)) }
                .filter { !$0.isEmpty }
        }

        // Parse command
        var cmd: [String]?
        if !command.isEmpty {
            // Split command respecting quotes
            cmd = command.split(
                separator: " ",
                omittingEmptySubsequences: true
            ).map { String($0) }
        }

        // Create host config
        let hostConfig = ContainerCreateRequest.HostConfig(
            binds: nil,
            portBindings: portBindings
        )

        // Create and return request
        return ContainerCreateRequest(
            image: image.trimmingCharacters(in: .whitespaces),
            cmd: cmd,
            env: envVars,
            volumes: nil,
            hostConfig: hostConfig,
            name: name.isEmpty ? nil : name.trimmingCharacters(in: .whitespaces)
        )
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var config = CreateContainerConfig(
            name: "test-container",
            image: "nginx:latest",
            command: "",
            environment: "NGINX_PORT=80",
            ports: "8080:80",
            startImmediately: true
        )

        var body: some View {
            CreateContainerSheet(config: $config)
        }
    }

    return PreviewWrapper()
}
