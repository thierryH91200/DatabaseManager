//
//  EntitySousOperations.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import SwiftUI
import SwiftData
import AppKit


@Model
final class EntitySousOperation: Identifiable {
    var amount: Double = 0.0
    var libelle: String? // Rend optionnel si nécessaire
    
    @Relationship(deleteRule: .nullify) var category: EntityCategory?
    @Relationship(deleteRule: .nullify) var transaction: EntityTransaction?
   
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    public init(libelle: String? = "Empty", amount: Double = 0.0, category: EntityCategory? = nil, transaction: EntityTransaction? = nil) {
        self.libelle = libelle
        self.amount = amount
        self.category = category
        self.transaction = transaction
    }
    public init() {}
    
    var amountString: String {
        let price = formatPrice(amount)
        return price
    }
    
    func copy(for transaction: EntityTransaction) -> EntitySousOperation {
        let newSous = EntitySousOperation()
        newSous.libelle = self.libelle
        newSous.amount = self.amount
        newSous.category = self.category
        newSous.transaction = transaction
        return newSous
    }
}

// SubTransactionsManager.swift
// PegaseUIData

import SwiftUI

final class SubTransactionsManager {
    static let shared = SubTransactionsManager()

    var subOperation: EntitySousOperation?

    var modelContext: ModelContext? {
        DataContext.shared.context
    }

    private init() { }

//    @MainActor
//    func createSubTransactions(
//        comment: String,
//        category: EntityCategory,
//        amount: String,
//        formState: TransactionFormState
//    ) {
//        guard let newSub = formState.currentSousTransaction else { return }
//
//        modelContext?.insert(newSub)
//        self.subOperation = newSub
//
//        update(comment: comment, category: category, amount: amount)
//
//        if let transaction = formState.currentTransaction, let sub = subOperation {
//            transaction.addSubOperation(sub)
//            formState.entityTransactions.append(transaction)
//        }
//
//        if formState.currentTransaction?.sousOperations == nil {
//            formState.currentTransaction?.sousOperations = []
//        }
//    }
   
    private func update(comment: String,
                        category: EntityCategory,
                        amount: String) {
        
        if let subOperation = subOperation {
            
            subOperation.libelle = comment
            subOperation.category = category
            if let value = Double(amount) {
                subOperation.amount = value
            } else {
                printTag("Erreur : Le montant saisi n'est pas valide")
            }
            //        subOperation.transaction = formState.currentTransaction
        }
    }
    
    // Suppression d'une entité
    func delete(entity: EntitySousOperation) {
        entity.transaction = nil
        modelContext?.delete(entity)
    }

}
