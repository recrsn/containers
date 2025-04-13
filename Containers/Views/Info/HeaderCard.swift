import SwiftUI

struct HeaderCard: View {
    let info: DockerInfo

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "cube.box")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)

                VStack(alignment: .leading) {
                    Text(info.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Docker \(info.serverVersion)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Status indicator
                HStack {
                    Circle()
                        .fill(info.containersRunning > 0 ? Color.green : Color.orange)
                        .frame(width: 10, height: 10)

                    Text(info.containersRunning > 0 ? "Active" : "Idle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    private func systemInfoTag(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)

            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.1))
        )
        .foregroundStyle(.blue)
    }
}

#Preview {
    HeaderCard(info: PreviewData.dockerInfo)
}
