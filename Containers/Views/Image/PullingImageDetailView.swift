import SwiftUI

struct LayerStatus: Identifiable {
    let id: String
    let status: String
    let progress: Double
    
    enum State {
        case waiting
        case downloading
        case extracting
        case complete
        case existing
        
        var icon: String {
            switch self {
            case .waiting: return "hourglass"
            case .downloading: return "arrow.down.circle"
            case .extracting: return "archivebox"
            case .complete: return "checkmark.circle.fill"
            case .existing: return "checkmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .waiting: return .gray
            case .downloading: return .blue
            case .extracting: return .orange
            case .complete: return .green
            case .existing: return .secondary
            }
        }
    }
    
    var state: State {
        if status.contains("Already exists") {
            return .existing
        } else if status.contains("Download complete") || status.contains("Pull complete") {
            return .complete
        } else if status.contains("Downloading") {
            return .downloading
        } else if status.contains("Extracting") {
            return .extracting
        } else {
            return .waiting
        }
    }
}

struct PullingImageDetailView: View {
    let image: ContainerImage
    
    private var layerStatuses: [LayerStatus] {
        image.getLayerStatuses()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Pulling Image")
                    .font(.largeTitle)
                    .padding(.bottom, 8)
                
                DetailRow(label: "Image", value: image.displayName)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overall Progress")
                        .font(.headline)
                    
                    ProgressView(value: image.progress)
                        .progressViewStyle(.linear)
                        .frame(maxWidth: .infinity)
                    
                    HStack {
                        Text("Completed \(Int(image.progress * 100))%")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("\(image.completedLayers.count)/\(image.allLayers.count) layers")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Layer Status")
                        .font(.headline)
                    
                    ForEach(layerStatuses) { layer in
                        HStack(spacing: 12) {
                            Image(systemName: layer.state.icon)
                                .foregroundStyle(layer.state.color)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(layer.id)
                                    .font(.callout)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                
                                Text(layer.status)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                if layer.state == .downloading && layer.progress > 0 {
                                    ProgressView(value: layer.progress)
                                        .progressViewStyle(.linear)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        Divider()
                    }
                }
                .padding()
                .background(Color.accentColor.opacity(0.05))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Pulling: \(image.displayName)")
    }
}

#Preview {
    NavigationStack {
        let previewImage = ContainerImage(
            id: "sha256:a1b2c3d4e5f6",
            parentId: "",
            repoTags: ["nginx:latest"],
            repoDigests: nil,
            created: Int(Date().timeIntervalSince1970),
            size: 142578432,
            sharedSize: 0,
            labels: nil,
            containers: 0
        )
        
        // Add pulling state
        var mutableImage = previewImage
        mutableImage.isPulling = true
        mutableImage.allLayers = ["a1b2c3d4", "e5f6g7h8", "i9j0k1l2", "m3n4o5p6", "q7r8s9t0"]
        mutableImage.completedLayers = ["e5f6g7h8", "m3n4o5p6"]
        mutableImage.layerProgress = [
            "a1b2c3d4": 0.45,
            "e5f6g7h8": 1.0,
            "i9j0k1l2": 0.15,
            "m3n4o5p6": 1.0,
            "q7r8s9t0": 0.0
        ]
        mutableImage.layerStatus = [
            "a1b2c3d4": "Downloading [====>      ]  5.3MB/12.1MB",
            "e5f6g7h8": "Download complete",
            "i9j0k1l2": "Extracting [=>          ]  1.2MB/8.7MB",
            "m3n4o5p6": "Already exists",
            "q7r8s9t0": "Waiting"
        ]
        
        return PullingImageDetailView(image: mutableImage)
    }
}