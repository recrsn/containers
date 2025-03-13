//
//  ContainerView.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 02/02/25.
//

import SwiftUI

struct ContainerView: View {
    @State private var containers: [Container] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var selectedContainer: Container?
    @State private var showingActionSheet = false
    @State private var showingCreateSheet = false
    @State private var newContainerConfig = CreateContainerConfig()
    
    private let dockerClient = DockerClient()
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading containers...")
                    .padding()
            } else {
                List(containers) { container in
                    ContainerRow(container: container)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedContainer = container
                            showingActionSheet = true
                        }
                }
                .overlay {
                    if containers.isEmpty && !isLoading {
                        ContentUnavailableView(
                            "No Containers",
                            systemImage: "square.dashed",
                            description: Text("No containers found. Pull an image and create a container to get started.")
                        )
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Create Container", action: { showingCreateSheet = true })
                    Button("Refresh", action: refreshContainers)
                } label: {
                    Label("Options", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateContainerSheet(config: $newContainerConfig, onSubmit: createContainer)
        }
        .confirmationDialog(
            "Container Actions",
            isPresented: $showingActionSheet,
            presenting: selectedContainer
        ) { container in
            Button("Start") {
                performContainerAction(container: container, action: .start)
            }
            
            Button("Stop") {
                performContainerAction(container: container, action: .stop)
            }
            
            Button("Restart") {
                performContainerAction(container: container, action: .restart)
            }
            
            Button("Pause") {
                performContainerAction(container: container, action: .pause)
            }
            
            Button("Unpause") {
                performContainerAction(container: container, action: .unpause)
            }
            
            Button("Remove", role: .destructive) {
                performContainerAction(container: container, action: .remove)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .task {
            refreshContainers()
        }
    }
    
    private func refreshContainers() {
        Task {
            await loadContainers()
        }
    }
    
    private func loadContainers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            containers = try await dockerClient.listContainers()
        } catch {
            errorMessage = "Failed to load containers: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    private enum ContainerAction {
        case start, stop, restart, pause, unpause, remove
    }
    
    private func performContainerAction(container: Container, action: ContainerAction) {
        Task {
            do {
                switch action {
                case .start:
                    try await dockerClient.startContainer(id: container.id)
                case .stop:
                    try await dockerClient.stopContainer(id: container.id)
                case .restart:
                    try await dockerClient.restartContainer(id: container.id)
                case .pause:
                    try await dockerClient.pauseContainer(id: container.id)
                case .unpause:
                    try await dockerClient.unpauseContainer(id: container.id)
                case .remove:
                    try await dockerClient.removeContainer(id: container.id)
                }
                
                // Refresh container list after action
                await loadContainers()
            } catch {
                errorMessage = "Failed to perform action: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func createContainer() {
        Task {
            do {
                // Convert CreateContainerConfig to ContainerCreateRequest
                let request = ContainerCreateRequest(
                    image: newContainerConfig.image,
                    cmd: newContainerConfig.command.isEmpty ? nil : newContainerConfig.command.components(separatedBy: " "),
                    env: newContainerConfig.environment.isEmpty ? nil : newContainerConfig.environment.components(separatedBy: "\n"),
                    volumes: nil,
                    hostConfig: newContainerConfig.ports.isEmpty ? nil : ContainerCreateRequest.HostConfig(
                        binds: nil,
                        portBindings: createPortBindings(from: newContainerConfig.ports)
                    ),
                    name: newContainerConfig.name.isEmpty ? nil : newContainerConfig.name
                )
                
                // Create container
                let containerId = try await dockerClient.createContainer(config: request)
                
                // Start container if requested
                if newContainerConfig.startImmediately {
                    try await dockerClient.startContainer(id: containerId)
                }
                
                // Reset form and refresh containers
                newContainerConfig = CreateContainerConfig()
                showingCreateSheet = false
                await loadContainers()
            } catch {
                errorMessage = "Failed to create container: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func createPortBindings(from portsString: String) -> [String: [ContainerCreateRequest.HostConfig.PortBinding]]? {
        let portMappings = portsString.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .compactMap { mapping -> (String, String)? in
                let parts = mapping.components(separatedBy: ":")
                guard parts.count == 2, 
                      let hostPort = Int(parts[0].trimmingCharacters(in: .whitespaces)),
                      let containerPort = Int(parts[1].trimmingCharacters(in: .whitespaces)) else {
                    return nil
                }
                return ("\(containerPort)/tcp", "\(hostPort)")
            }
        
        guard !portMappings.isEmpty else { return nil }
        
        var portBindings: [String: [ContainerCreateRequest.HostConfig.PortBinding]] = [:]
        
        for (containerPort, hostPort) in portMappings {
            portBindings[containerPort] = [
                ContainerCreateRequest.HostConfig.PortBinding(
                    hostIp: "0.0.0.0",
                    hostPort: hostPort
                )
            ]
        }
        
        return portBindings
    }
}

struct ContainerRow: View {
    let container: Container
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(container.displayName)
                    .font(.headline)
                
                Text(container.image)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            statusIndicator
                .padding(.trailing, 8)
        }
        .padding(.vertical, 4)
    }
    
    private var statusIndicator: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            
            Text(container.status)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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
}

struct CreateContainerConfig {
    var name: String = ""
    var image: String = ""
    var command: String = ""
    var environment: String = ""
    var ports: String = ""
    var startImmediately: Bool = true
}

struct CreateContainerSheet: View {
    @Binding var config: CreateContainerConfig
    @Environment(\.dismiss) private var dismiss
    var onSubmit: () -> Void
    
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
                
                Section(header: Text("Port Mappings"), footer: Text("Format: HOST_PORT:CONTAINER_PORT, one per line")) {
                    TextEditor(text: $config.ports)
                        .frame(height: 100)
                        .font(.body.monospaced())
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Environment Variables"), footer: Text("One per line, format: KEY=VALUE")) {
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
                        onSubmit()
                    }
                    .disabled(config.image.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
}

#Preview {
    ContainerView()
}
