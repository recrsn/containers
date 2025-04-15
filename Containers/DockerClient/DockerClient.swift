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

enum DockerError: Error, CustomStringConvertible, LocalizedError {
    case apiError(statusCode: HTTPResponseStatus, message: String)
    case decodingError(String)
    case networkError(Error)
    case invalidURL
    case encodingError(Error)
    
    var description: String {
        switch self {
        case .apiError(let statusCode, let message):
            return "Docker API Error (\(statusCode)): \(message)"
        case .decodingError(let message):
            return "Docker Error: \(message)"
        case .networkError(let error):
            return "Docker Network Error: \(error.localizedDescription)"
        case .invalidURL:
            return "Docker Error: Invalid URL"
        case .encodingError(let error):
            return "Docker Error: \(error.localizedDescription)"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .apiError(let statusCode, let message):
            // Extract the error message from JSON if possible
            if let jsonData = message.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let errorMessage = json["message"] as? String {
                return "Docker API Error (\(statusCode)): \(errorMessage)"
            }
            return "Docker API Error (\(statusCode)): \(message)"
        case .decodingError(let message):
            return "Failed to process Docker response: \(message)"
        case .networkError(let error):
            return "Connection error: \(error.localizedDescription)"
        case .invalidURL:
            return "Invalid Docker API URL"
        case .encodingError(let error):
            return "Failed to encode Docker request: \(error.localizedDescription)"
        }
    }
}

// MARK: - Docker Client Protocol

protocol DockerClientProtocol: Sendable {
    // System Operations
    func info() async throws -> DockerInfo
    
    // Container Operations
    func listContainers(all: Bool) async throws -> [Container]
    func inspectContainer(id: String) async throws -> Container
    func createContainer(config: ContainerCreateRequest) async throws -> ContainerCreateResponse
    func startContainer(id: String) async throws
    func stopContainer(id: String, timeout: Int) async throws
    func restartContainer(id: String, timeout: Int) async throws
    func pauseContainer(id: String) async throws
    func unpauseContainer(id: String) async throws
    func removeContainer(id: String, force: Bool, removeVolumes: Bool) async throws
    
    // Image Operations
    func listImages(all: Bool) async throws -> [ContainerImage]
    func inspectImage(id: String) async throws -> ContainerImage
    func pullImage(name: String) throws -> AsyncThrowingStream<ImagePullProgress, Error>
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
        
        // Log request information for debugging
        Logger.shared.debug("Docker API Request: \(method) \(path)")
        
        if let body = body {
            let bodyData = try encoder.encode(body)
            request.body = .bytes(bodyData)
            
            // Log request body for debugging (only in debug mode)
            if let bodyString = String(data: bodyData, encoding: .utf8) {
                Logger.shared.debug("Request body: \(bodyString)")
            }
        }
        
        do {
            let response = try await httpClient.execute(request, timeout: .seconds(30))
            Logger.shared.debug("Docker API Response: Status \(response.status.code)")
            
            guard (200...299).contains(response.status.code) else {
                var errorMessage = "API error"
                errorMessage = try await String(buffer: response.body.collect(upTo: 1024 * 1024))
                Logger.shared.error("Docker API error response: \(errorMessage)")
                throw DockerError.apiError(statusCode: response.status, message: errorMessage)
            }
            
            let body = try await Data(buffer: response.body.collect(upTo: 8 * 1024 * 1024))
            
            do {
                let result = try decoder.decode(T.self, from: body)
                return result
            } catch {
                let bodyString = String(data: body, encoding: .utf8)
                Logger.shared.error("Decoding error: \(error)")
                Logger.shared.debug("Response body: \(String(describing: bodyString))")
                
                // More detailed error information for debugging
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        Logger.shared.error("Type mismatch: \(type), path: \(context.codingPath.map { $0.stringValue })")
                    case .valueNotFound(let type, let context):
                        Logger.shared.error("Value not found: \(type), path: \(context.codingPath.map { $0.stringValue })")
                    case .keyNotFound(let key, let context):
                        Logger.shared.error("Key not found: \(key.stringValue), path: \(context.codingPath.map { $0.stringValue })")
                    case .dataCorrupted(let context):
                        Logger.shared.error("Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        Logger.shared.error("Unknown decoding error: \(error)")
                    }
                }
                
                throw DockerError.decodingError(
                    "Failed to decode response: \(error.localizedDescription)")
            }
        } catch let error as DockerError {
            Logger.shared.error(error, context: "Docker API")
            throw error
        } catch {
            Logger.shared.error("Network error: \(error)")
            if let nsError = error as NSError? {
                Logger.shared.error("Error domain: \(nsError.domain), code: \(nsError.code)")
                if let errorDesc = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                    Logger.shared.error("Description: \(errorDesc)")
                }
            }
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
        
        // Log request information for debugging
        Logger.shared.debug("Docker API Request: \(method) \(path) (expect no content)")
        
        if let body = body {
            let bodyData = try encoder.encode(body)
            request.body = .bytes(bodyData)
            
            // Log request body for debugging
            if let bodyString = String(data: bodyData, encoding: .utf8) {
                Logger.shared.debug("Request body: \(bodyString)")
            }
        }
        
        do {
            let response = try await httpClient.execute(request, timeout: .seconds(30))
            Logger.shared.debug("Docker API Response: Status \(response.status.code)")
            
            guard (200...299).contains(response.status.code) else {
                var errorMessage = "API error"
                errorMessage = try await String(buffer: response.body.collect(upTo: 1024 * 1024))
                Logger.shared.error("Docker API error response: \(errorMessage)")
                throw DockerError.apiError(statusCode: response.status, message: errorMessage)
            }
        } catch let error as DockerError {
            Logger.shared.error(error, context: "Docker API")
            throw error
        } catch {
            Logger.shared.error("Network error: \(error)")
            if let nsError = error as NSError? {
                Logger.shared.error("Error domain: \(nsError.domain), code: \(nsError.code)")
                if let errorDesc = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                    Logger.shared.error("Description: \(errorDesc)")
                }
            }
            throw DockerError.networkError(error)
        }
    }
    
    private func prepareRequest(path: String, method: String, body: Encodable?) throws -> HTTPClientRequest {
        let unixSocketURL = "http+unix://\(socketPath.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? socketPath)\(path)"
        
        // Prepare the request and encode body upfront to avoid closure capture issues
        var request = HTTPClientRequest(url: unixSocketURL)
        request.method = .init(rawValue: method)
        request.headers.add(name: "Content-Type", value: "application/json")
        request.headers.add(name: "Host", value: "localhost")
        
        Logger.shared.debug("Docker API Streaming Request: \(method) \(path)")
        
        if let body = body {
            do {
                let bodyData = try encoder.encode(body)
                request.body = .bytes(bodyData)
            } catch {
                Logger.shared.error(error, context: "Error encoding body: \(String(describing: body))")
                throw DockerError.encodingError(error)
            }
        }
        
        return request
    }
    
    func performStreamingRequest<T: Decodable>(path: String, method: String, body: Encodable? = nil) throws -> AsyncThrowingStream<T, Error> {
        
        let request = try prepareRequest(path: path, method: method, body: body)
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let response = try await httpClient.execute(request, timeout: .seconds(300))
                    
                    for try await chunk in response.body {
                        let data = Data(buffer: chunk)
                        
                        // Split by new lines as Docker sends JSON objects line by line
                        let jsonStrings = String(data: data, encoding: .utf8)?.components(separatedBy: "\n")
                        
                        for jsonString in jsonStrings ?? [] {
                            if !jsonString.isEmpty {
                                if let jsonData = jsonString.data(using: .utf8) {
                                    do {
                                        let progress = try self.decoder.decode(T.self, from: jsonData)
                                        continuation.yield(progress)
                                    } catch {
                                        Logger.shared.error("Failed to decode streaming response: \(error)")
                                        // Continue processing on decode error
                                    }
                                }
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
