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
    @State private var isCreating = false
    @State private var successMessage: String?
    @State private var showSuccess = false

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
                
                if isCreating {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Creating container...")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Create Container")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isCreating)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isCreating ? "Creating..." : "Create") {
                        createContainer()
                    }
                    .disabled(config.image.isEmpty || isCreating)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
        .alert("Container Creation Failed", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
                .multilineTextAlignment(.leading)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(successMessage ?? "Container created successfully")
                .multilineTextAlignment(.leading)
        }
        .disabled(isCreating)
    }

    private func createContainer() {
        isCreating = true
        
        Task {
            do {
                // Create container
                let response = try await docker.createContainer(config: config)
                
                guard let containerId = response.id else {
                    throw DockerError.decodingError("Missing container ID in response")
                }
                
                let containerName = config.name.isEmpty ? String(containerId.prefix(12)) : config.name
                
                // Display warnings if any
                if let warnings = response.warnings, !warnings.isEmpty {
                    let warningText = warnings.joined(separator: "\n- ")
                    successMessage = "Container '\(containerName)' created with warnings:\n- \(warningText)"
                    if config.startImmediately {
                        successMessage! += "\n\nContainer will be started."
                    }
                }
                else {
                    successMessage = config.startImmediately 
                        ? "Container '\(containerName)' created successfully" 
                        : "Container '\(containerName)' created successfully"
                }

                // Start container if requested
                if config.startImmediately {
                    try await docker.startContainer(id: containerId)
                    if response.warnings?.isEmpty ?? true {
                        successMessage = "Container '\(containerName)' created and started successfully"
                    }
                }

                // Reset form and refresh containers
                try await docker.loadContainers()
                
                isCreating = false
                showSuccess = true
            } catch {
                // Log the error with context
                Logger.shared.error(error, context: "Failed to create container")
                
                // Use error.localizedDescription which will now use our custom descriptions
                // for DockerError through the LocalizedError protocol
                errorMessage = error.localizedDescription
                
                // Add additional debug logging for non-Docker errors
                if !(error is DockerError), let nsError = error as NSError? {
                    Logger.shared.error("Error domain: \(nsError.domain), code: \(nsError.code)")
                    if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
                        Logger.shared.error("Underlying error: \(underlyingError)")
                    }
                }
                
                isCreating = false
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
                    
                    // Log port binding for debugging
                    Logger.shared.debug("Processing port mapping: host \(hostPort) -> container \(containerPort)")

                    // Create port binding
                    let binding = ContainerCreateRequest.HostConfig.PortBinding(
                        hostIp: nil,
                        hostPort: hostPort
                    )

                    // Add to bindings - ports need to be in format "port/tcp" or "port/udp"
                    let containerPortWithProtocol = containerPort.contains("/") ? containerPort : "\(containerPort)/tcp"
                    portBindings?[containerPortWithProtocol] = [binding]
                    
                    // Log the final binding format being used
                    Logger.shared.debug("Added port binding: \(containerPortWithProtocol) -> \(hostPort)")
                } else {
                    // Log warning for invalid port format
                    Logger.shared.warning("Invalid port mapping format: \(portMapping), expected HOST:CONTAINER")
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
