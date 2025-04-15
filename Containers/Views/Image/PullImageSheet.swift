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
    
    // Form validation
    @State private var isValidImageName = false
    
    // Common image examples
    private let commonImages = [
        "ubuntu:latest",
        "nginx:alpine",
        "postgres:15",
        "node:18",
        "redis:alpine",
        "python:3.11-slim"
    ]
    
    // Validation regular expression for image names
    private let imageNameRegex = #/^[a-z0-9]+([._-][a-z0-9]+)*(/[a-z0-9]+([._-][a-z0-9]+)*)*(:[\w][\w.-]{0,127})?$/#
    
    private func validateImageName() {
        isValidImageName = imageName.isEmpty ? false : ((try? imageNameRegex.wholeMatch(in: imageName) != nil) != nil) || true
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Image name", text: $imageName)
                        .autocorrectionDisabled()
                        .onChange(of: imageName) { _, _ in
                            validateImageName()
                        }
                } footer: {
                    VStack(alignment: .leading) {
                        if !isValidImageName && !imageName.isEmpty {
                            Text("Image name should be in format: name[:tag]")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        Text("Docker Hub will be used if no registry is specified")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
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
                .disabled(imageName.isEmpty || !isValidImageName)
            }
        }
    }
    //        .frame(minWidth: 400, minHeight: 350)
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
