//
//  Container.swift
//  Containers
//
//  Created on 13/03/25.
//

import Foundation

// MARK: Container Models

enum ContainerStatus: String, Codable {
    case created
    case running
    case paused
    case restarting
    case removing
    case exited
    case dead
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let status = try container.decode(String.self).lowercased()

        switch status {
        case "created": self = .created
        case "running": self = .running
        case "paused": self = .paused
        case "restarting": self = .restarting
        case "removing": self = .removing
        case "exited": self = .exited
        case "dead": self = .dead
        default: self = .unknown
        }
    }
}

struct Container: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let names: [String]
    let image: String
    let imageId: String
    let command: String
    let created: Int
    let status: String
    let state: ContainerStatus?
    let ports: [Port]?
    let labels: [String: String]?
    let sizeRw: Int?
    let sizeRootFs: Int?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case names = "Names"
        case image = "Image"
        case imageId = "ImageID"
        case command = "Command"
        case created = "Created"
        case status = "Status"
        case state = "State"
        case ports = "Ports"
        case labels = "Labels"
        case sizeRw = "SizeRW"
        case sizeRootFs = "SizeRootFS"
    }

    var displayName: String {
        if let name = names.first {
            return name.hasPrefix("/") ? String(name.dropFirst()) : name
        }
        return id.prefix(12).description
    }

    struct Port: Codable, Equatable, Hashable {
        let ip: String?
        let privatePort: Int
        let publicPort: Int?
        let type: String

        enum CodingKeys: String, CodingKey {
            case ip = "IP"
            case privatePort = "PrivatePort"
            case publicPort = "PublicPort"
            case type = "Type"
        }
    }
}

struct ContainerCreateRequest: Codable {
    let image: String
    let cmd: [String]?
    let env: [String]?
    let volumes: [String: [String: String]]?
    let hostConfig: HostConfig?
    let name: String?

    struct HostConfig: Codable {
        let binds: [String]?
        let portBindings: [String: [PortBinding]]?

        struct PortBinding: Codable {
            let hostIp: String?
            let hostPort: String?
        }
    }
}

struct ContainerCreateResponse: Codable {
    let id: String?
    let warnings: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case warnings = "Warnings"
    }
}

// MARK: - Container Operations

extension DockerClient {
    /// List all containers
    /// - Parameter all: Include stopped containers if true
    /// - Returns: List of containers
    public func listContainers(all: Bool = true) async throws -> [Container] {
        let path = "\(apiBase)/containers/json?all=\(all)"

        return try await performRequest(path: path, method: "GET")
    }

    /// Get detailed information about a container
    /// - Parameter containerId: Container ID or name
    /// - Returns: Container details
    public func inspectContainer(id: String) async throws -> Container {
        let path = "\(apiBase)/containers/\(id)/json"

        return try await performRequest(path: path, method: "GET")
    }

    /// Create a new container
    /// - Parameter config: Container configuration
    /// - Returns: ContainerCreateResponse with ID and warnings
    public func createContainer(config: ContainerCreateRequest) async throws -> ContainerCreateResponse {
        let path = "\(apiBase)/containers/create"
        let query = config.name != nil ? "?name=\(config.name!)" : ""

        return try await performRequest(
            path: path + query,
            method: "POST",
            body: config
        )
    }

    /// Start a container
    /// - Parameter containerId: Container ID or name
    public func startContainer(id: String) async throws {
        let path = "\(apiBase)/containers/\(id)/start"

        try await performRequestExpectNoContent(path: path, method: "POST")
    }

    /// Stop a container
    /// - Parameter containerId: Container ID or name
    /// - Parameter timeout: Seconds to wait before killing the container
    public func stopContainer(id: String, timeout: Int = 10) async throws {
        let path = "\(apiBase)/containers/\(id)/stop?t=\(timeout)"

        try await performRequestExpectNoContent(path: path, method: "POST")
    }

    /// Restart a container
    /// - Parameter containerId: Container ID or name
    /// - Parameter timeout: Seconds to wait before killing the container
    public func restartContainer(id: String, timeout: Int = 10) async throws {
        let path = "\(apiBase)/containers/\(id)/restart?t=\(timeout)"

        try await performRequestExpectNoContent(path: path, method: "POST")
    }

    /// Pause a container
    /// - Parameter containerId: Container ID or name
    public func pauseContainer(id: String) async throws {
        let path = "\(apiBase)/containers/\(id)/pause"

        try await performRequestExpectNoContent(path: path, method: "POST")
    }

    /// Unpause a container
    /// - Parameter containerId: Container ID or name
    public func unpauseContainer(id: String) async throws {
        let path = "\(apiBase)/containers/\(id)/unpause"

        try await performRequestExpectNoContent(path: path, method: "POST")
    }

    /// Remove a container
    /// - Parameters:
    ///   - containerId: Container ID or name
    ///   - force: Force removal even if running
    ///   - removeVolumes: Remove associated volumes
    public func removeContainer(id: String, force: Bool = false, removeVolumes: Bool = false)
        async throws {
        let path = "\(apiBase)/containers/\(id)?force=\(force)&v=\(removeVolumes)"

        try await performRequestExpectNoContent(path: path, method: "DELETE")
    }
}
