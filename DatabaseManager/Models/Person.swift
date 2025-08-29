//
//  Item.swift
//  DatabaseManager
//
//  Created by thierryH24 on 24/08/2025.
//

import Foundation
import SwiftData
import Combine

// MARK: - Modèle de données
@Model
class Person {
    var name: String
    var age: Int
    var createdAt: Date
    
    init(name: String, age: Int) {
        self.name = name
        self.age = age
        self.createdAt = Date()
    }
}

final class PersonManager: ObservableObject {
    
    static let shared = PersonManager()
    
    @Published var entitiesPerson = [Person]()
    
    var modelContext: ModelContext? {
        DataContext.shared.context
    }
    
    init () {
    }
    
    @discardableResult
    func create(name: String, age: Int) -> Person {
        let person = Person(name: name, age: age)
        modelContext?.insert(person)

        entitiesPerson.append(person)
        modelContext?.insert(person)
        return person
    }
    
    func getAllData() -> [Person] {
        
        entitiesPerson.removeAll()
        
        let predicate = #Predicate<Person> { _ in true }
        let sort = [SortDescriptor(\Person.name, order: .forward)]
        
        let descriptor = FetchDescriptor<Person>(
            predicate: predicate,
            sortBy: sort )
        
        do {
            entitiesPerson = try modelContext?.fetch(descriptor) ??   []
        } catch {
            print("Error fetching data from SwiftData: \(error)")
            return []
        }
        return entitiesPerson
    }
    
    func delete(entity: Person, undoManager: UndoManager?) {
        guard let context = modelContext else { return }

        context.undoManager = undoManager
        context.undoManager?.beginUndoGrouping()
        context.undoManager?.setActionName("Delete Person")
        context.delete(entity)
        context.undoManager?.endUndoGrouping()
    }
}

final class DataContext {
    static let shared = DataContext()
    @Published var persons = [Person]()

    var context: ModelContext?
    var undoManager: UndoManager? = UndoManager()

    init() {}
}


