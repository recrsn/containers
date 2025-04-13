import SwiftUI

struct ContainerStatsView: View {
    let info: DockerInfo

    var body: some View {
        VStack(spacing: 16) {
            // Container counts
            HStack(spacing: 24) {
                containerStat(
                    count: info.containersRunning, title: "Running", icon: "play.circle",
                    color: .green)
                containerStat(
                    count: info.containersPaused, title: "Paused", icon: "pause.circle",
                    color: .orange)
                containerStat(
                    count: info.containersStopped, title: "Stopped", icon: "stop.circle",
                    color: .red)
            }
            .padding(.vertical, 8)

            Divider()

            // Overall summary
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(
                        icon: "square.stack.3d.up", label: "Total Containers",
                        value: "\(info.containers)")
                    InfoRow(icon: "photo", label: "Images", value: "\(info.images)")
                }
            }
        }
    }

    private func containerStat(count: Int, title: String, icon: String, color: Color) -> some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(color)

            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ContainerStatsView(info: PreviewData.dockerInfo)
}
