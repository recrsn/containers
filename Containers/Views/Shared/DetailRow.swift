//
//  DetailRow.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 23/03/25.
//

import SwiftUI

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
        }
        .padding(.bottom, 4)
    }
}

#Preview {
    DetailRow(label: "Hello", value: "World")
}
