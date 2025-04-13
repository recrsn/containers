//
//  PullImageSheet.swift
//  Containers
//
//  Created on 11/04/25.
//

import SwiftUI

struct PullImageSheet: View {
    @Binding var imageName: String
    @Environment(\.dismiss) private var dismiss
    var onSubmit: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Image Name")) {
                    TextField("Image name (e.g. ubuntu:latest)", text: $imageName)
                        .autocorrectionDisabled()
                }

                Section(
                    header: Text("Examples"),
                    footer: Text("Docker Hub will be used if no registry is specified")
                ) {
                    Button("ubuntu:latest") {
                        imageName = "ubuntu:latest"
                    }
                    Button("nginx:alpine") {
                        imageName = "nginx:alpine"
                    }
                    Button("postgres:15") {
                        imageName = "postgres:15"
                    }
                }
            }
            .navigationTitle("Pull Image")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Pull") {
                        onSubmit()
                    }
                    .disabled(imageName.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 350)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var imageName = ""

        var body: some View {
            PullImageSheet(imageName: $imageName, onSubmit: {})
        }
    }

    return PreviewWrapper()
}
