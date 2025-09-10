//
//  EntityPaymentMode.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import SwiftUI
import SwiftData
import Combine

@Model final class EntityPaymentMode: Identifiable , Hashable {
    
    var name: String = ""
    
    @Attribute(.transformable(by: ColorTransformer.self)) var color: NSColor
    
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }
    
    @Relationship var account: EntityAccount
    
    @MainActor
    init(name: String = "Test", color: NSColor = .black ) {
        guard let account = CurrentAccountManager.shared.getAccount() else {
            fatalError("Aucun compte disponible pour créer un mode de paiement")
        }

        self.name = name
        self.color = color
        self.account = account
    }

    // Implémentez `Hashable`
    public static func == (lhs: EntityPaymentMode, rhs: EntityPaymentMode) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

extension EntityPaymentMode: CustomStringConvertible {
    public var description: String {
        "EntityPaymentMode(name: \(name), color: \(color), uuid: \(uuid))"
    }
}

protocol PaymentModeManaging {
    
    func create(account: EntityAccount?, name: String, color: NSColor) throws -> EntityPaymentMode?
    func update(entity: EntityPaymentMode, name: String, color: NSColor)
    func getAllData() -> [EntityPaymentMode]?
    func getAllNames(for account: EntityAccount) -> [String]
    func findOrCreate(account: EntityAccount, name: String, color: Color, uuid: UUID) -> EntityPaymentMode
    func find( account: EntityAccount?, name: String) -> EntityPaymentMode?
    func delete(entity: EntityPaymentMode, undoManager: UndoManager?)
    func createDefaultPaymentModes(for account: EntityAccount)

    func save () throws
}

//Gère les opérations CRUD (Create, Read, Update, Delete)
//Interagit directement avec SwiftData
//Contient la logique métier complexe
//Est un singleton (shared)
//Gère les données par défaut
final class PaymentModeManager : PaymentModeManaging, ObservableObject {
    

    static let shared = PaymentModeManager()
    
    @Published var modePayments = [EntityPaymentMode]()
    
    var modelContext: ModelContext? {
        DataContext.shared.context
    }

    init() { }
    
    func create(account: EntityAccount?, name: String, color: NSColor) throws -> EntityPaymentMode? {
                
        let mode = EntityPaymentMode(name: name, color: color)
        modelContext?.insert(mode)
        try? modelContext?.save()
        return mode
    }

    func update(entity: EntityPaymentMode, name: String, color: NSColor) {
        entity.name = name
        entity.color = color
        do {
            try save()
        } catch {
            printTag("Failed to save updates: \(error.localizedDescription)")
        }
    }

    func getAllData() -> [EntityPaymentMode]? {
                
        let account = CurrentAccountManager.shared.getAccount()
        guard account != nil else {
            return []
        }

        let lhs = account!.uuid
        let predicate = #Predicate<EntityPaymentMode> { entity in entity.account.uuid == lhs }
        let sort = [SortDescriptor(\EntityPaymentMode.name, order: .forward)]
        
        let fetchDescriptor = FetchDescriptor<EntityPaymentMode>(
            predicate: predicate,
            sortBy: sort )
        
        do {
            let fetchedData = try modelContext?.fetch(fetchDescriptor) ?? []
            return fetchedData
        } catch {
            printTag("Error fetching data with SwiftData: \(error)")
            return []
        }
    }
    
    // MARK: getAllNames ModePaiement
    func getAllNames(for account: EntityAccount) -> [String] {
        
         return getAllData()?.map { $0.name } ?? []
    }

    // MARK: findOrCreate ModePaiement
   func findOrCreate(account: EntityAccount, name: String, color: Color, uuid: UUID) -> EntityPaymentMode {
        if let entity = find(account: account, name: name) {
            return entity
        } else {
            return try! create(account: account, name: name, color: NSColor.fromSwiftUIColor(color))!
        }
    }
    
    // MARK: find ModePaiement
    func find( account: EntityAccount? = nil, name: String) -> EntityPaymentMode? {
        
        guard let account = account ?? CurrentAccountManager.shared.getAccount() else {
            printTag("Aucun compte disponible pour la recherche.")
            return nil
        }
        
        let lhs = account.uuid
        let predicate = #Predicate<EntityPaymentMode> { $0.account.uuid == lhs && $0.name == name }
        let sort = [SortDescriptor(\EntityPaymentMode.name, order: .forward)] // Trier par le nom

        let fetchDescriptor = FetchDescriptor<EntityPaymentMode>(
            predicate: predicate, // Filtrer par le compte
            sortBy: sort )

        do {
            let searchResults = try modelContext?.fetch(fetchDescriptor) ?? []
            let result = searchResults.isEmpty == false ? searchResults.first : nil
            return result
        } catch {
            printTag("Error with request: \(error)")
            return nil
        }
    }
    
    // MARK: delete ModePaiement
    func delete(entity: EntityPaymentMode, undoManager: UndoManager?)
    {
        guard let modelContext = modelContext else { return }

        modelContext.undoManager = undoManager
        modelContext.undoManager?.beginUndoGrouping()
        modelContext.undoManager?.setActionName("Delete the Payment methods")
        modelContext.delete(entity)
        modelContext.undoManager?.endUndoGrouping()
    }

    // MARK: default ModePaiement
    
    func createDefaultPaymentModes(for account: EntityAccount) {
        modePayments.removeAll()
        
        // Liste des noms et couleurs des méthodes de paiement
        let names = [ String(localized :"Bank Card"),
                      String(localized :"Check"),
                      String(localized :"Cash"),
                      String(localized :"Bank withdrawal"),
                      String(localized :"Discount"),
                      String(localized :"Cash withdrawal"),
                      String(localized :"Bank transfer"),
                      String(localized :"Direct debit")]
        let paymentModes: [(name: String, color: NSColor)] = [
            ( names[0], .red),
            ( names[1], .green),
            ( names[2], .yellow),
            ( names[3], .blue),
            ( names[4], .red),
            ( names[5], .gray),
            ( names[6], .brown),
            ( names[7], .black)
        ]
        
        // Création des entités de mode de paiement
        paymentModes.forEach {
            do {
                try _ = create(account: account, name: $0.name, color: $0.color)
            } catch {
                printTag("Erreur création par défaut : \(error)")
            }
        }
               
        let lhs = account.uuid
        let predicate = #Predicate<EntityPaymentMode>{ entity in entity.account.uuid == lhs }
        let sort = [SortDescriptor(\EntityPaymentMode.name, order: .forward)]
                
        let fetchDescriptor = FetchDescriptor<EntityPaymentMode>(
            predicate: predicate,
            sortBy: sort )
        
        // Récupération des entités EntityPaymentMode liées au compte actuel
        do {
            modePayments = try modelContext?.fetch(fetchDescriptor) ?? []
        } catch {
            printTag("Erreur lors de la récupération des modes de paiement : \(error.localizedDescription)")
        }
    }
    
    // MARK: save ModePaiement
    func save () throws {
        do {
            try modelContext?.save()
        } catch {
            throw EnumError.saveFailed
        }
    }
}

