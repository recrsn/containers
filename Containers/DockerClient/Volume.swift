//
//  Volume.swift
//  Containers
//
//  Created on 13/03/25.
//

import Foundation

// MARK: - Volume Models

struct Volume: Codable, Identifiable, Equatable, Hashable {
    let name: String
    let driver: String
    let mountpoint: String
    let createdAt: String?
    let status: [String: String]?
    let labels: [String: String]?
    let scope: String
    let options: [String: String]?
    let usageData: UsageData?

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case driver = "Driver"
        case mountpoint = "Mountpoint"
        case createdAt = "CreatedAt"
        case status = "Status"
        case labels = "Labels"
        case scope = "Scope"
        case options = "Options"
        case usageData = "UsageData"
    }

    var id: String { name }

    struct UsageData: Codable, Equatable, Hashable {
        let size: Int
        let refCount: Int

        enum CodingKeys: String, CodingKey {
            case size = "Size"
            case refCount = "RefCount"
        }
    }
}

// MARK: - Volume Operations

extension DockerClient {
    /// List all volumes
    /// - Returns: List of volumes
    public func listVolumes() async throws -> [Volume] {
        let path = "\(apiBase)/volumes"

        struct VolumesResponse: Codable {
            let volumes: [Volume]

            enum CodingKeys: String, CodingKey {
                case volumes = "Volumes"
            }
        }

        let response: VolumesResponse = try await performRequest(path: path, method: "GET")
        return response.volumes
    }

    /// Get detailed information about a volume
    /// - Parameter name: Volume name
    /// - Returns: Volume details
    public func inspectVolume(name: String) async throws -> Volume {
        let path = "\(apiBase)/volumes/\(name)"

        return try await performRequest(path: path, method: "GET")
    }

    /// Create a volume
    /// - Parameter name: Volume name
    /// - Parameter driver: Volume driver
    /// - Parameter labels: Volume labels
    /// - Returns: Created volume
    public func createVolume(
        name: String, driver: String = "local", labels: [String: String]? = nil
    )
        async throws -> Volume {
        let path = "\(apiBase)/volumes/create"

        struct VolumeCreateRequest: Codable {
            let name: String
            let driver: String
            let labels: [String: String]?

            enum CodingKeys: String, CodingKey {
                case name = "Name"
                case driver = "Driver"
                case labels = "Labels"
            }
        }

        let request = VolumeCreateRequest(name: name, driver: driver, labels: labels)

        return try await performRequest(
            path: path,
            method: "POST",
            body: request
        )
    }

    /// Remove a volume
    /// - Parameters:
    ///   - name: Volume name
    ///   - force: Force removal
    public func removeVolume(name: String, force: Bool = false) async throws {
        let path = "\(apiBase)/volumes/\(name)?force=\(force)"

        try await performRequestExpectNoContent(path: path, method: "DELETE")
    }
}
