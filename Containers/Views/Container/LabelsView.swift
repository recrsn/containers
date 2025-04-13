//
//  LabelsView.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 11/04/25.
//

import SwiftUI

private struct Label: Identifiable {
    let key: String
    let value: String

    var id: String { key }
}

struct LabelsView: View {
    let labels: [String: String]

    private var _labels: [Label] {
        labels.sorted(by: <).map { Label(key: $0.0, value: $0.1) }
    }

    var body: some View {
        Table(_labels) {
            TableColumn("Key") { item in
                Text(item.key)
                    .font(.body.monospaced())
            }
            TableColumn("Value") { item in
                Text(item.value)
                    .font(.body)
            }
        }

    }
}

#Preview {
    LabelsView(
        labels: [
            "com.docker.publisher": "nginx",
            "com.docker.version": "20.10.11",
            "maintainer": "nginx"
        ]
    )
}
