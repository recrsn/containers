//
//  ContentView.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 02/02/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var selectedSection: Section? = .containers
    
    enum Section: String, Identifiable, CaseIterable {
        case containers = "Containers"
        case images = "Images"
        case volumes = "Volumes"
        
        var id: String { self.rawValue }
        
        var iconName: String {
            switch self {
            case .containers: return "square.stack.3d.up"
            case .images: return "cube"
            case .volumes: return "folder"
            }
        }
    }
    
    @EnvironmentObject private var dockerSettings: DockerSettings
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSection) {
                ForEach(Section.allCases) { section in
                    NavigationLink(value: section) {
                        Label(section.rawValue, systemImage: section.iconName)
                    }
                }
            }
            .navigationTitle("Containers")
        } detail: {
            if let selectedSection {
                switch selectedSection {
                case .containers:
                    ContainerView()
                        .navigationTitle("Containers")
                case .images:
                    ImageView()
                        .navigationTitle("Images")
                case .volumes:
                    VolumeView()
                        .navigationTitle("Volumes")
                }
            } else {
                ContentUnavailableView(
                    "No Selection",
                    systemImage: "square.dashed",
                    description: Text("Select a section from the sidebar to get started.")
                )
            }
        }
        .environmentObject(dockerSettings)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .environmentObject(DockerSettings())
}
