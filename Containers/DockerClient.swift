//
//  DockerClient.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 02/02/25.
//

import Foundation
import AsyncHTTPClient
import NIO
import NIOHTTP1
import NIOCore
import NIOPosix
import NIOFoundationCompat


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

struct Container: Codable, Identifiable {
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
    
    struct Port: Codable {
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

struct Image: Codable, Identifiable {
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
        return id.hasPrefix("sha256:") ? String(id.dropFirst(7).prefix(12)) : id.prefix(12).description
    }
}

struct Volume: Codable, Identifiable {
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
    
    struct UsageData: Codable {
        let size: Int
        let refCount: Int
        
        enum CodingKeys: String, CodingKey {
            case size = "Size"
            case refCount = "RefCount"
        }
    }
}


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
            let socketPathEncoded = socketPath.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? socketPath
            return "http+unix://\(socketPathEncoded)\(pathComponent)"
        }
        
        // For standard URLs, just use the normal URL scheme + path
        return pathComponent
    }
}


enum DockerError: Error {
    case apiError(statusCode: HTTPResponseStatus, message: String)
    case decodingError(String)
    case networkError(Error)
    case invalidURL
}

final class DockerClient: Sendable {
    
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private let version: String = "1.47"
    private let dockerURL: URL
    private let apiBase: String
    private let httpClient: HTTPClient
    private let socketPath: String
    
    init(socketPath: String = "/var/run/docker.sock") {
        decoder = JSONDecoder()
        encoder = JSONEncoder()
        
        self.socketPath = socketPath
        self.dockerURL = URL(string: "unix://\(socketPath)")!
        self.apiBase = "/v\(version)"
        
        // Create HTTP client with Unix socket configuration
        var configuration = HTTPClient.Configuration()
        configuration.timeout = HTTPClient.Configuration.Timeout(connect: .seconds(5), read: .seconds(10), write: .seconds(10))
        
        self.httpClient = HTTPClient(
            configuration: configuration
        )
    }
    
    deinit {
        try? httpClient.syncShutdown()
    }
    
    // MARK: - Container Operations
    
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
    /// - Returns: Created container ID
    public func createContainer(config: ContainerCreateRequest) async throws -> String {
        let path = "\(apiBase)/containers/create"
        let query = config.name != nil ? "?name=\(config.name!)" : ""
        
        let response: [String: String] = try await performRequest(
            path: path + query,
            method: "POST",
            body: config
        )
        
        guard let id = response["id"] else {
            throw DockerError.decodingError("Missing container ID in response")
        }
        
        return id
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
    public func removeContainer(id: String, force: Bool = false, removeVolumes: Bool = false) async throws {
        let path = "\(apiBase)/containers/\(id)?force=\(force)&v=\(removeVolumes)"
        
        try await performRequestExpectNoContent(path: path, method: "DELETE")
    }
    
    // MARK: - Image Operations
    
    /// List all images
    /// - Parameter all: Include intermediate images if true
    /// - Returns: List of images
    public func listImages(all: Bool = false) async throws -> [Image] {
        let path = "\(apiBase)/images/json?all=\(all)"
        
        return try await performRequest(path: path, method: "GET")
    }
    
    /// Get detailed information about an image
    /// - Parameter imageId: Image ID or name
    /// - Returns: Image details
    public func inspectImage(id: String) async throws -> Image {
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
    public func removeImage(id: String, force: Bool = false, pruneChildren: Bool = false) async throws {
        let path = "\(apiBase)/images/\(id)?force=\(force)&prune=\(pruneChildren)"
        
        try await performRequestExpectNoContent(path: path, method: "DELETE")
    }
    
    // MARK: - Volume Operations
    
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
    public func createVolume(name: String, driver: String = "local", labels: [String: String]? = nil) async throws -> Volume {
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
    
    // MARK: - Helper Methods
    
    private func performRequest<T: Decodable>(path: String, method: String, body: Encodable? = nil) async throws -> T {
        // Format URL for Unix socket connection
        let unixSocketURL = "http+unix://\(socketPath.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? socketPath)\(path)"
        
        var request = HTTPClientRequest(url: unixSocketURL)
        request.method = .init(rawValue: method)
        request.headers.add(name: "Content-Type", value: "application/json")
        request.headers.add(name: "Host", value: "localhost")
        
        if let body = body {
            let bodyData = try encoder.encode(body)
            request.body = .bytes(bodyData)
        }
        
        do {
            let response = try await httpClient.execute(request, timeout: .seconds(30))
            
            guard (200...299).contains(response.status.code) else {
                var errorMessage = "API error"
                errorMessage = try await String(buffer: response.body.collect(upTo: 1024 * 1024))
                throw DockerError.apiError(statusCode: response.status, message: errorMessage)
            }
            
            let body = try await Data(buffer: response.body.collect(upTo: 8 * 1024 * 1024))
                
            do {
                return try decoder.decode(T.self, from: body)
            } catch {
                let bodyString = String(data: body, encoding: .utf8)
                print("Response body: \(String(describing: bodyString))")
                print("Decoding error: \(error)")
                throw DockerError.decodingError("Failed to decode response: \(error.localizedDescription)")
            }
        } catch let error as DockerError {
            throw error
        } catch {
            print("Network error: \(error)")
            throw DockerError.networkError(error)
        }
    }
    
    private func performRequestExpectNoContent(path: String, method: String, body: Encodable? = nil) async throws {
        // Format URL for Unix socket connection
        let unixSocketURL = "http+unix://\(socketPath.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? socketPath)\(path)"
        
        var request = HTTPClientRequest(url: unixSocketURL)
        request.method = .init(rawValue: method)
        request.headers.add(name: "Content-Type", value: "application/json")
        request.headers.add(name: "Host", value: "localhost")
        
        if let body = body {
            let bodyData = try encoder.encode(body)
            request.body = .bytes(bodyData)
        }
        
        do {
            let response = try await httpClient.execute(request, timeout: .seconds(30))
            
            guard (200...299).contains(response.status.code) else {
                var errorMessage = "API error"
                errorMessage = try await String(buffer: response.body.collect(upTo: 1024 * 1024))
                throw DockerError.apiError(statusCode: response.status, message: errorMessage)
            }
        } catch let error as DockerError {
            throw error
        } catch {
            print("Network error: \(error)")
            throw DockerError.networkError(error)
        }
    }

}
