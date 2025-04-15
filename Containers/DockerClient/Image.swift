//
//  Image.swift
//  Containers
//
//  Created on 13/03/25.
//

import Foundation

// MARK: - Image Models

struct ImagePullProgress: Decodable, Identifiable {
    let status: String
    let progressDetail: ProgressDetail?
    let id: String?
    let progress: String?
    
    struct ProgressDetail: Decodable {
        let current: Int?
        let total: Int?
    }
    
    var progressPercent: Double {
        guard let detail = progressDetail, 
              let current = detail.current, 
              let total = detail.total, 
              total > 0 else {
            return 0
        }
        return Double(current) / Double(total)
    }
}

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
    
    // Added properties for image pulling
    var layerProgress: [String: Double] = [:]
    var layerStatus: [String: String] = [:]
    var completedLayers: Set<String> = []
    var allLayers: Set<String> = []
    var isPulling: Bool = false

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
    
    var progress: Double {
        // If we have no layers yet, return 0
        if allLayers.isEmpty { return 0.0 }
        
        // Calculate progress based on completed layers and in-progress layers
        var totalProgress = 0.0
        
        // Each completed layer counts as 100% progress
        totalProgress += Double(completedLayers.count)
        
        // Add the progress of layers still in progress
        for (layerId, layerProgress) in layerProgress {
            if !completedLayers.contains(layerId) {
                totalProgress += layerProgress
            }
        }
        
        // Divide by the total number of layers to get overall progress
        return totalProgress / Double(allLayers.count)
    }
    
    func getLayerStatuses() -> [LayerStatus] {
        return allLayers.map { layerId in
            let progress = layerProgress[layerId] ?? (completedLayers.contains(layerId) ? 1.0 : 0.0)
            let status = layerStatus[layerId] ?? "Waiting"
            return LayerStatus(id: layerId, status: status, progress: progress)
        }.sorted(by: { lhs, rhs in
            // Sort completed layers first, then by progress in descending order
            if completedLayers.contains(lhs.id) && !completedLayers.contains(rhs.id) {
                return true
            } else if !completedLayers.contains(lhs.id) && completedLayers.contains(rhs.id) {
                return false
            } else {
                return lhs.progress > rhs.progress
            }
        })
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
    /// - Returns: An AsyncThrowingStream of ImagePullProgress events for tracking the pull progress
    public func pullImage(name: String) throws -> AsyncThrowingStream<ImagePullProgress, Error> {
        // Format the URL-encoded image name to handle special characters
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let path = "\(apiBase)/images/create?fromImage=\(encodedName)"
        
        Logger.shared.debug("Pulling image: \(name)")
        
        return try performStreamingRequest(path: path, method: "POST")
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
