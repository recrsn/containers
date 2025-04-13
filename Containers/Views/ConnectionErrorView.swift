//
//  ConnectionErrorView.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 12/04/25.
//

import SwiftUI

struct ConnectionErrorView: View {
    let error: Error?

    var body: some View {
        ContentUnavailableView {
            Label("Connection Error", systemImage: "network.slash")
        } description: {
            if let error = error {
                Text("Failed to connect to Docker: \(error.localizedDescription)")
            } else {
                Text("Failed to connect to Docker. Please check your settings.")
            }
        } actions: {
            SettingsLink {
                Label("Open Settings", systemImage: "gear")
            }
        }
    }
}

#Preview {
    ConnectionErrorView(error: nil)
}
