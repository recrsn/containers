//
//  DockerSettingsView.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 13/03/25.
//

import SwiftUI

struct DockerSettingsView: View {
    @State private var settings = DockerSettings()
    @Environment(DockerContext.self) private var connectionContext: DockerContext

    @State private var isShowingAddSheet = false
    @State private var selectedConnection: DockerSocket?
    @State private var testConnectionResult: String?
    @State private var isTestingConnection = false
    @State private var selectedTab: String = "connections"

    @State private var editingName: String = ""
    @State private var editingSocketType: DockerSocket.SocketType = .dockerDesktop
    @State private var editingCustomPath: String = ""

    var body: some View {
        TabView(selection: $selectedTab) {
            ConnectionsTabView()
                .tabItem {
                    Label("Connections", systemImage: "network")
                }
                .tag("connections")
        }
        .frame(minWidth: 500, minHeight: 300)
    }
}

#Preview {
    DockerSettingsView()
        .environment(DockerContext.preview)
}
