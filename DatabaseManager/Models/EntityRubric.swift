//
//  EntityRubric.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
////

import AppKit
import SwiftData
import SwiftUI



@Model
final class EntityRubric: Identifiable {
    
    var name: String = ""
    @Attribute(.transformable(by: ColorTransformer.self)) var color: NSColor
    @Attribute(.ephemeral) var total: Double = 0.0
    
    @Relationship(deleteRule: .cascade) var categorie : [EntityCategory] = []
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }
    
    @Relationship var account: EntityAccount
    
    init( name: String, color: NSColor, account: EntityAccount) {
        self.name = name
        self.color = color
        self.categorie = []
        self.uuid = UUID()
        self.account = account
    }
}

extension EntityRubric: CustomStringConvertible {
    public var description: String {
        "EntityRubric(name: \(name), total: \(total), account: \(account.name), uuid: \(uuid))"
    }
}

final class RubricManager {
    
    static let shared = RubricManager()
    
    var currentAccount: EntityAccount {
        CurrentAccountManager.shared.getAccount()!
    }

    var entitiesRubric: [EntityRubric] = []
    
    // Contexte pour les modifications
   var modelContext: ModelContext? {
        DataContext.shared.context
    }
    
    private init() { }
    
    func findOrCreate(account: EntityAccount, name: String, color: NSColor) -> EntityRubric {
        if let existingRubric = find(account: account, name: name) {
            return existingRubric
        }
        
        let newRubric = EntityRubric(name: name, color: color, account: account)
        modelContext?.insert(newRubric)
        
        entitiesRubric.append(newRubric)
        return newRubric
    }

    func find(account: EntityAccount, name: String) -> EntityRubric? {
        let result = entitiesRubric.first { $0.account.id == account.id && $0.name == name }
        return result
    }
    
    func delete(entity: EntityRubric) {
        modelContext?.delete(entity)
        entitiesRubric.removeAll { $0.id == entity.id }
    }
    
    @discardableResult
    func getAllData(account: EntityAccount? = nil) -> [EntityRubric] {
               
        let lhs = currentAccount.uuid
        let predicate = #Predicate<EntityRubric>{ entity in entity.account.uuid == lhs }
        let sort = [SortDescriptor(\EntityRubric.name, order: .forward)]
        
        let fetchDescriptor = FetchDescriptor<EntityRubric>(
            predicate: predicate,
            sortBy: sort )
        
        do {
            entitiesRubric = try modelContext?.fetch(fetchDescriptor) ?? []

        } catch {
            printTag("Erreur lors de la récupération des données : \(error.localizedDescription)")
        }
        if entitiesRubric.isEmpty {
            defaultRubric(for : currentAccount  )
        }
        return entitiesRubric
    }
        
    func importCSV(from fileURL: URL) {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            printTag("Erreur de lecture du fichier")
            return
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard !lines.isEmpty else { return }

//        let account = currentAccount

        for (index, line) in lines.enumerated() {
            let columns = line.components(separatedBy: ";")

            if index == 0 { continue } // Ignorer l'en-tête

            if columns.count >= 5 {
                let rubriqueName = columns[0]
                let categoryName = columns[1]
                let objectif     = Double(columns[3]) ?? 0.0
                let nscolor      = colorFromName(columns[4])

                // 🔁 Trouve ou crée la rubrique (robuste même si non consécutif)
                let rubric = findOrCreate(account: currentAccount, name: rubriqueName, color: nscolor)

                // ✅ Ajouter une catégorie à cette rubrique
                let category = EntityCategory(name: categoryName, objectif: objectif, rubric: rubric)
                rubric.categorie.append(category)
            }
        }

        do {
            try modelContext?.save()
        } catch {
            printTag("Erreur lors de la sauvegarde : \(error)")
        }
    }
    
    func defaultRubric(for account: EntityAccount) {
        guard let url = Bundle.main.url(forResource: "rubrique", withExtension: "csv") else {
            printTag("Error: File not found. ressources : rubrique.csv")
            return
        }
        importCSV(from: url)
    }
    
    func save () throws {
        do {
            try modelContext?.save()
        } catch {
            throw EnumError.saveFailed
        }
    }
}

