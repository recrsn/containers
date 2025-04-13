//
//  Network.swift
//  Containers
//
//  Created on 13/03/25.
//

import Foundation

// MARK: - Network Models

struct Network: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let driver: String?
    let scope: String
    let ipam: IPAM
    let containers: [String: NetworkContainer]?
    let options: [String: String]?
    let labels: [String: String]?
    let isInternal: Bool?
    let created: String?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case driver = "Driver"
        case scope = "Scope"
        case ipam = "IPAM"
        case containers = "Containers"
        case options = "Options"
        case labels = "Labels"
        case isInternal = "Internal"
        case created = "Created"
    }

    struct IPAM: Codable, Equatable, Hashable {
        let driver: String?
        let config: [IPAMConfig]?
        let options: [String: String]?

        struct IPAMConfig: Codable, Equatable, Hashable {
            let subnet: String?
            let gateway: String?
            let ipRange: String?

            enum CodingKeys: String, CodingKey {
                case subnet = "Subnet"
                case gateway = "Gateway"
                case ipRange = "IPRange"
            }
        }
    }

    struct NetworkContainer: Codable, Equatable, Hashable {
        let name: String?
        let endpointId: String
        let macAddress: String?
        let ipv4Address: String?
        let ipv6Address: String?

        enum CodingKeys: String, CodingKey {
            case name = "Name"
            case endpointId = "EndpointID"
            case macAddress = "MacAddress"
            case ipv4Address = "IPv4Address"
            case ipv6Address = "IPv6Address"
        }
    }
}

// MARK: - HTTP Helpers

extension URL {
    /// Extracts the Unix socket path from a URL
    var unixSocketPath: String? {
        guard scheme == "unix" else { return nil }

        // Get the host part which contains the socket path
        return host
    }

    /// Creates a URL string for Unix domain socket HTTP connections
    func unixDomainSocketURLString(path: String) -> String {
        // For Unix domain socket connections via AsyncHTTPClient,
        // the format is http+unix://localhost/api/path where the socket path
        // is encoded in the URL scheme
        "http+unix://localhost\(path)"
    }

    /// Appends a path component to the URL
    func appendingPathComponent(pathComponent: String) -> String {
        // Check if this is a Unix socket URL
        if scheme == "unix", let socketPath = unixSocketPath {
            // For Unix socket URLs, we need to format the URL in a way that AsyncHTTPClient understands
            // The socket path is encoded in the URL itself
            let socketPathEncoded =
                socketPath.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                ?? socketPath
            return "http+unix://\(socketPathEncoded)\(pathComponent)"
        }

        // For standard URLs, just use the normal URL scheme + path
        return pathComponent
    }
}

// MARK: - Network Operations

extension DockerClient {
    /// List all networks
    /// - Returns: List of networks
    public func listNetworks() async throws -> [Network] {
        let path = "\(apiBase)/networks"

        return try await performRequest(path: path, method: "GET")
    }

    /// Get detailed information about a network
    /// - Parameter id: Network ID or name
    /// - Returns: Network details
    public func inspectNetwork(id: String) async throws -> Network {
        let path = "\(apiBase)/networks/\(id)"

        return try await performRequest(path: path, method: "GET")
    }

    /// Create a network
    /// - Parameters:
    ///   - name: Network name
    ///   - driver: Network driver (default: "bridge")
    ///   - subnet: CIDR subnet for network (optional)
    ///   - gateway: Gateway for network (optional)
    ///   - labels: Network labels (optional)
    /// - Returns: Created network ID
    public func createNetwork(
        name: String,
        driver: String = "bridge",
        subnet: String? = nil,
        gateway: String? = nil,
        labels: [String: String]? = nil
    ) async throws -> String {
        let path = "\(apiBase)/networks/create"

        struct NetworkCreateRequest: Codable {
            let name: String
            let driver: String
            let ipam: IPAM?
            let labels: [String: String]?

            struct IPAM: Codable {
                let driver: String
                let config: [IPAMConfig]?

                struct IPAMConfig: Codable {
                    let subnet: String?
                    let gateway: String?
                }
            }
        }

        var ipamConfig: [NetworkCreateRequest.IPAM.IPAMConfig]?
        if subnet != nil || gateway != nil {
            ipamConfig = [NetworkCreateRequest.IPAM.IPAMConfig(subnet: subnet, gateway: gateway)]
        }

        let ipam =
            ipamConfig != nil
            ? NetworkCreateRequest.IPAM(driver: "default", config: ipamConfig) : nil

        let request = NetworkCreateRequest(
            name: name,
            driver: driver,
            ipam: ipam,
            labels: labels
        )

        let response: [String: String] = try await performRequest(
            path: path,
            method: "POST",
            body: request
        )

        guard let id = response["Id"] else {
            throw DockerError.decodingError("Missing network ID in response")
        }

        return id
    }

    /// Connect a container to a network
    /// - Parameters:
    ///   - networkId: Network ID or name
    ///   - containerId: Container ID or name
    ///   - ipv4Address: IPv4 address to assign to container (optional)
    public func connectContainerToNetwork(
        networkId: String,
        containerId: String,
        ipv4Address: String? = nil
    ) async throws {
        let path = "\(apiBase)/networks/\(networkId)/connect"

        struct NetworkConnectRequest: Codable {
            let container: String
            let endpointConfig: EndpointConfig?

            struct EndpointConfig: Codable {
                let ipamConfig: IPAMConfig?

                struct IPAMConfig: Codable {
                    let ipv4Address: String?
                }
            }
        }

        let ipamConfig =
            ipv4Address != nil
            ? NetworkConnectRequest.EndpointConfig.IPAMConfig(ipv4Address: ipv4Address) : nil
        let endpointConfig =
            ipamConfig != nil ? NetworkConnectRequest.EndpointConfig(ipamConfig: ipamConfig) : nil

        let request = NetworkConnectRequest(
            container: containerId,
            endpointConfig: endpointConfig
        )

        try await performRequestExpectNoContent(
            path: path,
            method: "POST",
            body: request
        )
    }

    /// Disconnect a container from a network
    /// - Parameters:
    ///   - networkId: Network ID or name
    ///   - containerId: Container ID or name
    ///   - force: Force disconnection even if container is running
    public func disconnectContainerFromNetwork(
        networkId: String,
        containerId: String,
        force: Bool = false
    ) async throws {
        let path = "\(apiBase)/networks/\(networkId)/disconnect"

        struct NetworkDisconnectRequest: Codable {
            let container: String
            let force: Bool
        }

        let request = NetworkDisconnectRequest(
            container: containerId,
            force: force
        )

        try await performRequestExpectNoContent(
            path: path,
            method: "POST",
            body: request
        )
    }

    /// Remove a network
    /// - Parameter id: Network ID or name
    public func removeNetwork(id: String) async throws {
        let path = "\(apiBase)/networks/\(id)"

        try await performRequestExpectNoContent(path: path, method: "DELETE")
    }
}
