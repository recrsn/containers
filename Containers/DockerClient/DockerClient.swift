//
//  DockerClient.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 02/02/25.
//

import AsyncHTTPClient
import Foundation
import NIO
import NIOCore
import NIOFoundationCompat
import NIOHTTP1
import NIOPosix
import os.log

// MARK: - Error Types

enum DockerError: Error {
    case apiError(statusCode: HTTPResponseStatus, message: String)
    case decodingError(String)
    case networkError(Error)
    case invalidURL
}

// MARK: - Docker Client Protocol

protocol DockerClientProtocol: Sendable {
    // System Operations
    func info() async throws -> DockerInfo

    // Container Operations
    func listContainers(all: Bool) async throws -> [Container]
    func inspectContainer(id: String) async throws -> Container
    func createContainer(config: ContainerCreateRequest) async throws -> String
    func startContainer(id: String) async throws
    func stopContainer(id: String, timeout: Int) async throws
    func restartContainer(id: String, timeout: Int) async throws
    func pauseContainer(id: String) async throws
    func unpauseContainer(id: String) async throws
    func removeContainer(id: String, force: Bool, removeVolumes: Bool) async throws

    // Image Operations
    func listImages(all: Bool) async throws -> [ContainerImage]
    func inspectImage(id: String) async throws -> ContainerImage
    func pullImage(name: String) async throws
    func removeImage(id: String, force: Bool, pruneChildren: Bool) async throws

    // Network Operations
    func listNetworks() async throws -> [Network]
    func inspectNetwork(id: String) async throws -> Network
    func createNetwork(
        name: String, driver: String, subnet: String?, gateway: String?, labels: [String: String]?
    ) async throws -> String
    func connectContainerToNetwork(networkId: String, containerId: String, ipv4Address: String?)
        async throws
    func disconnectContainerFromNetwork(networkId: String, containerId: String, force: Bool)
        async throws
    func removeNetwork(id: String) async throws

    // Volume Operations
    func listVolumes() async throws -> [Volume]
    func inspectVolume(name: String) async throws -> Volume
    func createVolume(name: String, driver: String, labels: [String: String]?) async throws
        -> Volume
    func removeVolume(name: String, force: Bool) async throws
}

// MARK: - Docker Client Implementation

final class DockerClient: DockerClientProtocol {
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private let version: String = "1.47"
    private let dockerURL: URL
    let apiBase: String
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
        configuration.timeout = HTTPClient.Configuration.Timeout(
            connect: .seconds(5), read: .seconds(10), write: .seconds(10))

        self.httpClient = HTTPClient(
            configuration: configuration
        )
    }

    deinit {
        try? httpClient.syncShutdown()
    }

    // MARK: - System Operations

    func info() async throws -> DockerInfo {
        return try await performRequest(path: "\(apiBase)/info", method: "GET")
    }

    // MARK: - Helper Methods

    func performRequest<T: Decodable>(path: String, method: String, body: Encodable? = nil)
        async throws -> T {
        // Format URL for Unix socket connection
        let unixSocketURL =
            "http+unix://\(socketPath.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? socketPath)\(path)"

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
                Logger.shared.error("Decoding error: \(error)")
                Logger.shared.debug("Response body: \(String(describing: bodyString))")
                throw DockerError.decodingError(
                    "Failed to decode response: \(error.localizedDescription)")
            }
        } catch let error as DockerError {
            Logger.shared.error(error, context: "Docker API")
            throw error
        } catch {
            Logger.shared.error("Network error: \(error)")
            throw DockerError.networkError(error)
        }
    }

    func performRequestExpectNoContent(path: String, method: String, body: Encodable? = nil)
        async throws {
        // Format URL for Unix socket connection
        let unixSocketURL =
            "http+unix://\(socketPath.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? socketPath)\(path)"

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
            Logger.shared.error(error, context: "Docker API")
            throw error
        } catch {
            Logger.shared.error("Network error: \(error)")
            throw DockerError.networkError(error)
        }
    }
}
