//
//  ImageDetailView.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 15/03/25.
//

import SwiftUI

struct ImageDetailView: View {
    let image: ContainerImage
    @Environment(DockerContext.self) private var docker
    @State private var showingCreateSheet = false
    @State private var showingRemoveAlert = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header section
                HStack {
                    VStack(alignment: .leading) {
                        Text(image.displayName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .lineLimit(2)

                        Text(image.id)
                            .font(.caption)
                            .monospaced()
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }

                    Spacer()
                }
                .padding(.bottom)

                // Action buttons
                HStack(spacing: 12) {
                    // Creating a container from an image would go here
                    ActionButton(
                        title: "Create", icon: "plus.square",
                        action: {
                            showingCreateSheet = true
                        })
                    ActionButton(
                        title: "Remove", icon: "trash", role: .destructive, tint: .red,
                        action: {
                            showingRemoveAlert = true
                        })
                }

                Divider().padding(.vertical)

                // Details
                Group {
                    if !image.repoTags.isNil {
                        Text("Tags")
                            .font(.headline)

                        ForEach(image.repoTags ?? [], id: \.self) { tag in
                            if tag != "<none>:<none>" {
                                Text(tag)
                                    .font(.body.monospaced())
                                    .textSelection(.enabled)
                                    .padding(.bottom, 2)
                            }
                        }

                        Divider().padding(.vertical, 8)
                    }

                    DetailRow(label: "Created", value: formattedDate)
                    DetailRow(label: "Size", value: formatSize(image.size))
                    DetailRow(label: "Shared Size", value: formatSize(image.sharedSize))
                    DetailRow(label: "Container Count", value: "\(image.containers)")

                    if !image.parentId.isEmpty && image.parentId != "<missing>" {
                        DetailRow(label: "Parent ID", value: image.parentId)
                    }

                    if let labels = image.labels, !labels.isEmpty {
                        Text("Labels")
                            .font(.headline)
                            .padding(.top, 8)

                        ForEach(labels.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            DetailRow(label: key, value: value)
                        }
                    }

                    if let repoDigests = image.repoDigests, !repoDigests.isEmpty {
                        Text("Repository Digests")
                            .font(.headline)
                            .padding(.top, 8)

                        ForEach(repoDigests, id: \.self) { digest in
                            Text(digest)
                                .font(.caption.monospaced())
                                .textSelection(.enabled)
                                .padding(.bottom, 2)
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Image Details")
        .alert("Remove Image", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                Task {
                    await removeImage()
                }
            }
        } message: {
            Text("Are you sure you want to remove this image? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private var formattedDate: String {
        let date = Date(timeIntervalSince1970: TimeInterval(image.created))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    private func formatSize(_ size: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    private func removeImage() async {
        do {
            try await docker.removeImage(id: image.id)
        } catch {
            Logger.shared.error(error, context: "Failed to remove image: \(image.id)")
            errorMessage = "Failed to remove image: \(error.localizedDescription)"
            showError = true
        }
    }
}

#Preview {
    ImageDetailView(image: PreviewData.image)
        .environment(DockerContext.preview)
}
