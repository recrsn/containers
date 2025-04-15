//
//  Logger.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 13/04/25.
//

import Foundation
import os.log

enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

final class _Logger {
    private let osLog: OSLog
    private let fileURL: URL
    private let dateFormatter: DateFormatter
    private let logQueue = DispatchQueue(label: "com.inputforge.containers.logger", qos: .utility)

    var minimumLogLevel: LogLevel = .info

    fileprivate init(minimumLogLevel: LogLevel = .info) {
        osLog = OSLog(
            subsystem: Bundle.main.bundleIdentifier ?? "com.inputforge.containers", category: "App")

        let logDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("Logs", isDirectory: true)

        do {
            try FileManager.default.createDirectory(
                at: logDirectory, withIntermediateDirectories: true)
        } catch {
            print("Failed to create log directory: \(error)")
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        fileURL = logDirectory.appendingPathComponent("containers-\(dateString).log")

        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: fileURL.path) {
            fileManager.createFile(atPath: fileURL.path, contents: nil)
        }
    }

    func log(
        _ level: LogLevel, message: String, file: String = #file, function: String = #function,
        line: Int = #line
    ) {
        guard level >= minimumLogLevel else { return }

        let sourceFileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage =
            "[\(dateFormatter.string(from: Date()))] [\(level)] [\(sourceFileName):\(line) \(function)] \(message)"

        // Log to console
        let osLogType: OSLogType
        switch level {
        case .debug:
            osLogType = .debug
        case .info:
            osLogType = .info
        case .warning:
            osLogType = .default
        case .error:
            osLogType = .error
        case .critical:
            osLogType = .fault
        }

        os_log("%{public}@", log: osLog, type: osLogType, logMessage)

        // Log to file
        logQueue.async { [fileURL = self.fileURL] in
            if let data = "\(logMessage)\n".data(using: .utf8) {
                if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    try? fileHandle.close()
                }
            }
        }
    }

    func debug(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        log(.debug, message: message, file: file, function: function, line: line)
    }

    func info(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        log(.info, message: message, file: file, function: function, line: line)
    }

    func warning(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        log(.warning, message: message, file: file, function: function, line: line)
    }

    func error(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        log(.error, message: message, file: file, function: function, line: line)
    }

    func error(
        _ error: Error, context: String? = nil, file: String = #file, function: String = #function,
        line: Int = #line
    ) {
        let errorMessage =
            context != nil
            ? "\(context!): \(error.localizedDescription)" : error.localizedDescription
        log(.error, message: errorMessage, file: file, function: function, line: line)
    }

    func critical(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        log(.critical, message: message, file: file, function: function, line: line)
    }
}

actor Logger {
    static let shared = _Logger()
    private init() {}
}
