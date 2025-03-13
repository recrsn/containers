//
//  ContainersApp.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 02/02/25.
//

import SwiftUI
import SwiftData

@main
struct ContainersApp: App {
    @StateObject private var dockerSettings = DockerSettings()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dockerSettings)
        }
        .modelContainer(sharedModelContainer)
        
        Settings {
            DockerSettingsView()
                .environmentObject(dockerSettings)
        }
    }
}
