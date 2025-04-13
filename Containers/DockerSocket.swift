//
//  DockerSocket.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 13/04/25.
//

import Foundation

struct DockerSocket: Identifiable, Hashable, Codable {
    var id: UUID
    var name: String
    var path: String
    var description: String
    var socketType: SocketType

    enum SocketType: String, Codable, CaseIterable {
        case dockerDesktop
        case colima
        case podman
        case custom

        var defaultPath: String {
            switch self {
            case .dockerDesktop:
                return "/var/run/docker.sock"
            case .colima:
                return "~/.colima/default/docker.sock"
            case .podman:
                return "~/.local/share/containers/podman/machine/podman-machine-default/podman.sock"
            case .custom:
                return ""
            }
        }

        var description: String {
            switch self {
            case .dockerDesktop:
                return "Default Docker Desktop socket path"
            case .colima:
                return "Default Colima socket path"
            case .podman:
                return "Default Podman machine socket path"
            case .custom:
                return "Specify a custom Docker socket path"
            }
        }

        var displayName: String {
            switch self {
            case .dockerDesktop: return "Docker Desktop"
            case .colima: return "Colima"
            case .podman: return "Podman"
            case .custom: return "Custom"
            }
        }
    }

    init(id: UUID = UUID(), name: String, path: String, description: String, socketType: SocketType) {
        self.id = id
        self.name = name
        self.path = path
        self.description = description
        self.socketType = socketType
    }

    var isCustom: Bool {
        return socketType == .custom
    }
}
