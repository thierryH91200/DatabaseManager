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
    var town: String
    var age: Int
    var createdAt: Date
    
    init(name: String, town: String, age: Int) {
        self.name = name
        self.town = town
        self.age = age
        self.createdAt = Date()
    }
}

// MARK: - Repository (stateless) pour Person
final class PersonManager: ObservableObject {
    
    static let shared = PersonManager()
    
    // Contexte et UndoManager actuels (fournis par ContainerManager via DataContext.shared)
    private var modelContext: ModelContext? { DataContext.shared.context }
    private var undoManager: UndoManager? { DataContext.shared.undoManager }
    
    private init () {}
    
    // MARK: - Create
    @discardableResult
    func create(name: String, town: String, age: Int) -> Person {
        let person = Person(name: name, town: town, age: age)
        guard let context = modelContext else { return person }
        
        context.undoManager = undoManager
        context.undoManager?.beginUndoGrouping()
        context.undoManager?.setActionName(String(localized: "Add Person"))
        context.insert(person)
        context.undoManager?.endUndoGrouping()
        
        do {
            try context.save()
        } catch {
            // Log technique; tu peux remplacer par OSLog si tu préfères
            print("❌ Error saving after create Person:", error)
        }
        return person
    }
    
    // MARK: - Update
    func update(person: Person, name: String, town: String, age: Int) {
        guard let context = modelContext else { return }
        
        let oldName = person.name
        let oldTown = person.town
        let oldAge  = person.age
        
        context.undoManager = undoManager
        context.undoManager?.beginUndoGrouping()
        context.undoManager?.setActionName(String(localized: "Edit Person"))
        
        person.name = name
        person.town = town
        person.age  = age
        
        // Optionnel: enregistrer un undo ciblé si tu souhaites un contrôle fin
        context.undoManager?.registerUndo(withTarget: person) { target in
            target.name = oldName
            target.town = oldTown
            target.age  = oldAge
            do {
                try context.save()
            } catch {
                print("❌ Error saving after undo edit Person:", error)
            }
        }
        
        context.undoManager?.endUndoGrouping()
        do {
            try context.save()
        } catch {
            print("❌ Error saving after update Person:", error)
        }
    }
    
    // MARK: - Delete
    func delete(person: Person) {
        guard let context = modelContext else { return }
        
        context.undoManager = undoManager
        context.undoManager?.beginUndoGrouping()
        context.undoManager?.setActionName(String(localized: "Delete Person"))
        context.delete(person)
        context.undoManager?.endUndoGrouping()
        
        do {
            try context.save()
        } catch {
            print("❌ Error saving after delete Person:", error)
        }
    }
    
    // MARK: - Fetch
    func fetchAll(sortedBy sortDescriptors: [SortDescriptor<Person>] = [SortDescriptor(\Person.name, order: .forward)]) -> [Person] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<Person>(
            predicate: nil,
            sortBy: sortDescriptors
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ Error fetching Persons:", error)
            return []
        }
    }
}

// MARK: - Contexte global (fourni par ContainerManager)
final class DataContext {
    static let shared = DataContext()
    
    var context: ModelContext?
    var undoManager: UndoManager? = UndoManager()

    private init() {}
}
