//
//  PortRow.swift
//  Containers
//
//  Created on 11/04/25.
//

import SwiftUI

struct PortRow: View {
    let port: Container.Port

    var body: some View {
        HStack {
            if let publicPort = port.publicPort {
                Text("\(publicPort):\(port.privatePort)/\(port.type)")
            } else {
                Text("\(port.privatePort)/\(port.type)")
            }

            if let ip = port.ip {
                Text("(\(ip))")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.body.monospaced())
        .padding(.bottom, 2)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    // Sample port for preview
    let samplePort = Container.Port(
        ip: "0.0.0.0",
        privatePort: 80,
        publicPort: 8080,
        type: "tcp"
    )

    return PortRow(port: samplePort)
        .padding()
}
