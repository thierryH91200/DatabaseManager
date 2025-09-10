//
//  EntityIdentity.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Identite

@Model
final class EntityIdentity : Identifiable{
    var adress     : String  = ""
    var complement : String  = ""
    var country    : String  = ""
    var cp         : String  = ""
    var email      : String  = ""
    var mobile     : String  = ""
    var name       : String  = "Dupont"
    var nameImage  : String  = ""
    var phone      : String  = ""
    var surName    : String  = "leon"
    var town       : String  = ""
    
    @Attribute(.unique) var uuid: UUID = UUID()
    
    @Relationship var account    : EntityAccount
    
    @MainActor
    public init(adress: String,
                complement : String,
                country: String,
                cp: String,
                email: String,
                mobile: String,
                name: String,
                nameImage : String,
                phone: String,
                surName: String,
                town: String) {
        self.adress = adress
        self.complement = complement
        self.country = country
        self.cp = cp
        self.email = email
        self.mobile = mobile
        self.name = name
        self.nameImage = nameImage
        self.phone = phone
        self.surName = surName
        self.town = town
        
        self.account = CurrentAccountManager.shared.getAccount()!
    }
    
    public init(name: String, surName: String, account : EntityAccount) {
        self.name = name
        self.surName = surName
        self.account = account
    }
    
    @MainActor
    init() {
        self.account = CurrentAccountManager.shared.getAccount()!
    }
}

// ObservableObject
final class IdentityManager: ObservableObject  {
    
    // Contexte pour les modifications
    static let shared = IdentityManager()
    
    @Published var identities = [EntityIdentity]()
    
    var modelContext: ModelContext? {
        DataContext.shared.context
    }

    init() {
    }
    
    @MainActor
    func create(name: String = "", surName: String = "") -> EntityIdentity {

        let currentAccount = CurrentAccountManager.shared.getAccount()!
        let entity = EntityIdentity(name: name, surName: surName, account: currentAccount)
        
        // Ajout de l'entité au contexte
        modelContext?.insert(entity)
        return entity
    }
    
    @discardableResult
    @MainActor
    func getAllData() -> EntityIdentity? {
        // Filtre pour l'entité liée à `currentAccount`
        
        guard let currentAccount = CurrentAccountManager.shared.getAccount() else {
            printTag("Erreur : aucun compte courant trouvé.")
            return nil
        }
        
        do {
            let lhs = currentAccount.uuid
            let predicate = #Predicate<EntityIdentity>{ entity in entity.account.uuid == lhs }
            let sort = [SortDescriptor(\EntityIdentity.name, order: .forward)]

            // Utilisation de SwiftData pour récupérer les entités correspondantes
            let fetchDescriptor = FetchDescriptor<EntityIdentity>(
                predicate: predicate,
                sortBy: sort )
            
            identities = try modelContext?.fetch(fetchDescriptor) ?? []
            
        } catch {
            printTag("Erreur lors de la récupération des données : \(error.localizedDescription)")
            return nil
        }
        return identities.first
    }
}

