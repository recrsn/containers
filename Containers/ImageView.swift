//
//  ImageView.swift
//  Containers
//
//  Created on 03/13/25.
//

import SwiftUI

struct ImageView: View {
    @State private var images: [Image] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var selectedImage: Image?
    @State private var showingActionSheet = false
    @State private var showingPullSheet = false
    @State private var imageToPull = ""
    
    private let dockerClient = DockerClient()
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading images...")
                    .padding()
            } else {
                List(images) { image in
                    ImageRow(image: image)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedImage = image
                            showingActionSheet = true
                        }
                }
                .overlay {
                    if images.isEmpty && !isLoading {
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
            }
        }
        .confirmationDialog(
            "Image Actions",
            isPresented: $showingActionSheet,
            presenting: selectedImage
        ) { image in
            Button("Create Container", action: {
                // This would navigate to container creation with this image pre-selected
            })
            
            Button("Remove", role: .destructive) {
                performImageAction(image: image, action: .remove)
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
        .task {
            await refreshImages()
        }
    }
    
    private func refreshImages() {
        Task {
            await loadImages()
        }
    }
    
    private func loadImages() async {
        isLoading = true
        errorMessage = nil
        
        do {
            images = try await dockerClient.listImages()
        } catch {
            errorMessage = "Failed to load images: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    private enum ImageAction {
        case remove
    }
    
    private func performImageAction(image: Image, action: ImageAction) {
        Task {
            do {
                switch action {
                case .remove:
                    try await dockerClient.removeImage(id: image.id)
                }
                
                // Refresh image list after action
                await loadImages()
            } catch {
                errorMessage = "Failed to perform action: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func pullImage() {
        guard !imageToPull.isEmpty else { return }
        
        Task {
            do {
                isLoading = true
                try await dockerClient.pullImage(name: imageToPull)
                imageToPull = ""
                showingPullSheet = false
                await loadImages()
            } catch {
                errorMessage = "Failed to pull image: \(error.localizedDescription)"
                showError = true
                isLoading = false
            }
        }
    }
}

struct ImageRow: View {
    let image: Image
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(image.displayName)
                    .font(.headline)
                
                Text(image.shortId)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(formatSize(image.size))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(formatDate(image.created))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatSize(_ size: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    private func formatDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

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
                
                Section(header: Text("Examples"), footer: Text("Docker Hub will be used if no registry is specified")) {
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
    ImageView()
}