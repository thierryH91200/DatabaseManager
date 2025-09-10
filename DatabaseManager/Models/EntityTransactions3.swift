//
//  EntityTransactions.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData

public extension Sequence where Element: Equatable {
    var uniqueElements: [Element] {
        return self.reduce(into: []) {
            uniqueElements, element in
            
            if !uniqueElements.contains(element) {
                uniqueElements.append(element)
            }
        }
    }
}

// MARK: convert dictionary to class
class GroupedYearOperations : NSObject {
    let year     : String
    var allMonth : [GroupedMonthOperations]
    
    init( dictionary: (key: String, value: [String: [Transaction]])) {
        self.year = dictionary.key
        
        self.allMonth = [GroupedMonthOperations]()
        let months = (dictionary.value).map { (key: String , value: [Transaction]) -> GroupedMonthOperations in
            return GroupedMonthOperations(month : key , Transactions: value)
        }
        self.allMonth = months.sorted(by: {$0.month > $1.month})
    }
}

class GroupedMonthOperations : NSObject {
    let month       : String
    let transactions : [ Transaction ]
    
    init( month: String, Transactions: [Transaction]) {
        
        self.month = month
        let idAllOperation = (0 ..< Transactions.count).map { (i) -> Transaction in
            return Transaction(year : Transactions[i].year, id: Transactions[i].id, entityTransaction: Transactions[i].entityTransaction)
        }
        self.transactions = idAllOperation.sorted(by: { $0.entityTransaction.datePointage.timeIntervalSince1970 > $1.entityTransaction.datePointage.timeIntervalSince1970 })
    }
}

class Transaction : NSObject {
    let isCb             : Bool
    let year             : String
    let id               : String
    let entityTransaction : EntityTransaction
    
    init( year: String, id: String, entityTransaction: EntityTransaction) {
        self.year = year
        self.id = id
        self.entityTransaction = entityTransaction
        self.isCb = false
//        let mode = self.entityTransaction.paymentMode?.name
//        self.cb = mode == PaymentMethod.Bank_Card ? true : false
    }
}


