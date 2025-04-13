import SwiftUI

struct ResourceGauge: View {
    let value: Double
    let maxValue: Double
    let color: Color
    let icon: String
    let title: String
    let percentage: Double?

    init(
        value: Double, maxValue: Double, color: Color, icon: String, title: String,
        percentage: Double? = nil
    ) {
        self.value = value
        self.maxValue = maxValue
        self.color = color
        self.icon = icon
        self.title = title
        self.percentage = percentage
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 10)

                if let pct = percentage {
                    Circle()
                        .trim(from: 0, to: min(CGFloat(pct) / 100.0, 1.0))
                        .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                } else {
                    Circle()
                        .trim(from: 0, to: 1.0)
                        .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }

                VStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)

                    if let pct = percentage {
                        Text(String(format: "%.1f%%", pct))
                            .font(.caption2)
                            .foregroundStyle(color)
                    }
                }
            }
            .frame(width: 80, height: 80)

            Text(formatValue())
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }

    private func formatValue() -> String {
        if title == "CPUs" {
            return "\(Int(value))"
        } else {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .binary
            return formatter.string(fromByteCount: Int64(value))
        }
    }
}

#Preview {
    HStack {
        ResourceGauge(
            value: 6,
            maxValue: 8,
            color: .blue,
            icon: "cpu",
            title: "CPUs",
            percentage: 75.0
        )

        ResourceGauge(
            value: 8_589_934_592,
            maxValue: 17_179_869_184,
            color: .green,
            icon: "memorychip",
            title: "Memory",
            percentage: 50.0
        )
    }
    .padding()
}
