//
//  EntityCategory.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData
import SwiftUI
import Combine


@Model final class EntityCategory {

    var name: String
    var objectif: Double = 0.0

    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    @Relationship(inverse: \EntitySchedule.category) var echeancier: [EntitySchedule]?
    @Relationship(inverse: \EntityPreference.category) var preference: EntityPreference?
    
    var rubric: EntityRubric?
    @Relationship(inverse: \EntitySousOperation.category) var sousOperations: [EntitySousOperation]?
    
    public init(name: String, objectif : Double, rubric: EntityRubric) {
        self.name = name
        self.objectif = objectif
        self.rubric = rubric
        
        self.uuid = UUID()
    }
}

final class CategoryManager: ObservableObject {
    
    static let shared = CategoryManager()
     
    var modelContext: ModelContext? {
        DataContext.shared.context
    }

    init() {}
   
   func findOrCreate(account: EntityAccount,
                      name: String,
                      objectif: Double,
                      rubric: EntityRubric ) -> EntityCategory {
        
//        let account = CurrentAccountManager.shared.getAccount()!

       if let existingCategory = find(name: name) {
            return existingCategory
        } else {
            let newCategory = EntityCategory(name: name, objectif: objectif, rubric: rubric)
            modelContext?.insert(newCategory) // Ajoute l'entité au contexte
            return newCategory
        }
    }
    
//    Explication :
//
//    On filtre d’abord sur category.name == name (simple, accepté par SwiftData).
//    Ensuite, on refiltre en Swift pour rubric?.account.uuid == lhs.
//    func find(name: String) -> EntityCategory? {
//        guard let modelContext = modelContext else { return nil }
//
//        let account = CurrentAccountManager.shared.getAccount()!
//        let lhs = account.uuid
//
//        let predicate: Predicate<EntityCategory> = #Predicate { category in
//            category.name == name
//        }
//        let sort = [SortDescriptor(\EntityCategory.name, order: .forward)]
//        let descriptor = FetchDescriptor<EntityCategory>(
//            predicate: predicate,
//            sortBy: sort
//        )
//
//        do {
//            let results = try modelContext.fetch(descriptor)
//            return results.firstMatchingAccount(account)
//        } catch {
//            printTag("Erreur durant la récupération SwiftData: \(error)")
//            return nil
//        }
//    }
    
    func find(name: String) -> EntityCategory? {
        guard let modelContext = modelContext else { return nil }

        let account = CurrentAccountManager.shared.getAccount()!
        let descriptor = FetchDescriptor.byName(name)

        let results = SwiftDataHelper.fetchAll(from: modelContext, descriptor: descriptor)
        return results.firstMatchingAccount(account)
    }
    
    func findWithRubric(account: EntityAccount, rubric: EntityRubric, name: String) -> EntityCategory? {
        // Supposons que 'category' soit un tableau d'EntityCategory
        let categories = rubric.categorie       // Accès direct, sans conversion
        return categories.first { $0.name == name } ?? categories.first
    }
    
    func delete(entity: EntityCategory, undoManager: UndoManager?) {
        
        guard let modelContext = modelContext else { return }

        modelContext.undoManager = undoManager
        modelContext.undoManager?.beginUndoGrouping()
        modelContext.undoManager?.setActionName("Delete Category")
        modelContext.delete(entity)
        modelContext.undoManager?.endUndoGrouping()
    }
}

extension Sequence where Element == EntityCategory {
    func filtered(byAccount account: EntityAccount) -> [EntityCategory] {
        let accountUUID = account.uuid
        return self.filter { $0.rubric?.account.uuid == accountUUID }
    }

    func firstMatchingAccount(_ account: EntityAccount) -> EntityCategory? {
        return self.filtered(byAccount: account).first
    }
}

extension FetchDescriptor<EntityCategory> {
    static func byName(_ name: String, limit: Int? = nil) -> FetchDescriptor<EntityCategory> {
        let predicate: Predicate<EntityCategory> = #Predicate { category in
            category.name == name
        }

        var descriptor = FetchDescriptor<EntityCategory>(
            predicate: predicate,
            sortBy: [SortDescriptor(\EntityCategory.name, order: .forward)]
        )

        if let limit {
            descriptor.fetchLimit = limit
        }

        return descriptor
    }
}

struct SwiftDataHelper {
    static func fetchFirst<T: PersistentModel>(
        from modelContext: ModelContext,
        descriptor: FetchDescriptor<T>
    ) -> T? {
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            printTag("Erreur lors du fetch SwiftData : \(error)")
            return nil
        }
    }

    static func fetchAll<T: PersistentModel>(
        from modelContext: ModelContext,
        descriptor: FetchDescriptor<T>
    ) -> [T] {
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            printTag("Erreur lors du fetch SwiftData : \(error)")
            return []
        }
    }
}

