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
    
    // Internal state for image selection
    @State private var showingPullSheet = false
    @State private var imageToPull = ""
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var selectedImage: ContainerImage? = nil
    
    var body: some View {
        NavigationSplitView {
            if docker.images.isEmpty && !docker.imageLoading && docker.pullingImages.isEmpty {
                ContentUnavailableView(
                    "No Images",
                    systemImage: "cube",
                    description: Text("No images found. Pull an image to get started.")
                )
            } else if docker.imageLoading && docker.pullingImages.isEmpty {
                ProgressView("Loading images...")
                    .padding()
            } else {
                VStack {
                    List(selection: $selectedImage) {
                        ForEach(docker.images) { image in
                            NavigationLink(value: image) {
                                if image.isPulling {
                                    PulledImageRow(
                                        imageName: image.displayName,
                                        progress: image.progress,
                                        completedLayers: image.completedLayers.count,
                                        totalLayers: image.allLayers.count
                                    )
                                } else {
                                    ImageRow(image: image)
                                }
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
            }
        } detail: {
            if let image = selectedImage {
                if image.isPulling {
                    PullingImageDetailView(image: image)
                } else {
                    ImageDetailView(image: image)
                }
            } else {
                ContentUnavailableView("Select an image", systemImage: "cube")
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
                showingPullSheet = false
                try await docker.pullImage(name: imageToPull)
                imageToPull = ""
            } catch {
                Logger.shared.error(error, context: "Failed to pull image")
                errorMessage = "Failed to pull image: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

#Preview {
    NavigationSplitView {
        List {
            Label("Images", systemImage: "image.circle")
        }.listStyle(.sidebar)
    } detail: {
        ImageView()
    }.environment(DockerContext.preview)
}
