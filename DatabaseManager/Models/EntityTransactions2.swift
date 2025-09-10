//
//  EntityTransactions.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import SwiftUI
import SwiftData
import AppKit
import Combine


protocol ListManaging {
//    func createTransactions(formState: TransactionFormState) -> EntityTransaction
    func find(uuid: UUID) -> EntityTransaction?
    func getAllComments(for account: EntityAccount) throws -> [String]

}

final class ListTransactionsManager: ListManaging {
    
//    @EnvironmentObject var formState: TransactionFormState

    static let shared = ListTransactionsManager()
    
    var listTransactions : [EntityTransaction] = []
    
    var ascending = false
    
    var modelContext: ModelContext? {
        DataContext.shared.context
    }

    init() { }
    
    @discardableResult
//    func createTransactions(formState: TransactionFormState) -> EntityTransaction {
//        // Create entityTransaction
//        formState.currentTransaction = EntityTransaction()
//        formState.currentTransaction?.createAt = Date().noon
//        formState.currentTransaction?.updatedAt = Date().noon
//        formState.currentTransaction?.uuid = UUID()
//        let account = CurrentAccountManager.shared.getAccount()!
//        formState.currentTransaction?.account = account
//        
//        modelContext!.insert(formState.currentTransaction!)
//
//        return formState.currentTransaction!
//    }
    
    func find(uuid: UUID) -> EntityTransaction? {
        // Création du prédicat pour filtrer les transactions par UUID
        let predicate = #Predicate<EntityTransaction> { $0.uuid == uuid }

        // Création du FetchDescriptor pour récupérer une entité correspondant à l'UUID
        let fetchDescriptor = FetchDescriptor<EntityTransaction>(
            predicate: predicate
        )

        do {
            // Récupération des entités correspondant au prédicat
            let results = try modelContext?.fetch(fetchDescriptor) ?? []
            
            // Retourner le premier résultat, s'il existe
            return results.first
        } catch {
            printTag("Erreur lors de la récupération des données avec SwiftData : \(error)")
            return nil
        }
    }
    
    func getAllComments(for account: EntityAccount) throws -> [String] {
        var comments = [String]()
        
        let lhs = account.uuid
        let predicate = #Predicate<EntityTransaction>{ transaction in transaction.account.uuid == lhs }
        let sort = [SortDescriptor(\EntityTransaction.dateOperation, order: .reverse)]
        
        let descriptor = FetchDescriptor<EntityTransaction>(
            predicate: predicate,
            sortBy: sort )

        // Fetch les transactions liées à l'account
        do {
            // Fetch transactions with error handling
            let entityTransactions = try modelContext?.fetch(descriptor) ?? []
            
            // Process transactions and their split operations
            for entityTransaction in entityTransactions {
                let splitTransactions = entityTransaction.sousOperations
                    let splitComments = splitTransactions.compactMap { $0.libelle }
                    comments.append(contentsOf: splitComments)
            }
            
            // Return unique comments
            return comments.uniqueElements
        } catch {
            throw error  // Or handle the error as needed for your use case
        }
    }

    func getAllData(from startDate: Date? = nil, to endDate: Date? = nil, ascending: Bool = true) -> [EntityTransaction] {
        let all = loadAllTransactions(ascending: ascending) // Méthode qui charge toutes les transactions
        guard let start = startDate, let end = endDate else {
            return all
        }
        return all.filter { $0.datePointage >= start && $0.datePointage <= end }
    }
    
    // MARK: getAllData
    func loadAllTransactions( ascending: Bool = true) -> [EntityTransaction] {

        let currentAccount = CurrentAccountManager.shared.getAccount()
        guard let currentAccount = currentAccount else {
            return []
        }
        self.ascending = ascending
        
        // Création du prédicat pour filtrer les transactions par compte
        let currentAccountID = currentAccount.uuid
        let predicate = #Predicate<EntityTransaction> { $0.account.uuid == currentAccountID }
        let sort = [ SortDescriptor(\EntityTransaction.datePointage, order: ascending ? .forward : .reverse) ]

        // Création du FetchDescriptor avec les tri par datePointage et dateOperation
        let fetchDescriptor = FetchDescriptor<EntityTransaction>(
            predicate: predicate,
            sortBy: sort )

        do {
            // Récupération des entités depuis le contexte
            listTransactions = try modelContext?.fetch(fetchDescriptor) ?? []
        } catch {
            printTag("Erreur lors de la récupération des données avec SwiftData : \(error)")
            return []
        }

        // Ajuste les dates si le compte est en mode démo
        if currentAccount.isDemo {
            adjustDate(for: currentAccount)
        }
        return listTransactions
    }

    // MARK: remove Transaction
    @MainActor
    func delete(entity: EntityTransaction) {
        guard let modelContext else {
            printTag("Container invalide.")
            return
        }
        modelContext.undoManager?.beginUndoGrouping()
        modelContext.undoManager?.setActionName("Delete the transaction")
        modelContext.delete(entity)
        modelContext.undoManager?.endUndoGrouping()
        
        do {
            try modelContext.save()
            printTag("✅ L'entité a été supprimée avec succès.")
        } catch {
            printTag("❗ Erreur lors de la suppression: \(error)")
        }
    }
    
    func printTransactions() {
        for entity in listTransactions {
            print(entity.datePointage)
            print(entity.dateOperation)
            print(entity.status?.name ?? "no status")
            print(entity.paymentMode?.name ?? "defaultMode")
            let subs = entity.sousOperations
            for sub in subs {
                print(sub.libelle ?? "Sans libellé")
                print(sub.category?.name ?? "Cat def")
                print(sub.category?.rubric!.name ?? "Rub def")
                print(sub.amount)
            }
        }
    }

    func adjustDate (for account: EntityAccount) {
        let currentAccount = account

        guard listTransactions.isEmpty == false else {return}
        let diffDate = (listTransactions.first?.datePointage.timeIntervalSinceNow)!
        for entity in listTransactions {
            entity.datePointage  = (entity.datePointage  - diffDate).noon
            entity.dateOperation = (entity.dateOperation - diffDate).noon
        }
        currentAccount.isDemo = false
    }
    
//    func clearCache(for account: EntityAccount) async {
//        await cache.invalidate(key: account.uuid)
//    }
//    
//    func clearAllCache() async {
//        await cache.invalidateAll()
//    }
}

class ListTransactionsViewModel: ObservableObject {
    @Published var account: EntityAccount
    @Published var listTransactions: [EntityTransaction]
    private let manager: ListTransactionsManager
    
    init(account: EntityAccount, manager: ListTransactionsManager) {
        self.account = account
        self.manager = manager
        self.listTransactions = []
        
        loadInitialData()
    }

    private func loadInitialData() {
        listTransactions = manager.getAllData()
    }

}

