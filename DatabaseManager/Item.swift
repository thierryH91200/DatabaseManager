//
//  Item.swift
//  DatabaseManager
//
//  Created by thierryH24 on 24/08/2025.
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
