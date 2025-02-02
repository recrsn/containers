//
//  Item.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 02/02/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
