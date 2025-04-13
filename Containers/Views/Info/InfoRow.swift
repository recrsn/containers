import SwiftUI

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.blue)

            Text(label)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    InfoRow(icon: "server.rack", label: "Server", value: "docker-desktop")
}
