//
//  ImageView.swift
//  Containers
//
//  Created on 13/03/25.
//

import SwiftUI

extension Optional where Wrapped: Collection {
    var isNil: Bool {
        self == nil || self?.isEmpty == true
    }
}

struct ImageView: View {
    @Environment(DockerContext.self) private var docker
    @State private var selectedImage: ContainerImage?
    // Internal state for image selection
    @State private var showingPullSheet = false
    @State private var imageToPull = ""
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationSplitView {
            VStack {
                if docker.imageLoading {
                    ProgressView("Loading images...")
                        .padding()
                } else {
                    List(docker.images, selection: $selectedImage) { image in
                        ImageRow(image: image)
                            .tag(image)
                    }
                    .overlay {
                        if docker.images.isEmpty {
                            ContentUnavailableView(
                                "No Images",
                                systemImage: "cube",
                                description: Text("No images found. Pull an image to get started.")
                            )
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Pull Image", action: { showingPullSheet = true })
                        Button("Refresh", action: refreshImages)
                    } label: {
                        Label("Options", systemImage: "ellipsis.circle")
                    }
                    .disabled(!docker.isConnected)
                }
            }
        } detail: {
            if let image = selectedImage {
                ImageDetailView(image: image)
            } else {
                ContentUnavailableView(
                    "No Image Selected",
                    systemImage: "square.dashed",
                    description: Text("Select an image to view its details.")
                )
            }
        }
        .sheet(isPresented: $showingPullSheet) {
            PullImageSheet(imageName: $imageToPull, onSubmit: pullImage)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func refreshImages() {
        Task {
            do {
                try await docker.loadImages()
            } catch {
                Logger.shared.error(error, context: "Failed to refresh images")
                errorMessage = "Failed to refresh images: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    private func pullImage() {
        guard !imageToPull.isEmpty else { return }

        Task {
            do {
                try await docker.pullImage(name: imageToPull)
                imageToPull = ""
                showingPullSheet = false
            } catch {
                Logger.shared.error(error, context: "Failed to pull image")
                errorMessage = "Failed to pull image: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

#Preview {
    ImageView()
        .environment(DockerContext.preview)
}
