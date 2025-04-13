import SwiftUI

struct InfoCard<Content: View>: View {
    let title: String
    let systemName: String
    let content: Content

    init(title: String, systemName: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemName = systemName
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: systemName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()
            }

            Divider()

            content
        }
        .padding()
    }
}

#Preview {
    InfoCard(title: "Sample Card", systemName: "info.circle") {
        Text("Content goes here")
    }
}
