//
//  EntityCheckBook.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData
import SwiftUI
import Combine


@Model public class EntityCheckBook {
    var name: String = ""
    var nbCheques: Int = 25
    var numPremier: Int = 1
    var numSuivant: Int = 10
    var prefix: String = "CH"
    
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    @Relationship var account: EntityAccount?
    
    init(name: String,
                nbCheques: Int,
                numPremier: Int,
                numSuivant: Int,
                prefix: String,
                account: EntityAccount) {
        
        self.name = name
        self.nbCheques = nbCheques
        self.numPremier = numPremier
        self.numSuivant = numSuivant
        self.prefix = prefix
        
        self.account = account
    }
  
    init() {
        // Avoid accessing @MainActor singletons here; let the manager inject the account.
        self.account = nil
    }
}

extension EntityCheckBook {

    var accountName: String {
        account?.identity?.name ?? ""
    }
    
    var accountSurname: String {
        account?.identity?.surName ?? ""
    }
}


// Responsabilités d’un Manager :
//    •    CRUD (Create, Read, Update, Delete) pour les entités.
//    •    Gestion des relations complexes entre les entités (ex. relation entre EntityCarnetCheques et EntityAccount).
//    •    Gestion des erreurs ou des validations métier.
//    •    Interaction avec des services tiers (APIs, bases de données, fichiers, etc.).
//    •    Gestion des états globaux liés à l’application.
final class ChequeBookManager : ObservableObject {
    
    static let shared = ChequeBookManager()
    
    @Published var checkBooks = [EntityCheckBook]()
        
    var modelContext: ModelContext? {
        DataContext.shared.context
    }

    init() {}
    
    @discardableResult
    func create(name: String,
                nbCheques: Int = 25,
                numPremier: Int = 1,
                numSuivant: Int = 1,
                prefix: String = "CH") -> EntityCheckBook? {
        // Créez une instance de EntityCarnetCheques
        guard let account = CurrentAccountManager.shared.getAccount() else {
            printTag("Aucun compte actif pour créer un carnet de chèques")
            return nil
        }
        
        let entity = EntityCheckBook(
            name       : name,
            nbCheques  : nbCheques,
            numPremier : numPremier,
            numSuivant : numSuivant,
            prefix     : prefix,
            account    : account)
        
        modelContext?.insert(entity)
        
        // Sauvegardez le contexte
        save()
        return entity
    }

    func getAllData() -> [EntityCheckBook]? {
        
        guard let account = CurrentAccountManager.shared.getAccount() else {
            printTag("Erreur : aucun compte courant trouvé.")
            return nil
        }

        let lhs = account.uuid
        let predicate = #Predicate<EntityCheckBook> { entity in entity.account?.uuid == lhs  }
        let sort = [SortDescriptor(\EntityCheckBook.name, order: .forward)]
        
        let descriptor = FetchDescriptor<EntityCheckBook>(
            predicate: predicate,
            sortBy: sort )
        
        do {
            checkBooks = try modelContext?.fetch(descriptor) ??   []
        } catch {
            printTag("Error fetching data from SwiftData: \(error)")
            return []
        }
        return checkBooks
    }

    func update(entity: EntityCheckBook, name: String) {
        entity.name = name
        save() // Assurez-vous de sauvegarder le contexte après modification
    }

    func delete(entity: EntityCheckBook, undoManager: UndoManager? )
    {
        guard let modelContext = modelContext else { return }

        modelContext.undoManager = undoManager
        modelContext.undoManager?.beginUndoGrouping()
        modelContext.undoManager?.setActionName("Delete CheckBook")
        modelContext.delete(entity)
        modelContext.undoManager?.endUndoGrouping()
    }
    
    private func defaultCarnetCheques() {
        guard checkBooks.isEmpty else { return }
        
        let entityCarnetCheques = EntityCheckBook()
        entityCarnetCheques.name = "Check"
        entityCarnetCheques.prefix = "CH"
        entityCarnetCheques.numPremier = 1
        entityCarnetCheques.numSuivant = 15
        entityCarnetCheques.nbCheques = 25
        entityCarnetCheques.uuid = UUID()
        modelContext?.insert(entityCarnetCheques)
        
        do {
            try modelContext?.save()
            checkBooks.append(entityCarnetCheques)
        } catch {
            printTag("Error saving default Carnet Cheques: \(error)")
        }
    }
    
    func save () {
        do {
            try modelContext?.save()
        } catch {
            printTag("Erreur lors de la sauvegarde de l'entité : \(error)")
        }
    }
}
