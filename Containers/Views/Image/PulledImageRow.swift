import SwiftUI

struct PulledImageRow: View {
    let imageName: String
    let progress: Double
    var completedLayers: Int = 0
    var totalLayers: Int = 0
    
    private var formattedProgress: String {
        let percent = Int(progress * 100)
        if totalLayers > 0 {
            return "\(percent)% (\(completedLayers)/\(totalLayers) layers)"
        } else {
            return "\(percent)%"
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(imageName)
                    .font(.headline)
                
                Text("Pulling in progress")
                    .font(.caption)
                    .foregroundStyle(.blue)
                
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 250)
            }
            
            Spacer()
            
            Text(formattedProgress)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack {
        PulledImageRow(imageName: "nginx:latest", progress: 0.3, completedLayers: 2, totalLayers: 6)
        PulledImageRow(imageName: "ubuntu:22.04", progress: 0.75, completedLayers: 6, totalLayers: 8)
    }
    .padding()
    .frame(width: 400)
}