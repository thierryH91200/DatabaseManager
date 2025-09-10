//
//  EntityInitAccount.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData
import SwiftUI


@Model final class EntityInitAccount {
    var bic: String = ""
    var cleRib: String = ""
    var codeAccount: String = ""
    var codeBank: String = ""
    var codeGuichet: String = ""
    
    var iban: String = ""

    var engage: Double = 0.0
    var prevu: Double = 0.0
    var realise: Double = 0.0

    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    @Relationship var account: EntityAccount
    
    public init(account : EntityAccount) {
        self.iban = "FR76"
        self.account = account
    }
}

final class InitAccountManager {
    
    static let shared = InitAccountManager()
    private var initAccounts = [EntityInitAccount]()
    private var initAccount : EntityInitAccount?

    // Contexte pour les modifications
    var currentAccount: EntityAccount? {
        CurrentAccountManager.shared.getAccount()
    }
    
    var modelContext: ModelContext? {
        DataContext.shared.context
    }

    init() {
    }

    // Utiliser un seul contexte pour la gestion des données
    func getAllData() -> EntityInitAccount? {
        
        guard let account = CurrentAccountManager.shared.getAccount() else {
            printTag("Erreur : aucun compte courant trouvé.")
            return nil
        }

        let lhs = account.uuid
        let predicate = #Predicate<EntityInitAccount>{ entity in entity.account.uuid == lhs }
        let sort = [SortDescriptor(\EntityInitAccount.codeAccount)]

        let descriptor = FetchDescriptor<EntityInitAccount>(
            predicate: predicate,
            sortBy: sort )

        do {
            initAccounts = try modelContext?.fetch(descriptor) ?? []
        } catch {
            printTag("Erreur lors de la récupération des données")
        }
        
        if let firstEntity = initAccounts.first {
            return firstEntity
        } else {
            do {
                return try create(numAccount: "", for: account)
            } catch {
                printTag("Erreur lors de la création d'une entité : \(error)")
                fatalError("Impossible de créer une entité, vérifiez la logique de gestion des erreurs.")
            }
        }
    }

    // Méthode de création d'entité
    func create(numAccount: String = "", for account: EntityAccount) throws -> EntityInitAccount {
        let entity = EntityInitAccount(account: account)
        
        entity.codeAccount = numAccount
        
        modelContext?.insert(entity)
        initAccounts.append(entity) // Mise à jour de la liste locale
        
        return entity
    }
    
    func delete(entityInitAccount: EntityInitAccount) {
        
        modelContext?.delete( entityInitAccount)
        initAccount = nil
 
        initAccount = getAllData()      // Recharger depuis la base de données
    }
    
    func save () throws {
        
        do {
            try modelContext?.save()
        } catch {
            throw EnumError.saveFailed
        }
    }
}

