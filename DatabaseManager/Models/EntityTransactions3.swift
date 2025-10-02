//
//  EntityTransactions.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData

// Faster O(n) uniqueness when Element is Hashable.
public extension Sequence where Element: Hashable {
    var uniqueElements: [Element] {
        var seen = Set<Element>()
        return self.filter { seen.insert($0).inserted }
    }
}

// MARK: - Grouped models

final class GroupedYearOperations {
    let year: String
    var allMonth: [GroupedMonthOperations]
    
    // dictionary: key = year, value = [month: [TransactionItem]]
    init(dictionary: (key: String, value: [String: [TransactionItem]])) {
        self.year = dictionary.key
        
        let months = dictionary.value.map { (key: String, value: [TransactionItem]) -> GroupedMonthOperations in
            GroupedMonthOperations(month: key, transactions: value)
        }
        // NOTE: This is a lexicographic sort on strings.
        // Prefer a numeric month (1...12) for perfect ordering if possible.
        self.allMonth = months.sorted { $0.month > $1.month }
    }
}

final class GroupedMonthOperations {
    let month: String
    let transactions: [TransactionItem]
    
    init(month: String, transactions: [TransactionItem]) {
        self.month = month
        // Sort by posting date (pointage) descending
        self.transactions = transactions.sorted {
            $0.entityTransaction.datePointage > $1.entityTransaction.datePointage
        }
    }
}

// MARK: - Lightweight view model for a transaction
struct TransactionItem {
    let year: String
    let id: String
    let entityTransaction: EntityTransaction
    
    // Compute instead of storing when you can derive from the source of truth.
    var isCardPayment: Bool {
        guard let modeName = entityTransaction.paymentMode?.name else { return false }
        let bankCardName = String(localized: "Bank Card")
        return modeName == bankCardName
    }
}

@available(*, deprecated, renamed: "TransactionItem")
typealias Transaction = TransactionItem

