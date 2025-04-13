//
//  ConnectionEditorView.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 12/04/25.
//

import SwiftUI

struct ConnectionEditorView: View {
    @Environment(DockerSettings.self) private var settings: DockerSettings
    @Environment(DockerContext.self) private var connectionContext: DockerContext
    @Binding var isPresented: Bool

    var existingConnection: DockerSocket?
    var isEditMode: Bool

    @State private var name: String = ""
    @State private var socketType: DockerSocket.SocketType = .dockerDesktop
    @State private var customPath: String = ""
    @State private var testConnectionResult: String?
    @State private var isTestingConnection: Bool = false

    init(isPresented: Binding<Bool>, existingConnection: DockerSocket? = nil) {
        self._isPresented = isPresented
        self.existingConnection = existingConnection
        self.isEditMode = existingConnection != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(isEditMode ? "Edit Connection" : "Add New Connection")
                .font(.headline)

            Form {
                TextField("Connection Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Picker("Connection Type", selection: $socketType) {
                    ForEach(DockerSocket.SocketType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(DefaultPickerStyle())
                .onChange(of: socketType) { _ in
                    if socketType != .custom {
                        customPath = socketType.defaultPath
                    }
                }

                TextField("Socket Path", text: $customPath)
                    .disabled(socketType != .custom)
            }

            HStack {
                Button(action: testConnection) {
                    HStack {
                        Text("Test connection")
                        if isTestingConnection {
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .disabled(isTestingConnection)

                if let result = testConnectionResult {
                    GroupBox {
                        HStack {
                            Text(result)
                                .foregroundColor(result.contains("Connected") ? .green : .red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button(isEditMode ? "Save Changes" : "Add Connection") {
                    if isFormValid() {
                        let path = socketType == .custom ? customPath : socketType.defaultPath

                        if isEditMode, let connection = existingConnection {
                            // Update existing connection
                            let updatedConnection = DockerSocket(
                                id: connection.id,
                                name: name,
                                path: path,
                                description: socketType.description,
                                socketType: socketType
                            )
                            Task {
                                await settings.updateConnection(updatedConnection)
                            }
                        } else {
                            // Add new connection
                            Task {
                                await settings.addConnection(
                                    name: name,
                                    socketType: socketType,
                                    customPath: socketType == .custom
                                        ? customPath : socketType.defaultPath
                                )
                            }
                        }
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!isFormValid())
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            if let connection = existingConnection {
                // Edit mode - populate with existing values
                name = connection.name
                socketType = connection.socketType
                customPath = connection.socketType == .custom ? connection.path : ""
            } else {
                // Add mode - set default values
                name = "New Connection"
                socketType = .dockerDesktop
                customPath = socketType.defaultPath
            }
        }
    }

    private func isFormValid() -> Bool {
        !name.isEmpty && (socketType != .custom || !customPath.isEmpty)
    }

    func testConnection() {
        let socketPath = socketType == .custom ? customPath : socketType.defaultPath
        isTestingConnection = true
        testConnectionResult = nil

        Task {
            do {
                let tempClient = DockerClient(socketPath: socketPath)
                let containers = try await tempClient.listContainers(all: true)
                await MainActor.run {
                    testConnectionResult =
                        "Connected successfully. Found \(containers.count) containers."
                    isTestingConnection = false
                }
            } catch {
                Logger.shared.error(error, context: "Test connection failed")
                await MainActor.run {
                    testConnectionResult = "Connection failed: \(error.localizedDescription)"
                    isTestingConnection = false
                }
            }
        }
    }
}

#Preview("Add Connection Sheet") {
    ConnectionEditorView(
        isPresented: .constant(true),
        existingConnection: nil
    )
    .environment(DockerSettings())
    .environment(DockerContext.preview)
}

#Preview("Edit Connection Sheet") {
    let socket = DockerSocket(
        name: "Test Connection",
        path: "/var/run/docker.sock",
        description: "Test description",
        socketType: .dockerDesktop
    )

    ConnectionEditorView(
        isPresented: .constant(true),
        existingConnection: socket
    )
    .environment(DockerSettings())
    .environment(DockerContext.preview)
}
