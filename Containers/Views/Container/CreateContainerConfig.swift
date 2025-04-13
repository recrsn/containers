//
//  CreateContainerConfig.swift
//  Containers
//
//  Created on 11/04/25.
//

import SwiftUI

struct CreateContainerConfig {
    var name: String = ""
    var image: String = ""
    var command: String = ""
    var environment: String = ""
    var ports: String = ""
    var startImmediately: Bool = true
}
