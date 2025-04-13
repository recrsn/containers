import SwiftUI

struct PropertyTreeView: View {
    let value: Any
    let label: String?
    let depth: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label = label {
                Text(formatPropertyName(label))
                    .font(.headline)
                    .fontWeight(.medium)
            }

            propertyContent
                .padding(.leading, CGFloat(depth) * 12)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var propertyContent: some View {
        let mirror = Mirror(reflecting: value)

        if mirror.displayStyle == .struct || mirror.displayStyle == .class {
            // Handle struct or class with children
            VStack(alignment: .leading, spacing: 8) {
                ForEach(mirror.children.map { IdentifiableMirrorChild($0) }) { identifiableChild in
                    if let propertyName = identifiableChild.label {
                        PropertyTreeView(
                            value: identifiableChild.value,
                            label: propertyName,
                            depth: depth + 1
                        )
                    }
                }
            }
        } else if mirror.displayStyle == .collection || mirror.displayStyle == .set {
            // Handle arrays and sets
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(mirror.children.enumerated()), id: \.offset) { index, element in
                    PropertyTreeView(
                        value: element.value,
                        label: "[\(index)]",
                        depth: depth + 1
                    )
                }
            }
        } else if mirror.displayStyle == .dictionary {
            // Handle dictionaries
            VStack(alignment: .leading, spacing: 8) {
                ForEach(mirror.children.map { IdentifiableMirrorChild($0) }) { identifiablePair in
                    let dictionaryPair = Mirror(reflecting: identifiablePair.value)
                    if let keyChild = dictionaryPair.children.first,
                        let valueChild = dictionaryPair.children.dropFirst().first {
                        PropertyTreeView(
                            value: valueChild.value,
                            label: "\(keyChild.value)",
                            depth: depth + 1
                        )
                    }
                }
            }
        } else if mirror.displayStyle == .optional {
            // Handle optionals
            if let firstChild = mirror.children.first {
                PropertyTreeView(
                    value: firstChild.value,
                    label: nil,
                    depth: depth
                )
            } else {
                Text("nil")
                    .italic()
                    .foregroundStyle(.secondary)
            }
        } else {
            // Handle primitive values
            Text(formatValue(value))
                .foregroundStyle(.secondary)
        }
    }

    private func formatPropertyName(_ name: String) -> String {
        // Remove the underscore prefix that Swift adds to property names
        let cleanName = name.hasPrefix("_") ? String(name.dropFirst()) : name

        // Convert camelCase to Title Case with Spaces
        let withSpaces = cleanName.replacingOccurrences(
            of: "([a-z])([A-Z])",
            with: "$1 $2",
            options: .regularExpression,
            range: nil
        )

        return withSpaces.prefix(1).uppercased() + withSpaces.dropFirst()
    }

    private func formatValue(_ value: Any) -> String {
        if let stringValue = value as? String {
            return stringValue
        } else if let boolValue = value as? Bool {
            return boolValue ? "Yes" : "No"
        } else if let intValue = value as? Int {
            return "\(intValue)"
        } else if let int64Value = value as? Int64 {
            if int64Value > 1_000_000 {
                let formatter = ByteCountFormatter()
                formatter.countStyle = .binary
                return formatter.string(fromByteCount: int64Value)
            }
            return "\(int64Value)"
        } else if let doubleValue = value as? Double {
            return String(format: "%.2f", doubleValue)
        } else if let array = value as? [Any] {
            return "[\(array.count) items]"
        } else if value is [String: Any] {
            return "(Dictionary)"
        } else {
            return "\(value)"
        }
    }
}

#Preview {
    ScrollView {
        PropertyTreeView(value: PreviewData.dockerInfo, label: "Docker Info", depth: 0)
    }
}
