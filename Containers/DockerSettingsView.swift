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
    var path: String
    let description: String
    let isCustom: Bool

    init(name: String, path: String, description: String, isCustom: Bool = false) {
        self.name = name
        self.path = path
        self.description = description
        self.isCustom = isCustom
    }

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
    @Published var customSocket: DockerSocket

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
        ),
        DockerSocket(
            name: "Custom",
            path: "",
            description: "Specify a custom Docker socket path",
            isCustom: true
        )
    ]

    init() {
        // Load saved socket path or use default
        let socketPath = UserDefaults.standard.string(forKey: "dockerSocketPath") ?? "/var/run/docker.sock"
        self.socketPath = socketPath
        self.dockerClient = DockerClient(socketPath: socketPath)
        self.customSocket = DockerSocket(
            name: "Custom",
            path: socketPath,
            description: "Custom Docker socket path",
            isCustom: true
        )
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
    @State private var testConnectionResult: String?
    @State private var isTestingConnection = false

    var body: some View {
        Form {
            Section {
                Picker("Select Docker Installation", selection: $selectedSocket) {
                    ForEach(DockerSettings.predefinedSockets) { socket in
                        Text(socket.name).tag(Optional(socket))
                    }
                }
                .onChange(of: selectedSocket) { newValue in
                    if let socket = newValue {
                        if socket.isCustom {
                            // For custom option, just update the UI elements
                            customPath = settings.customSocket.path
                        } else {
                            // For predefined options, apply the path immediately
                            let resolvedPath = settings.resolvePath(socket.path)
                            settings.socketPath = resolvedPath
                            customPath = resolvedPath
                            testConnection()
                        }
                    }
                }

                if let socket = selectedSocket, !socket.isCustom {
                    Text(socket.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let socket = selectedSocket, socket.isCustom {
                    TextField("Custom Socket Path", text: $customPath)
                        .onSubmit {
                            if !customPath.isEmpty {
                                let resolvedPath = settings.resolvePath(customPath)
                                settings.socketPath = resolvedPath
                                settings.customSocket.path = customPath
                            }
                        }

                    Button("Apply Custom Path") {
                        if !customPath.isEmpty {
                            let resolvedPath = settings.resolvePath(customPath)
                            settings.socketPath = resolvedPath
                            settings.customSocket.path = customPath
                            testConnection()
                        }
                    }
                    .disabled(customPath.isEmpty)

                    Text(socket.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
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
        .padding()
        .frame(width: 500)
        .onAppear {
            // Set initial values
            customPath = settings.socketPath

            // Find if the current path matches any predefined socket
            if let match = DockerSettings.predefinedSockets.filter({ !$0.isCustom }).first(where: {
                settings.resolvePath($0.path) == settings.socketPath
            }) {
                selectedSocket = match
            } else {
                // Use custom socket
                settings.customSocket.path = settings.socketPath
                selectedSocket = DockerSettings.predefinedSockets.last // The custom option
            }
        }
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
