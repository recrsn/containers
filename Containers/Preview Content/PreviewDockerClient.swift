//
//  PreviewDockerClient.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 11/04/25.
//

import Foundation

actor PreviewDockerClient: DockerClientProtocol {
    // In-memory state
    private var containers: [Container]
    private var images: [ContainerImage]
    private var networks: [Network]
    private var volumes: [Volume]
    private let dockerInfo: DockerInfo

    init() {
        // Initialize with preview data
        self.containers = [PreviewData.container]
        self.images = [PreviewData.image]
        self.networks = [PreviewData.network]
        self.volumes = []
        self.dockerInfo = PreviewData.dockerInfo
    }

    // MARK: - System Operations

    func info() async throws -> DockerInfo {
        return dockerInfo
    }

    // MARK: - Container Operations

    func listContainers(all: Bool = true) async throws -> [Container] {
        if all {
            return containers
        } else {
            return containers.filter { $0.state == .running }
        }
    }

    func inspectContainer(id: String) async throws -> Container {
        guard
            let container = containers.first(where: {
                $0.id == id || $0.names.contains("/\(id)") || $0.names.contains(id)
            })
        else {
            throw DockerError.decodingError("Container not found")
        }
        return container
    }

    func createContainer(config: ContainerCreateRequest) async throws -> String {
        let id = "mock_\(UUID().uuidString.prefix(12))"

        let names = [config.name.map { "/\($0)" } ?? "/mock_container"].compactMap { $0 }

        let newContainer = Container(
            id: id,
            names: names,
            image: config.image,
            imageId: "sha256:\(UUID().uuidString)",
            command: config.cmd?.joined(separator: " ") ?? "mock command",
            created: Int(Date().timeIntervalSince1970),
            status: "Created",
            state: .created,
            ports: [],
            labels: [:],
            sizeRw: 0,
            sizeRootFs: 0
        )

        containers.append(newContainer)
        return id
    }

    func startContainer(id: String) async throws {
        guard let index = containers.firstIndex(where: { $0.id == id }) else {
            throw DockerError.decodingError("Container not found")
        }

        let container = containers[index]
        containers.remove(at: index)

        // Update container state
        let updatedContainer = Container(
            id: container.id,
            names: container.names,
            image: container.image,
            imageId: container.imageId,
            command: container.command,
            created: container.created,
            status: "Up 1 second",
            state: .running,
            ports: container.ports,
            labels: container.labels,
            sizeRw: container.sizeRw,
            sizeRootFs: container.sizeRootFs
        )

        containers.append(updatedContainer)
    }

    func stopContainer(id: String, timeout: Int = 10) async throws {
        guard let index = containers.firstIndex(where: { $0.id == id }) else {
            throw DockerError.decodingError("Container not found")
        }

        let container = containers[index]
        containers.remove(at: index)

        // Update container state
        let updatedContainer = Container(
            id: container.id,
            names: container.names,
            image: container.image,
            imageId: container.imageId,
            command: container.command,
            created: container.created,
            status: "Exited (0) 1 second ago",
            state: .exited,
            ports: container.ports,
            labels: container.labels,
            sizeRw: container.sizeRw,
            sizeRootFs: container.sizeRootFs
        )

        containers.append(updatedContainer)
    }

    func restartContainer(id: String, timeout: Int = 10) async throws {
        try await stopContainer(id: id, timeout: timeout)
        try await startContainer(id: id)
    }

    func pauseContainer(id: String) async throws {
        guard let index = containers.firstIndex(where: { $0.id == id }) else {
            throw DockerError.decodingError("Container not found")
        }

        let container = containers[index]
        containers.remove(at: index)

        // Update container state
        let updatedContainer = Container(
            id: container.id,
            names: container.names,
            image: container.image,
            imageId: container.imageId,
            command: container.command,
            created: container.created,
            status: "Paused",
            state: .paused,
            ports: container.ports,
            labels: container.labels,
            sizeRw: container.sizeRw,
            sizeRootFs: container.sizeRootFs
        )

        containers.append(updatedContainer)
    }

    func unpauseContainer(id: String) async throws {
        guard let index = containers.firstIndex(where: { $0.id == id }) else {
            throw DockerError.decodingError("Container not found")
        }

        let container = containers[index]
        containers.remove(at: index)

        // Update container state
        let updatedContainer = Container(
            id: container.id,
            names: container.names,
            image: container.image,
            imageId: container.imageId,
            command: container.command,
            created: container.created,
            status: "Up 1 second",
            state: .running,
            ports: container.ports,
            labels: container.labels,
            sizeRw: container.sizeRw,
            sizeRootFs: container.sizeRootFs
        )

        containers.append(updatedContainer)
    }

    func removeContainer(id: String, force: Bool = false, removeVolumes: Bool = false) async throws {
        guard let index = containers.firstIndex(where: { $0.id == id }) else {
            throw DockerError.decodingError("Container not found")
        }

        let container = containers[index]
        if container.state == .running && !force {
            throw DockerError.apiError(
                statusCode: .init(statusCode: 409),
                message: "Container is running. Use force to remove it."
            )
        }

        containers.remove(at: index)
    }

    // MARK: - Image Operations

    func listImages(all: Bool = false) async throws -> [ContainerImage] {
        return images
    }

    func inspectImage(id: String) async throws -> ContainerImage {
        guard
            let image = images.first(where: {
                $0.id == id || $0.id.contains(id) || $0.repoTags?.contains(id) == true
            })
        else {
            throw DockerError.decodingError("Image not found")
        }
        return image
    }

    func pullImage(name: String) async throws {
        // Simulate image pull by creating a new image if it doesn't exist
        if !images.contains(where: { $0.repoTags?.contains(name) == true }) {
            let newImage = ContainerImage(
                id: "sha256:\(UUID().uuidString)",
                parentId: "",
                repoTags: [name],
                repoDigests: ["mock@sha256:\(UUID().uuidString)"],
                created: Int(Date().timeIntervalSince1970),
                size: 150_000_000,
                sharedSize: 0,
                labels: ["maintainer": "Mock Maintainer"],
                containers: 0
            )
            images.append(newImage)
        }
    }

    func removeImage(id: String, force: Bool = false, pruneChildren: Bool = false) async throws {
        guard
            let index = images.firstIndex(where: {
                $0.id == id || $0.id.contains(id) || $0.repoTags?.contains(id) == true
            })
        else {
            throw DockerError.decodingError("Image not found")
        }

        // Check if image is in use by any container
        let isInUse = containers.contains { $0.imageId == images[index].id }
        if isInUse && !force {
            throw DockerError.apiError(
                statusCode: .init(statusCode: 409),
                message: "Image is being used by running container")
        }

        images.remove(at: index)
    }

    // MARK: - Network Operations

    func listNetworks() async throws -> [Network] {
        return networks
    }

    func inspectNetwork(id: String) async throws -> Network {
        guard let network = networks.first(where: { $0.id == id || $0.name == id }) else {
            throw DockerError.decodingError("Network not found")
        }
        return network
    }

    func createNetwork(
        name: String, driver: String = "bridge", subnet: String? = nil, gateway: String? = nil,
        labels: [String: String]? = nil
    ) async throws -> String {
        let id = UUID().uuidString

        // Create IPAM config
        var ipamConfig: [Network.IPAM.IPAMConfig]?
        if subnet != nil || gateway != nil {
            ipamConfig = [
                Network.IPAM.IPAMConfig(
                    subnet: subnet,
                    gateway: gateway,
                    ipRange: nil
                )
            ]
        }

        let ipam = Network.IPAM(
            driver: "default",
            config: ipamConfig,
            options: nil
        )

        let newNetwork = Network(
            id: id,
            name: name,
            driver: driver,
            scope: "local",
            ipam: ipam,
            containers: [:],
            options: [:],
            labels: labels,
            isInternal: false,
            created: ISO8601DateFormatter().string(from: Date())
        )

        networks.append(newNetwork)
        return id
    }

    func connectContainerToNetwork(
        networkId: String, containerId: String, ipv4Address: String? = nil
    )
        async throws {
        guard
            let networkIndex = networks.firstIndex(where: {
                $0.id == networkId || $0.name == networkId
            })
        else {
            throw DockerError.decodingError("Network not found")
        }

        guard let container = containers.first(where: { $0.id == containerId }) else {
            throw DockerError.decodingError("Container not found")
        }

        let network = networks[networkIndex]
        networks.remove(at: networkIndex)

        var updatedContainers = network.containers ?? [:]

        let networkContainer = Network.NetworkContainer(
            name: container.displayName,
            endpointId: UUID().uuidString,
            macAddress: "02:42:ac:11:00:02",
            ipv4Address: ipv4Address ?? "172.17.0.2/16",
            ipv6Address: nil
        )

        updatedContainers[containerId] = networkContainer

        let updatedNetwork = Network(
            id: network.id,
            name: network.name,
            driver: network.driver,
            scope: network.scope,
            ipam: network.ipam,
            containers: updatedContainers,
            options: network.options,
            labels: network.labels,
            isInternal: network.isInternal,
            created: network.created
        )

        networks.append(updatedNetwork)
    }

    func disconnectContainerFromNetwork(networkId: String, containerId: String, force: Bool = false)
        async throws {
        guard
            let networkIndex = networks.firstIndex(where: {
                $0.id == networkId || $0.name == networkId
            })
        else {
            throw DockerError.decodingError("Network not found")
        }

        let network = networks[networkIndex]
        networks.remove(at: networkIndex)

        guard var updatedContainers = network.containers else {
            throw DockerError.decodingError("Network has no containers")
        }

        guard updatedContainers[containerId] != nil else {
            throw DockerError.decodingError("Container not connected to network")
        }

        updatedContainers.removeValue(forKey: containerId)

        let updatedNetwork = Network(
            id: network.id,
            name: network.name,
            driver: network.driver,
            scope: network.scope,
            ipam: network.ipam,
            containers: updatedContainers,
            options: network.options,
            labels: network.labels,
            isInternal: network.isInternal,
            created: network.created
        )

        networks.append(updatedNetwork)
    }

    func removeNetwork(id: String) async throws {
        guard let index = networks.firstIndex(where: { $0.id == id || $0.name == id }) else {
            throw DockerError.decodingError("Network not found")
        }

        let network = networks[index]

        // Check if network is in use
        if let containers = network.containers, !containers.isEmpty {
            throw DockerError.apiError(
                statusCode: .init(statusCode: 409), message: "Network has active endpoints")
        }

        networks.remove(at: index)
    }

    // MARK: - Volume Operations

    func listVolumes() async throws -> [Volume] {
        return volumes
    }

    func inspectVolume(name: String) async throws -> Volume {
        guard let volume = volumes.first(where: { $0.name == name }) else {
            throw DockerError.decodingError("Volume not found")
        }
        return volume
    }

    func createVolume(name: String, driver: String = "local", labels: [String: String]? = nil)
        async throws -> Volume {
        let newVolume = Volume(
            name: name,
            driver: driver,
            mountpoint: "/var/lib/docker/volumes/\(name)/_data",
            createdAt: ISO8601DateFormatter().string(from: Date()),
            status: nil,
            labels: labels,
            scope: "local",
            options: nil,
            usageData: nil
        )

        volumes.append(newVolume)
        return newVolume
    }

    func removeVolume(name: String, force: Bool = false) async throws {
        guard let index = volumes.firstIndex(where: { $0.name == name }) else {
            throw DockerError.decodingError("Volume not found")
        }

        volumes.remove(at: index)
    }
}
