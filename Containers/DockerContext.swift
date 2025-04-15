//
//  DockerContext.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 11/04/25.
//

import Foundation
import SwiftUI
import os.log

struct Loadable<Value> {
    var value: Value?
    var isLoading: Bool = false

    mutating func load(_ body: () async throws -> Value) async rethrows -> Value {
        self.isLoading = true
        defer { self.isLoading = false }
        return try await body()
    }
}

@MainActor
@Observable
final class DockerContext {
    @ObservationIgnored private var client: DockerClientProtocol

    var isConnected: Bool = false
    var connectionError: Error?
    var socketPath: String

    var isLoading: Bool = false
    var systemInfo: DockerInfo?

    var containerLoading: Bool = false
    var containers: [Container] = []

    var imageLoading: Bool = false
    
    var downloadedImages: [ContainerImage] = []
    var pullingImages: [String: ContainerImage] = [:]
    
    var images: [ContainerImage] {
        // Combine and sort both pulling and downloaded images by creation time (newest first)
        let pullingArray = Array(pullingImages.values).sorted(by: { $0.created > $1.created })
        let sortedDownloaded = downloadedImages.sorted(by: { $0.created > $1.created })
        return pullingArray + sortedDownloaded
    }

    var networkLoading: Bool = false
    var networks: [Network] = []

    var volumeLoading: Bool = false
    var volumes: [Volume] = []

    init(client: DockerClientProtocol? = nil, socketPath: String = "/var/run/docker.sock") {
        self.socketPath = socketPath
        self.client = client ?? DockerClient(socketPath: socketPath)
    }

    // MARK: - Connection Management

    func connect() async throws {
        self.isLoading = true
        defer { isLoading = false }

        do {
            // Test connection by loading system info
            self.systemInfo = try await client.info()
            self.isConnected = true
            self.isLoading = false
        } catch {
            Logger.shared.error(error, context: "Docker connection failed")
            self.isConnected = false
            self.isLoading = false
            throw error
        }
    }

    func reconnect(socketPath: String) async throws {
        self.socketPath = socketPath
        self.client = DockerClient(socketPath: socketPath)
        try await connect()
    }

    // MARK: - Data Loading Methods
    func loadContainers() async throws {
        guard isConnected else { return }

        containerLoading = true
        defer { containerLoading = false }

        do {
            containers = try await client.listContainers(all: true)
        } catch {
            Logger.shared.error(error, context: "Failed to load containers")
            connectionError = error
            throw error
        }
    }

    func loadImages() async throws {
        guard isConnected else { return }

        imageLoading = true
        defer { imageLoading = false }

        do {
            downloadedImages = try await client.listImages(all: false)
        } catch {
            Logger.shared.error(error, context: "Failed to load images")
            connectionError = error
            throw error
        }
    }

    func loadNetworks() async throws {
        guard isConnected else { return }

        networkLoading = true
        defer { networkLoading = false }

        do {
            networks = try await client.listNetworks()
        } catch {
            Logger.shared.error(error, context: "Failed to load networks")
            connectionError = error
            throw error
        }
    }

    func loadVolumes() async throws {
        guard isConnected else { return }

        volumeLoading = true
        defer { volumeLoading = false }

        do {
            volumes = try await client.listVolumes()
        } catch {
            Logger.shared.error(error, context: "Failed to load volumes")
            connectionError = error
            throw error
        }
    }

    func refreshAll() async throws {
        guard isConnected else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await (
                self.connect(),
                self.loadContainers(),
                self.loadImages(),
                self.loadNetworks(),
                self.loadVolumes()
            )
        } catch {
            Logger.shared.error(error, context: "Failed to refresh all data")
            connectionError = error
            throw error
        }
    }

    func loadSystemInfo() async throws {
        guard isConnected else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            systemInfo = try await client.info()
        } catch {
            Logger.shared.error(error, context: "Failed to load system info")
            connectionError = error
            throw error
        }
    }

    // MARK: - Container Operations

    func createContainer(config: CreateContainerConfig) async throws -> ContainerCreateResponse {
        containerLoading = true
        defer { containerLoading = false }

        do {
            let request = config.toCreateRequest()
            Logger.shared.debug("Creating container with image: \(request.image)")
            
            // Log more details about the request
            if let name = request.name {
                Logger.shared.debug("Container name: \(name)")
            }
            if let envVars = request.env, !envVars.isEmpty {
                Logger.shared.debug("Environment variables: \(envVars.joined(separator: ", "))")
            }
            if let portBindings = request.hostConfig?.portBindings, !portBindings.isEmpty {
                let bindingInfo = portBindings.map { key, value in
                    return "\(key): \(value.map { "\($0.hostPort ?? "nil")" }.joined(separator: ", "))"
                }.joined(separator: "; ")
                Logger.shared.debug("Port bindings: \(bindingInfo)")
            }
            
            let response = try await client.createContainer(config: request)
            
            // Log any warnings from the Docker API
            if let warnings = response.warnings, !warnings.isEmpty {
                Logger.shared.warning("Container created with warnings: \(warnings.joined(separator: ", "))")
            }
            
            return response
        } catch {
            // Log error with context - DockerError will now have a much better description
            Logger.shared.error(error, context: "Failed to create container")
            connectionError = error
            throw error
        }
    }

    func startContainer(id: String) async throws {
        guard isConnected else { return }

        containerLoading = true
        defer { containerLoading = false }

        do {
            try await client.startContainer(id: id)
            try await loadContainers()
        } catch {
            Logger.shared.error(error, context: "Failed to start container \(id)")
            connectionError = error
            throw error
        }
    }

    func stopContainer(id: String) async throws {
        guard isConnected else { return }

        containerLoading = true
        defer { containerLoading = false }

        do {
            try await client.stopContainer(id: id, timeout: 30000)
            try await loadContainers()
        } catch {
            Logger.shared.error(error, context: "Failed to stop container \(id)")
            connectionError = error
            throw error
        }
    }

    func restartContainer(id: String) async throws {
        guard isConnected else { return }

        containerLoading = true
        defer { containerLoading = false }

        do {
            try await client.restartContainer(id: id, timeout: 30000)
            try await loadContainers()
        } catch {
            Logger.shared.error(error, context: "Failed to restart container \(id)")
            connectionError = error
            throw error
        }
    }

    func pauseContainer(id: String) async throws {
        guard isConnected else { return }

        containerLoading = true
        defer { containerLoading = false }

        do {
            try await client.pauseContainer(id: id)
            try await loadContainers()
        } catch {
            Logger.shared.error(error, context: "Failed to pause container \(id)")
            connectionError = error
            throw error
        }
    }

    func unpauseContainer(id: String) async throws {
        guard isConnected else { return }

        containerLoading = true
        defer { containerLoading = false }

        do {
            try await client.unpauseContainer(id: id)
            try await loadContainers()
        } catch {
            Logger.shared.error(error, context: "Failed to unpause container \(id)")
            connectionError = error
            throw error
        }
    }

    func removeContainer(id: String, force: Bool = false) async throws {
        guard isConnected else { return }

        containerLoading = true
        defer { containerLoading = false }

        do {
            try await client.removeContainer(id: id, force: force, removeVolumes: false)
            try await loadContainers()
        } catch {
            Logger.shared.error(error, context: "Failed to remove container \(id)")
            connectionError = error
            throw error
        }
    }

    func pullImage(name: String) async throws {
        guard isConnected else { return }

        imageLoading = true
        
        // Create a new ContainerImage instance for the image being pulled
        var pullingImage = ContainerImage(
            id: "pulling_\(name)",  // Temporary ID
            parentId: "",
            repoTags: [name],
            repoDigests: nil,
            created: Int(Date().timeIntervalSince1970),
            size: 0,
            sharedSize: 0,
            labels: nil,
            containers: 0
        )
        
        // Mark this as a pulling image
        pullingImage.isPulling = true
        
        // Add to the pulling images dictionary
        pullingImages[name] = pullingImage
        
        defer { 
            imageLoading = false
            // Remove the image from pullingImages when done
            pullingImages.removeValue(forKey: name)
        }

        do {
            let stream = try client.pullImage(name: name)
            
            for try await progress in stream {
                if let id = progress.id {
                    // Add this layer to the set of all layers
                    pullingImages[name]?.allLayers.insert(id)
                    
                    // Always update the status for this layer
                    pullingImages[name]?.layerStatus[id] = progress.status
                    
                    // Check if this is a layer completion status
                    if progress.status.contains("Download complete") || 
                       progress.status.contains("Pull complete") ||
                       progress.status.contains("Already exists") {
                        // Mark this layer as completed
                        pullingImages[name]?.completedLayers.insert(id)
                        // Remove from in-progress since it's done
                        pullingImages[name]?.layerProgress.removeValue(forKey: id)
                    } else if progress.progressDetail?.total != nil {
                        // This is a layer in progress
                        pullingImages[name]?.layerProgress[id] = progress.progressPercent
                    }
                    
                    // Log the progress for debugging
                    Logger.shared.debug("Image: \(name), Layer: \(id), Status: \(progress.status), Progress: \(String(describing: progress.progress))")
                }
            }
            
            // Once complete, refresh the images list
            try await loadImages()
        } catch {
            Logger.shared.error(error, context: "Failed to pull image \(name)")
            connectionError = error
            throw error
        }
    }

    func removeImage(id: String, force: Bool = false) async throws {
        guard isConnected else { return }

        imageLoading = true
        defer { imageLoading = false }

        do {
            try await client.removeImage(id: id, force: force, pruneChildren: false)
            try await loadImages()
        } catch {
            Logger.shared.error(error, context: "Failed to remove image \(id)")
            connectionError = error
            throw error
        }
    }

    func createNetwork(name: String, driver: String = "bridge") async throws {
        guard isConnected else { return }

        networkLoading = true
        defer { networkLoading = false }

        do {
            _ = try await client.createNetwork(
                name: name, driver: driver, subnet: nil, gateway: nil, labels: nil)
            try await loadNetworks()
        } catch {
            Logger.shared.error(error, context: "Failed to create network \(name)")
            connectionError = error
            throw error
        }
    }

    func removeNetwork(id: String) async throws {
        guard isConnected else { return }

        networkLoading = true
        defer { networkLoading = false }

        do {
            try await client.removeNetwork(id: id)
            try await loadNetworks()
        } catch {
            Logger.shared.error(error, context: "Failed to remove network \(id)")
            connectionError = error
            throw error
        }
    }

    func createVolume(name: String) async throws {
        guard isConnected else { return }

        volumeLoading = true
        defer { volumeLoading = false }

        do {
            _ = try await client.createVolume(name: name, driver: "local", labels: [:])
            try await loadVolumes()
        } catch {
            Logger.shared.error(error, context: "Failed to create volume \(name)")
            connectionError = error
            throw error
        }
    }

    func removeVolume(name: String) async throws {
        guard isConnected else { return }

        volumeLoading = true
        defer { volumeLoading = false }

        do {
            try await client.removeVolume(name: name, force: false)
            try await loadVolumes()
        } catch {
            Logger.shared.error(error, context: "Failed to remove volume \(name)")
            connectionError = error
            throw error
        }
    }
}

extension DockerContext {
    static var preview: DockerContext {
        let previewClient = PreviewDockerClient()
        let context = DockerContext(client: previewClient)
        context.isConnected = true
        context.systemInfo = PreviewData.dockerInfo
        context.containers = [PreviewData.container]
        context.downloadedImages = [PreviewData.image]
        context.networks = [PreviewData.network]
        context.volumes = [PreviewData.volume]
        return context
    }
}
