import Foundation
import SwiftUI

struct DockerInfoView: View {
    let info: DockerInfo

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header card with Docker info
                HeaderCard(info: info)

                // System info card
                InfoCard(title: "System", systemName: "desktopcomputer") {
                    InfoRow(icon: "server.rack", label: "Name", value: info.name)
                    InfoRow(icon: "tag", label: "Docker Version", value: info.serverVersion)
                    InfoRow(
                        icon: "gear", label: "OS",
                        value:
                            "\(info.operatingSystem) \(info.osVersion != nil ? info.osVersion! : "") (\(info.osType))"
                    )
                    InfoRow(icon: "memorychip", label: "Kernel", value: info.kernelVersion)
                    InfoRow(icon: "cpu", label: "Architecture", value: info.architecture)
                }

                // Resources card
                InfoCard(title: "Resources", systemName: "chart.bar") {
                    InfoRow(icon: "cpu", label: "CPU", value: "\(info.ncpu)")
                    InfoRow(icon: "memorychip", label: "Memory", value: formatBytes(info.memTotal))
                    InfoRow(icon: "externaldrive", label: "Storage Driver", value: info.driver)
                    InfoRow(icon: "doc.text", label: "Logging Driver", value: info.loggingDriver)
                    InfoRow(icon: "timer", label: "Default Runtime", value: info.defaultRuntime)
                }

                // Container Statistics card with visual indicators
                InfoCard(title: "Container Statistics", systemName: "square.3.stack.3d") {
                    ContainerStatsView(info: info)
                }
                
                // Warnings card
                if let warnings = info.warnings, !warnings.isEmpty {
                    InfoCard(title: "Warnings", systemName: "exclamationmark.triangle") {
                        ForEach(warnings, id: \.self) { warning in
                            HStack(alignment: .top) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .padding(.top, 2)

                                Text(warning)
                                    .foregroundStyle(.orange)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // More details section
                InfoCard(title: "Advanced Details", systemName: "gear.circle") {
                    DisclosureGroup {
                        PropertyTreeView(value: info, label: nil, depth: 0)
                            .padding(.vertical, 4)
                    } label: {
                        Label("All Configuration Properties", systemImage: "list.bullet.indent")
                            .font(.headline)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Docker Info")

    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    NavigationStack {
        DockerInfoView(info: PreviewData.dockerInfo)
    }
}
