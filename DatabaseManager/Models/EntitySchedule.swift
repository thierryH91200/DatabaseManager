//
//  EntitySchedule.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData
import SwiftUI
import Combine


@Model
final class EntitySchedule : Identifiable{
    var amount                   : Double = 0.0
    var dateCree                 : Date   = Date()
    var dateDebut                : Date   = Date()
    var dateFin                  : Date   = Date()
    var dateModifie              : Date   = Date()
    var dateValeur               : Date   = Date()
    var frequence                : Int16  = 0
    var libelle                  : String = ""
    var nextOccurrence           : Int16  = 0
    var occurrence               : Int16  = 0
    var typeFrequence            : Int16  = 0

    @Attribute var isProcessed: Bool = false
    
    @Attribute(.unique) var uuid : UUID   = UUID()
    public var id                : UUID { uuid }
    
    var category                 : EntityCategory?
    var paymentMode              : EntityPaymentMode?
//    @Relationship(inverse        : \EntityAccount.compteLie) var linkedAccount : EntityAccount?
    
    @Relationship var account    : EntityAccount

    @MainActor
    public init() {
        self.account = CurrentAccountManager.shared.getAccount()!
    }
    
    public init(
        amount        : Double,
        dateValeur    : Date,
        dateDebut     : Date,
        dateFin       : Date,
        frequence     : Int16,
        libelle       : String,
        nextOccurrence : Int16,
        occurrence    : Int16,
        typeFrequence : Int16,
        account       : EntityAccount ){
            
            self.amount = amount
            self.libelle = libelle
            self.dateFin = dateFin
            self.dateDebut = dateDebut
            self.dateValeur = dateValeur
            self.frequence =  frequence
            self.libelle = libelle
            self.nextOccurrence = nextOccurrence
            self.occurrence = occurrence
            self.typeFrequence = typeFrequence
            self.account = account
        }
}

extension EntitySchedule: CustomStringConvertible {
    public var description: String {
        "EntitySchedule(libelle: \(libelle), amount: \(amount), dateValeur: \(dateValeur.formatted()), isProcessed: \(isProcessed), uuid: \(uuid))"
    }
}

extension EntitySchedule {
    var categoryName: String {
        category?.name ?? "N/A"
    }
}

protocol ScheduleManaging {
    func create(account: EntityAccount?, name : String) throws -> EntitySchedule
    func getAllData() -> [EntitySchedule]?
    func save () throws
}

final class SchedulerManager: ScheduleManaging, ObservableObject  {

    @Published var schedulers = [EntitySchedule]()
    
    static let shared = SchedulerManager()
    
    var modelContext: ModelContext? {
        DataContext.shared.context
    }

    init() { }
    
    func create(account: EntityAccount?, name : String) throws -> EntitySchedule {
        let entity = EntitySchedule()
        modelContext?.insert(entity)
        try save()
        schedulers.append(entity)
        
        return entity
    }
    
    func update(entity: EntitySchedule, name: String) {
        entity.libelle = name
    }
    
    // Suppression d'une entité
    func delete(entity: EntitySchedule, undoManager: UndoManager?) {
        guard let modelContext = modelContext else { return }

        modelContext.undoManager = undoManager
        modelContext.undoManager?.beginUndoGrouping()
        modelContext.undoManager?.setActionName("Delete Schedule")
        modelContext.delete(entity)
        modelContext.undoManager?.endUndoGrouping()
    }
    
    // Récupérer toutes les données filtrées par compte
    func getAllData() -> [EntitySchedule]? {
        
        guard let currentAccount = CurrentAccountManager.shared.getAccount() else {
            printTag("Erreur : aucun compte courant trouvé.")
            return nil
        }
        
        let lhs = currentAccount.uuid
        let predicate = #Predicate<EntitySchedule>{ entity in entity.account.uuid == lhs }
        let sort =  [SortDescriptor(\EntitySchedule.libelle, order: .forward)]
        
        let descriptor = FetchDescriptor<EntitySchedule>(
            predicate: predicate,
            sortBy: sort )
        
        do {
            // Récupérez les entités en utilisant le FetchDescriptor
            schedulers = try modelContext?.fetch( descriptor ) ?? []
        } catch {
            printTag("Erreur lors de la récupération des données: \(error)")
            return [] // Retourne nil en cas d'erreur
        }
        return schedulers
    }
    
    
    @MainActor func createTransaction (entitySchedule: EntitySchedule) {
        
        entitySchedule.nextOccurrence += 1
        let account = CurrentAccountManager.shared.getAccount()!
        let entityStatus = StatusManager.shared.getAllData(for: account) ?? []
        
        let dateValeur = entitySchedule.dateValeur.noon
        
        let entityTransaction = EntityTransaction()
        
        entityTransaction.createAt       = Date().noon
        entityTransaction.updatedAt    = Date().noon
        entityTransaction.dateOperation  = dateValeur
        entityTransaction.datePointage   = dateValeur
        
        entityTransaction.account        = entitySchedule.account
        
        entityTransaction.paymentMode    = entitySchedule.paymentMode
        entityTransaction.status         = Date() >= dateValeur ? entityStatus[2] : entityStatus[1]
        
        entityTransaction.bankStatement = 0
        entityTransaction.uuid           = UUID()
        
        // create sous transaction
        let entitySousOperation = createSousOperation(for: entitySchedule)
        
        // addd sous transaction
        entityTransaction.addSubOperation(  entitySousOperation)
        
//        if entitySchedule.linkedAccount != nil {
//            //            createComptelie()
//        }
        
        do {
            try save()
        } catch {
            
        }
    }
    
    func createComptelie() {
        //            let entityTransactionsTransfert = NSEntityDescription.insertNewObject(forEntityName: "EntityTransactions", into: viewContext!) as! EntityTransactions
        //
        //            entityTransactionsTransfert.dateCree      = entityTransaction.dateCree
        //            entityTransactionsTransfert.dateModifie   = entityTransaction.dateModifie
        //            entityTransactionsTransfert.dateOperation = entityTransaction.dateOperation
        //            entityTransactionsTransfert.datePointage  = entityTransaction.datePointage
        //
        //            let compteLie = entitySchedule.compteLie!
        //            entityTransactionsTransfert.account        = compteLie
        //
        //            entityTransactionsTransfert.statut        = entityTransaction.statut
        //            entityTransactionsTransfert.bankStatement = entityTransaction.bankStatement
        //
        //            // le modePaiement existe t il ??
        //            var name = entityTransactionsTransfert.paymentMode?.name ?? "nil"
        //            let color = entityTransactionsTransfert.paymentMode?.color as? NSColor ?? NSColor.black
        //            let uuid = entityTransactionsTransfert.paymentMode?.uuid ?? UUID()
        //            let entityModePaiement = PaymentMode.shared.findOrCreate(account: compteLie, name: name, color: color , uuid: uuid)
        //            entityTransactionsTransfert.paymentMode  = entityModePaiement
        //
        //
        //            let entitySousOperations = entityTransactionsTransfert.sousOperations
        //            let entitySplitTransactions = entitySousOperations!.allObjects as! [EntitySousOperations]
        //            let entitySplitTransaction = entitySplitTransactions.first
        //
        //            let entityRubric = Rubric.shared.findOrCreate(account: compteLie, name: name, color: color, uuid: uuid)
        //
        //            // la categorie existe t elle ?
        //            name = entitySchedule.category?.name ?? "nil"
        //            let objectif = entitySchedule.category?.objectif
        //            let entityCategorie = Categories.shared.findOrCreate(account: compteLie, name: name, objectif: objectif!, uuid: uuid)
        //
        //            entitySplitTransaction?.category = entityCategorie
        //            entitySplitTransaction?.category?.rubric = entityRubric
        //            entitySplitTransaction?.amount       = -entitySchedule.amount
        //
        //            entityTransactionsTransfert.addToSousOperations(entitySousOperation)
        //
        //            entityTransactionsTransfert.uuid          = UUID()
        
    }
    
    // Créer une sous-opération
    func createSousOperation(for schedule: EntitySchedule) -> EntitySousOperation {
        let sousOperation = EntitySousOperation()
        
        let rubricName = schedule.category?.rubric?.name ?? ""
        let color = schedule.category?.rubric?.color ?? .black
        //        let rubricUUID = schedule.category?.rubric?.uuid ?? UUID()
        let rubric = RubricManager.shared.findOrCreate(account: schedule.account, name: rubricName, color: color)
        
        let categoryName = schedule.category?.name ?? ""
        let objectif = schedule.category?.objectif ?? 0.0
        //        let categoryUUID = schedule.category?.uuid ?? UUID()
        let category = CategoryManager.shared.findOrCreate(
            account: schedule.account,
            name: categoryName,
            objectif: objectif,
            rubric: rubric)
        
        sousOperation.category = category
        sousOperation.category?.rubric = rubric
        sousOperation.amount = schedule.amount
        sousOperation.libelle = schedule.libelle
        
        return sousOperation
    }
    
    func createTransaction(for schedule: EntitySchedule, on dateValeur: Date) {
        schedule.nextOccurrence += 1
        
        let transaction = EntityTransaction()
        
        transaction.createAt = Date()
        transaction.updatedAt = Date()
        transaction.dateOperation = dateValeur
        transaction.datePointage = dateValeur
        transaction.account = schedule.account
        transaction.paymentMode = schedule.paymentMode
        //        transaction.status = Date() >= dateValeur ? 2 : 1
        transaction.bankStatement = 0
        transaction.uuid = UUID()
        
        let sousOperation = createSousOperation(for: schedule)
        transaction.sousOperations.append( sousOperation )
        
//        if let linkedAccount = schedule.linkedAccount {
//            let transferTransaction = EntityTransaction()
//            transferTransaction.createAt = transaction.createAt
//            transferTransaction.updatedAt = transaction.updatedAt
//            transferTransaction.dateOperation = transaction.dateOperation
//            transferTransaction.datePointage = transaction.datePointage
//            transferTransaction.account = linkedAccount
//            transferTransaction.status = transaction.status
//            transferTransaction.bankStatement = transaction.bankStatement
//            
//            let paymentModeName = transferTransaction.paymentMode?.name ?? ""
//            let color = transferTransaction.paymentMode?.color ?? .black
//            let paymentModeUUID = transferTransaction.paymentMode?.uuid ?? UUID()
//            let paymentMode = PaymentModeManager.shared.findOrCreate(account: linkedAccount, name: paymentModeName, color: Color(color), uuid: paymentModeUUID)
//            
//            transferTransaction.paymentMode = paymentMode
//            
//            let rubric = RubricManager.shared.findOrCreate(
//                account: linkedAccount,
//                name: paymentModeName,
//                color: .black)
//            
//            let categoryName = schedule.category?.name ?? "nil"
//            let objectif = schedule.category?.objectif ?? 0.0
//            let category = CategoryManager.shared.findOrCreate(
//                account: linkedAccount,
//                name: categoryName,
//                objectif: objectif,
//                rubric: rubric)
//            
//            let transferSousOperation = EntitySousOperation()
//            transferSousOperation.category = category
//            transferSousOperation.category?.rubric = rubric
//            transferSousOperation.amount = -schedule.amount
//            
//            transferTransaction.sousOperations.append(transferSousOperation)
//            transferTransaction.uuid = UUID()
//            modelContext?.insert(transferTransaction) // Ajout explicite dans le contexte
//        }
        
        // Sauvegarde explicite
        if modelContext?.hasChanges ?? false{
            do {
                try modelContext?.save()
            } catch {
                printTag("Erreur lors de la sauvegarde : \(error.localizedDescription)")
            }
        }
    }
    func save () throws {
        
        do {
            try modelContext?.save()
        } catch {
            throw EnumError.saveFailed
        }
    }
    
//    func selectScheduler(_ scheduler: EntitySchedule) {
//        NotificationCenter.default.post(name: .didSelectScheduler, object: scheduler)
//    }
    
}

