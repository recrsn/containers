//
//  CreateNetworkSheet.swift
//  Containers
//
//  Created on 11/04/25.
//

import SwiftUI

struct CreateNetworkSheet: View {
    @Binding var networkName: String
    @Binding var networkDriver: String
    @Binding var networkSubnet: String
    @Binding var networkGateway: String
    @Environment(\.dismiss) private var dismiss
    var onSubmit: () -> Void

    private let networkDrivers = ["bridge", "host", "overlay", "macvlan", "ipvlan", "none"]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Configuration")) {
                    TextField("Name", text: $networkName)
                        .autocorrectionDisabled()

                    Picker("Driver", selection: $networkDriver) {
                        ForEach(networkDrivers, id: \.self) { driver in
                            Text(driver).tag(driver)
                        }
                    }
                }

                Section(
                    header: Text("Network Configuration"),
                    footer: Text("Optional CIDR notation (e.g., 172.16.0.0/16)")
                ) {
                    TextField("Subnet", text: $networkSubnet)
                        .autocorrectionDisabled()

                    TextField("Gateway", text: $networkGateway)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Create Network")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onSubmit()
                    }
                    .disabled(networkName.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var name = ""
        @State private var driver = "bridge"
        @State private var subnet = ""
        @State private var gateway = ""

        var body: some View {
            CreateNetworkSheet(
                networkName: $name,
                networkDriver: $driver,
                networkSubnet: $subnet,
                networkGateway: $gateway,
                onSubmit: {}
            )
        }
    }

    return PreviewWrapper()
}
