//
//  Untitled.swift
//  PegaseUIData
//
//  Created by thierryH24 on 16/08/2025.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@Model
final class EntityFolderAccount: Identifiable  {
    
    var name: String = ""
    var nameImage: String = "folder.fill"
    var isRoot : Bool = false

    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }
    
//    @Relationship(deleteRule: .cascade, inverse: \EntityAccount.folder)
    var children: [EntityAccount] = []
    
    public init() {
    }
    
    public init(name: String, isRoot: Bool, children: [EntityAccount]) {
        self.name = name
//        self.isRoot = isRoot
        self.children = children
    }
}

extension EntityFolderAccount {
    var childrenSorted: [EntityAccount] {
        children.sorted { $0.name < $1.name }
    }
}

extension EntityFolderAccount {
    func addAccounts(_ accounts: [EntityAccount]) {
        for account in accounts {
            self.addChild(account)
        }
    }
    
    func addChild(_ child: EntityAccount) {
        if children.isEmpty == true {
            children = []
        }
        children.append(child)
    }
}


final class AccountFolderManager {
    
    static let shared = AccountFolderManager()
    @Published var folderAccount = [EntityFolderAccount]()
    
    var modelContext: ModelContext? {
        DataContext.shared.context
    }
    
    init() { }
    
    func getAllData() -> [EntityFolderAccount] {
        
        let predicate =  #Predicate<EntityFolderAccount>{ _ in true }
        let sort = [SortDescriptor(\EntityFolderAccount.name, order: .forward)]
        
        let fetchDescriptor = FetchDescriptor<EntityFolderAccount>(
            predicate: predicate,
            sortBy: sort )

        do {
            folderAccount = try modelContext?.fetch(fetchDescriptor) ?? []
            return folderAccount
        } catch {
            printTag("Erreur lors de la récupération des données avec SwiftData")
        }
        return folderAccount
    }
    
    func getRoot(modelContext: ModelContext) -> [EntityFolderAccount] {
        // NOTE: Current logic filters non-root items; keep this if you rely on it for preload decisions.
        let request = FetchDescriptor<EntityFolderAccount>(
            predicate: #Predicate { $0.isRoot == false }
        )
        do {
            let entities = try modelContext.fetch(request)
            return entities
        } catch {
            printTag("Erreur lors du fetch des dossiers (getRoot): \(error.localizedDescription)")
            return []
        }
    }
    
    func preloadDataIfNeeded(modelContext: ModelContext) {
        // Vérifie si des données existent déjà
        let existingFolders = try? modelContext.fetch(FetchDescriptor<EntityFolderAccount>())
        guard existingFolders?.isEmpty == true else { return }
        
        // Ajout de données d'exemple
        let folder1 = EntityFolderAccount()
        folder1.name = String(localized:"Bank Account",table : "Account")
        
        var account1 = AccountFactory.createAccount(
            modelContext: modelContext,
            name: String(localized:"Current account1"),
            icon: "dollarsign.circle")
        account1 = AccountFactory.createOptionAccount(
            modelContext: modelContext,
            account: account1,
            idName: "Martin",
            idSurName: "Pierre",
            numAccount: "00045700E")
        
        var account2 = AccountFactory.createAccount(
            modelContext: modelContext,
            name: String(localized:"Current account2"),
            icon: "eurosign.circle")
        account2 = AccountFactory.createOptionAccount(
            modelContext: modelContext,
            account: account2,
            idName: "Martin",
            idSurName: "Marie",
            numAccount: "00045701F")
        
        folder1.children = [
            account1, account2 ]
        
        let folder2 = EntityFolderAccount()
        folder2.name = String(localized:"Save",table : "Account")
        
        var account3 = AccountFactory.createAccount(
            modelContext: modelContext,
            name: String(localized:"Current account3"),
            icon: "calendar.circle")
        account3 = AccountFactory.createOptionAccount(
            modelContext: modelContext,
            account: account3,
            idName: "Durand",
            idSurName: "Jean",
            numAccount: "00045703H")
        
        folder2.children = [
            account3 ]
        
        // Enregistrer les dossiers
        modelContext.insert(folder1)
        modelContext.insert(folder2)
        
        try? modelContext.save()
    }

}
