//
//  EntityPreference.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@Model final class EntityPreference {
    
    var signe       : Bool = true
    var status      : EntityStatus?
    var category    : EntityCategory?
    var paymentMode : EntityPaymentMode?
      
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }
    
    @Relationship var account: EntityAccount

    init(account: EntityAccount,
                category: EntityCategory? = nil,
                paymentMode: EntityPaymentMode? = nil,
                status: EntityStatus? = nil) {
        
        self.category    = category
        self.paymentMode = paymentMode
        self.status      = status
        self.signe       = true
        
        self.account     = account
    }
}

protocol PreferenceManaging {

    func defaultPref(account: EntityAccount) -> EntityPreference?
    func getAllData(for account: EntityAccount?) -> EntityPreference?
    func saveContext()
}

// MARK: preferenceManager
final class PreferenceManager: PreferenceManaging {
    
    static let shared = PreferenceManager()
    
    var entityPreferences : [EntityPreference]?
    
    var modelContext: ModelContext? {
        DataContext.shared.context
    }

    private init() { }
    
    // MARK: - default
    func defaultPref(account: EntityAccount) -> EntityPreference? {
        // Vérifie si une préférence existe déjà
        if let existingPreference = getAllData(for: account) {
            return existingPreference
        }

        let newPreference = EntityPreference(account: account)
        
        if newPreference.category == nil,
           let rubric = RubricManager.shared.getAllData(account: account).first {
            if let category = rubric.categorie.sorted(by: { $0.name < $1.name }).first {
                newPreference.category = category
            }
        }
        
        newPreference.paymentMode = PaymentModeManager.shared.getAllData()?.first

        let rubrics = RubricManager.shared.getAllData(account: account)
        if let firstRubric = rubrics.first {
            newPreference.category = firstRubric.categorie.first
            newPreference.category?.rubric = firstRubric
        }
        
        // Configuration de status
        newPreference.status = StatusManager.shared.getAllData(for: account)?.first

        newPreference.signe = true
        newPreference.account = account
        
        modelContext?.insert(newPreference)
        entityPreferences?.append(newPreference) // Mise à jour du cache local
        
        saveContext()
        return newPreference
    }
    
    func getAllData(for account: EntityAccount?) -> EntityPreference? {
        guard let account = account else {
            printTag("Preference : Erreur : Account est nil")
            return nil
        }
        let accountID = account.uuid
        let predicate = #Predicate<EntityPreference> { entity in entity.account.uuid == accountID }
        let fetchDescriptor = FetchDescriptor<EntityPreference>(predicate: predicate)
        
        do {
            entityPreferences = try modelContext?.fetch(fetchDescriptor) ?? []
        } catch {
            printTag("Erreur lors de la récupération des données : \(error.localizedDescription)")
        }
        return entityPreferences?.first
    }
    func update(status: EntityStatus,
                mode: EntityPaymentMode,
                rubric: EntityRubric,
                category: EntityCategory,
                preference: EntityPreference,
                sign : Bool) async throws {
        
        preference.status = status
        preference.paymentMode = mode
        preference.category?.rubric = rubric
        preference.category = category
        preference.signe = sign

        saveContext()
    }
    
    func saveContext() {
        do {
            try modelContext?.save()
        } catch {
            if let path = getSQLiteFilePath() {
                printTag("Erreur de sauvegarde. Base de données SQLite : \(path)")
            }
            printTag("Erreur lors de la sauvegarde : \(error.localizedDescription)")
        }
    }
}

func getSQLiteFilePath() -> String? {
    guard let _ = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last else { return nil}
    
    if let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
        let path = "Core Data SQLite file is located at: \(url.path)"
        return path
    }
    return nil
}
