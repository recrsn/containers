//
//  CreateVolumeSheet.swift
//  Containers
//
//  Created on 13/03/25.
//

import SwiftUI

struct CreateVolumeSheet: View {
    @Binding var volumeName: String
    @Environment(\.dismiss) private var dismiss
    var onSubmit: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Volume Name")) {
                    TextField("Name", text: $volumeName)
                        .autocorrectionDisabled()
                }

                Section(footer: Text("Only local driver is currently supported")) {
                    Text("Driver: local")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Create Volume")
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
                    .disabled(volumeName.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 250)
    }
}

#Preview {
    CreateVolumeSheet(volumeName: .constant("test-volume"), onSubmit: {})
}
