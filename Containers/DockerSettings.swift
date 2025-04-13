//
//  DockerSettings.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 16/03/25.
//

import SwiftUI

@MainActor
@Observable
class DockerSettings {
    var connections: [DockerSocket] = []

    private let fileManager = FileManager.default

    private var connectionsFileURL: URL {
        let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
        let bundleId = Bundle.main.bundleIdentifier ?? "com.amitosh.Containers"
        let containerDir = appSupportDir.appendingPathComponent(bundleId, isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: containerDir.path) {
            try? fileManager.createDirectory(at: containerDir, withIntermediateDirectories: true)
        }

        return containerDir.appendingPathComponent("connections.json")
    }

    func addConnection(name: String, socketType: DockerSocket.SocketType, customPath: String = "")
        async {
        let path = socketType == .custom ? customPath : socketType.defaultPath
        let newConnection = DockerSocket(
            name: name,
            path: path,
            description: socketType.description,
            socketType: socketType
        )

        connections.append(newConnection)
        await saveConnections()
    }

    func updateConnection(_ connection: DockerSocket) async {
        if let index = connections.firstIndex(where: { $0.id == connection.id }) {
            connections[index] = connection
            await saveConnections()
        }
    }

    func removeConnection(id: UUID) async {
        connections.removeAll(where: { $0.id == id })
        await saveConnections()
    }

    private func loadConnections() async {
        if fileManager.fileExists(atPath: connectionsFileURL.path) {
            do {
                let data = try Data(contentsOf: connectionsFileURL)
                connections = try JSONDecoder().decode([DockerSocket].self, from: data)
            } catch {
                Logger.shared.error(error, context: "Error loading connections")
                connections = []
            }
        }
    }

    private func saveConnections() async {
        do {
            let data = try JSONEncoder().encode(connections)
            try data.write(to: connectionsFileURL)
        } catch {
            Logger.shared.error(error, context: "Error saving connections")
        }
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
