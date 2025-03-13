//
//  ContainersApp.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 02/02/25.
//

import SwiftUI

@main
struct ContainersApp: App {
    @StateObject private var dockerSettings = DockerSettings()


    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dockerSettings)
        }

        Settings {
            DockerSettingsView()
                .environmentObject(dockerSettings)
        }
    }
}
