//
//  EntityDummy.swift
//  PegaseUIData
//
//  Created by thierryH24 on 19/10/2025.
//


import Foundation
import SwiftData

@Model
final class DummyModel {
    @Attribute(.unique) var id: UUID

    init() {
        self.id = UUID()
    }
}

// Singleton global pour centraliser le ModelContext et l'UndoManager.
final class DataContext {
    static let shared = DataContext()

    var container: ModelContainer?
    var context: ModelContext?
    var undoManager: UndoManager?

    private init() {}
}
