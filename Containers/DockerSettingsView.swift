//
//  DockerSettingsView.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 13/03/25.
//

import SwiftUI

struct DockerSocket: Identifiable, Hashable {
    var id: String { path }
    let name: String
    let path: String
    let description: String
    
    static func == (lhs: DockerSocket, rhs: DockerSocket) -> Bool {
        return lhs.path == rhs.path
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }
}

class DockerSettings: ObservableObject {
    @Published var socketPath: String {
        didSet {
            UserDefaults.standard.set(socketPath, forKey: "dockerSocketPath")
            dockerClient = DockerClient(socketPath: socketPath)
        }
    }
    
    @Published var dockerClient: DockerClient
    
    static let predefinedSockets: [DockerSocket] = [
        DockerSocket(
            name: "Docker Desktop",
            path: "/var/run/docker.sock",
            description: "Default Docker Desktop socket path"
        ),
        DockerSocket(
            name: "Colima",
            path: "~/.colima/default/docker.sock",
            description: "Default Colima socket path"
        ),
        DockerSocket(
            name: "Podman",
            path: "~/.local/share/containers/podman/machine/podman-machine-default/podman.sock",
            description: "Default Podman machine socket path"
        )
    ]
    
    init() {
        // Load saved socket path or use default
        let socketPath = UserDefaults.standard.string(forKey: "dockerSocketPath") ?? "/var/run/docker.sock"
        self.socketPath = socketPath
        self.dockerClient = DockerClient(socketPath: socketPath)
    }
    
    // Resolve path with tilde expansion
    func resolvePath(_ path: String) -> String {
        if path.hasPrefix("~") {
            let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
            return path.replacingOccurrences(of: "~", with: homeDirectory)
        }
        return path
    }
}

struct DockerSettingsView: View {
    @EnvironmentObject private var settings: DockerSettings
    @State private var customPath: String = ""
    @State private var selectedSocket: DockerSocket?
    @State private var isCustomPath = false
    @State private var testConnectionResult: String?
    @State private var isTestingConnection = false
    
    var body: some View {
        TabView {
            Form {
                Section {
                    Picker("Socket Configuration", selection: $isCustomPath) {
                        Text("Predefined").tag(false)
                        Text("Custom").tag(true)
                    }
                    .pickerStyle(.segmented)
                    
                    if isCustomPath {
                        TextField("Custom Socket Path", text: $customPath)
                            .onSubmit {
                                if !customPath.isEmpty {
                                    settings.socketPath = settings.resolvePath(customPath)
                                }
                            }
                        
                        Button("Apply Custom Path") {
                            if !customPath.isEmpty {
                                settings.socketPath = settings.resolvePath(customPath)
                                testConnection()
                            }
                        }
                        .disabled(customPath.isEmpty)
                    } else {
                        Picker("Select Docker Installation", selection: $selectedSocket) {
                            ForEach(DockerSettings.predefinedSockets) { socket in
                                Text(socket.name).tag(Optional(socket))
                            }
                        }
                        .onChange(of: selectedSocket) { newValue in
                            if let socket = newValue {
                                let resolvedPath = settings.resolvePath(socket.path)
                                settings.socketPath = resolvedPath
                                customPath = resolvedPath
                                testConnection()
                            }
                        }
                        
                        if let selectedSocket = selectedSocket {
                            Text(selectedSocket.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("Current Socket Path: \(settings.socketPath)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Docker Socket Connection")
                }
                
                Section {
                    Button(action: testConnection) {
                        HStack {
                            Text("Test Connection")
                            if isTestingConnection {
                                Spacer()
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    }
                    .disabled(isTestingConnection)
                    
                    if let result = testConnectionResult {
                        Text(result)
                            .foregroundColor(result.contains("Connected") ? .green : .red)
                    }
                }
            }
            .tabItem {
                Label("Connection", systemImage: "network")
            }
            .onAppear {
                // Set initial values
                customPath = settings.socketPath
                
                // Find if the current path matches any predefined socket
                if let match = DockerSettings.predefinedSockets.first(where: { 
                    settings.resolvePath($0.path) == settings.socketPath 
                }) {
                    selectedSocket = match
                    isCustomPath = false
                } else {
                    isCustomPath = true
                }
            }
            
            Form {
                Text("Docker Socket Information")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                Text("Configure the connection to your Docker daemon by selecting a predefined socket path or specifying a custom path.")
                
                Divider()
                    .padding(.vertical)
                
                Text("Predefined Options:")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(DockerSettings.predefinedSockets) { socket in
                        VStack(alignment: .leading) {
                            Text(socket.name)
                                .font(.subheadline)
                                .bold()
                            Text(socket.path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(socket.description)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 5)
                    }
                }
            }
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .padding()
        .frame(width: 500)
    }
    
    private func testConnection() {
        isTestingConnection = true
        testConnectionResult = nil
        
        Task {
            do {
                // Try to get a list of containers as a test
                let containers = try await settings.dockerClient.listContainers()
                await MainActor.run {
                    testConnectionResult = "Connected successfully. Found \(containers.count) containers."
                    isTestingConnection = false
                }
            } catch {
                await MainActor.run {
                    testConnectionResult = "Connection failed: \(error.localizedDescription)"
                    isTestingConnection = false
                }
            }
        }
    }
}

#Preview {
    DockerSettingsView()
        .environmentObject(DockerSettings())
}
