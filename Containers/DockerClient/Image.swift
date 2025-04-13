//
//  Image.swift
//  Containers
//
//  Created on 13/03/25.
//

import Foundation

// MARK: - Image Models

struct ContainerImage: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let parentId: String
    let repoTags: [String]?
    let repoDigests: [String]?
    let created: Int
    let size: Int
    let sharedSize: Int
    let labels: [String: String]?
    let containers: Int

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case parentId = "ParentId"
        case repoTags = "RepoTags"
        case repoDigests = "RepoDigests"
        case created = "Created"
        case size = "Size"
        case sharedSize = "SharedSize"
        case labels = "Labels"
        case containers = "Containers"
    }

    var displayName: String {
        if let tag = repoTags?.first, tag != "<none>:<none>" {
            return tag
        }
        return id.prefix(12).description
    }

    var shortId: String {
        return id.hasPrefix("sha256:")
            ? String(id.dropFirst(7).prefix(12)) : id.prefix(12).description
    }
}

// MARK: - Image Operations

extension DockerClient {
    /// List all images
    /// - Parameter all: Include intermediate images if true
    /// - Returns: List of images
    public func listImages(all: Bool = false) async throws -> [ContainerImage] {
        let path = "\(apiBase)/images/json?all=\(all)"

        return try await performRequest(path: path, method: "GET")
    }

    /// Get detailed information about an image
    /// - Parameter imageId: Image ID or name
    /// - Returns: Image details
    public func inspectImage(id: String) async throws -> ContainerImage {
        let path = "\(apiBase)/images/\(id)/json"

        return try await performRequest(path: path, method: "GET")
    }

    /// Pull an image from a registry
    /// - Parameter name: Image name to pull (e.g. "ubuntu:latest")
    public func pullImage(name: String) async throws {
        let path = "\(apiBase)/images/create?fromImage=\(name)"

        try await performRequestExpectNoContent(path: path, method: "POST")
    }

    /// Remove an image
    /// - Parameters:
    ///   - imageId: Image ID or name
    ///   - force: Force removal of the image
    ///   - pruneChildren: Remove untagged parents
    public func removeImage(id: String, force: Bool = false, pruneChildren: Bool = false)
        async throws {
        let path = "\(apiBase)/images/\(id)?force=\(force)&prune=\(pruneChildren)"

        try await performRequestExpectNoContent(path: path, method: "DELETE")
    }
}
