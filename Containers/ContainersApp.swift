//
//  ContainersApp.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 02/02/25.
//

import SwiftUI
import os.log

@main
struct ContainersApp: App {
    @State private var dockerContext = DockerContext()

    init() {
        // Set minimum log level
        Logger.shared.minimumLogLevel = .info

        // Log app startup
        Logger.shared.info("Containers app started")

        do {
            // Perform any initialization tasks that might throw errors
            try validateEnvironment()
        } catch {
            Logger.shared.error(error, context: "App initialization failed")
        }
    }

    private func validateEnvironment() throws {
        // Check for essential directories
        let fileManager = FileManager.default
        let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first

        if appSupportDir == nil {
            Logger.shared.warning("Application Support directory not found")
        }

        // Log system information
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        Logger.shared.info("Running on \(osVersion)")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dockerContext)
        }

        Settings {
            DockerSettingsView()
                .environment(dockerContext)
        }
    }
}

#Preview {
    ContentView()
        .environment(DockerContext.preview)
}
