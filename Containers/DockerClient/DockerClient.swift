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

// MARK: - Error Types

enum DockerError: Error {
    case apiError(statusCode: HTTPResponseStatus, message: String)
    case decodingError(String)
    case networkError(Error)
    case invalidURL
}

// MARKL - Docker Client

final class DockerClient: Sendable {
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
        configuration.timeout = HTTPClient.Configuration.Timeout(connect: .seconds(5), read: .seconds(10), write: .seconds(10))

        self.httpClient = HTTPClient(
            configuration: configuration
        )
    }

    deinit {
        try? httpClient.syncShutdown()
    }

    // MARK: - Helper Methods

    func performRequest<T: Decodable>(path: String, method: String, body: Encodable? = nil) async throws -> T {
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

    func performRequestExpectNoContent(path: String, method: String, body: Encodable? = nil) async throws {
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
