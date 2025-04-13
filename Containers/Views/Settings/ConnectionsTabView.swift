//
//  ConnectionsTabView.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 12/04/25.
//

import SwiftUI

struct ConnectionsTabView: View {
    @Environment(DockerSettings.self) private var settings
    @Environment(DockerContext.self) private var connectionContext

    @State private var isShowingAddSheet = false
    @State private var isShowingEditSheet = false
    @State private var selectedConnection: DockerSocket?

    var body: some View {
        HStack(alignment: .top) {
            GroupBox {
                List(selection: $selectedConnection) {
                    Section {
                        ForEach(settings.connections) {
                            connection in
                            VStack(alignment: .leading) {
                                Text(connection.name)

                                Text(connection.path)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(connection)
                        }
                    } header: {
                        Text("Connections")
                    }
                }
                .listStyle(.plain)

                HStack {
                    Button(action: {
                        isShowingAddSheet = true
                    }) {
                        Label("Add connection", systemImage: "plus")
                    }

                    Button(action: {
                        if let connection = selectedConnection {
                            Task {
                                await settings.removeConnection(id: connection.id)
                                selectedConnection = nil
                            }
                        }
                    }) {
                        Label("Remove connection", systemImage: "minus")
                    }
                    .disabled(selectedConnection == nil)

                    Button(action: {
                        if selectedConnection != nil {
                            isShowingEditSheet = true
                        }
                    }) {
                        Label("Edit connection", systemImage: "pencil")
                    }
                    .disabled(selectedConnection == nil)

                    Spacer()
                }
                .buttonStyle(.borderless)
                .labelStyle(.iconOnly)
                .padding(8)
            }
            .frame(width: 200)
            .sheet(isPresented: $isShowingAddSheet) {
                ConnectionEditorView(isPresented: $isShowingAddSheet)
            }
            .sheet(isPresented: $isShowingEditSheet) {
                if let connection = selectedConnection {
                    ConnectionEditorView(
                        isPresented: $isShowingEditSheet,
                        existingConnection: connection
                    )
                }
            }

            // Right side - Connection details
            if let connection = selectedConnection {
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Connection Details")
                            .font(.headline)

                        Divider()

                        HStack {
                            Text("Name:")
                                .fontWeight(.medium)
                            Text(connection.name)
                        }

                        HStack {
                            Text("Type:")
                                .fontWeight(.medium)
                            Text(connection.socketType.displayName)
                        }

                        HStack {
                            Text("Path:")
                                .fontWeight(.medium)
                            Text(connection.path)
                                .textSelection(.enabled)
                        }

                        HStack {
                            Text("Description:")
                                .fontWeight(.medium)
                            Text(connection.description)
                        }

                        Spacer()

                        Button(action: {
                            isShowingEditSheet = true
                        }) {
                            Text("Edit Connection")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                GroupBox {
                    VStack {
                        Spacer()
                        Text("Select a connection or add a new one")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }.onAppear {
            selectedConnection = settings.connections.first
        }.padding()
    }
}

#Preview {
    ConnectionsTabView()
        .environment(DockerContext.preview)
}
