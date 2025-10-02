//
//  Item.swift
//  DatabaseManager
//
//  Created by thierryH24 on 24/08/2025.
//

import Foundation
import SwiftData
import Observation
import OSLog

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
@MainActor
@Observable
final class PersonManager {
    
    
    static let shared = PersonManager()
    private let logger = Logger(subsystem: "DatabaseManager", category: "PersonManager")
    
    var persons: [Person] = []
    
    // Contexte et UndoManager actuels (fournis par ContainerManager via DataContext.shared)
    private var modelContext: ModelContext? { DataContext.shared.context }
    private var undoManager: UndoManager? { DataContext.shared.undoManager }

    private init () {}
    
    func reset() {
        persons.removeAll()
    }
    
    // MARK: - Create
    @discardableResult
    func create(name: String, town: String, age: Int) -> Person {
        let person = Person(name: name, town: town, age: age)
        guard let context = modelContext else {
            logger.error("ModelContext missing in create(); returning unsaved Person.")
            return person
        }
        
        context.undoManager = undoManager
        context.undoManager?.beginUndoGrouping()
        context.undoManager?.setActionName(String(localized: "Add Person"))
        context.insert(person)
        context.undoManager?.endUndoGrouping()
        
        do {
            try context.save()
        } catch {
            // Log technique; tu peux remplacer par OSLog si tu préfères
            logger.error("Error saving after create Person: \(error.localizedDescription, privacy: .public)")
        }
        return person
    }
    
    // MARK: - Update
    func update(person: Person, name: String, town: String, age: Int) {
        guard let context = modelContext else {
            logger.error("ModelContext missing in update(); aborting.")
            return
        }
        
        let oldName = person.name
        let oldTown = person.town
        let oldAge  = person.age
        
        context.undoManager = undoManager
        context.undoManager?.beginUndoGrouping()
        context.undoManager?.setActionName(String(localized: "Edit Person"))
        
        person.name = name
        person.town = town
        person.age  = age
        
        context.undoManager?.registerUndo(withTarget: person) { target in
            target.name = oldName
            target.town = oldTown
            target.age  = oldAge
            do {
                try context.save()
            } catch {
                self.logger.error("Error saving after undo edit Person: \(error.localizedDescription, privacy: .public)")
            }
        }
        
        context.undoManager?.endUndoGrouping()
        do {
            try context.save()
        } catch {
            logger.error("Error saving after update Person: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    // MARK: - Delete
    func delete(person: Person) {
        guard let context = modelContext else {
            logger.error("ModelContext missing in delete(); aborting.")
            return
        }
        
        context.undoManager = undoManager
        context.undoManager?.beginUndoGrouping()
        context.undoManager?.setActionName(String(localized: "Delete Person"))
        context.delete(person)
        context.undoManager?.endUndoGrouping()
        
        do {
            try context.save()
        } catch {
            logger.error("Error saving after delete Person: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    // MARK: - Fetch
    func fetchAll(sortedBy sortDescriptors: [SortDescriptor<Person>] = [SortDescriptor(\Person.name, order: .forward)]) -> [Person] {
        guard let context = modelContext else {
            logger.error("ModelContext missing in fetchAll(); returning empty list.")
            return []
        }
        
        let descriptor = FetchDescriptor<Person>(
            predicate: nil,
            sortBy: sortDescriptors
        )
        do {
            persons =  try context.fetch(descriptor)
        } catch {
            logger.error("Error fetching Persons: \(error.localizedDescription, privacy: .public)")
            return []
        }
        return persons
    }
}

