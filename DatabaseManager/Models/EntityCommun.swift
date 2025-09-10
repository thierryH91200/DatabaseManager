//
//  EntityCommun.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 14/03/2025.
//

import Foundation
import SwiftData
import SwiftUI
import os

enum EnumError: Error {
    case contextNotConfigured
    case accountNotFound
    case invalidStatusType
    case saveFailed
    case fetchFailed
}

// Singleton global pour centraliser le ModelContext et l'UndoManager.
// ContainerManager et d'autres parties du code les injectent ici.
final class DataContext {
    static let shared = DataContext()
    var context: ModelContext?
    var undoManager: UndoManager?

    private init() {}
}

// Logging utilitaire
@inline(__always)
func printTag(_ message: @autoclosure () -> String,
              category: String = "App",
              file: StaticString = #fileID,
              function: StaticString = #function,
              line: UInt = #line) {
    let text = message()
    #if canImport(os)
    if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "PegaseUIData",
                            category: category)
        logger.info("[\(file):\(line)] \(function, privacy: .public) — \(text, privacy: .public)")
        return
    }
    #endif
    // Fallback
    print("[\(category)] \(file):\(line) \(function) — \(text)")
}

extension Date {
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}

func formatPrice(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency // format monétaire
    formatter.locale = Locale.current // devise de l'utilisateur
    let format = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    return format
}


struct PriceText: View {
    let amount: Double

    var body: some View {
        Text(amount, format: .currency(code: currencyCode))
    }

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "EUR"
    }
}

func cleanDouble(from string: String) -> Double {
    // Supprime les caractères non numériques sauf , et .
    let cleanedString = string.filter { "0123456789,.".contains($0) }
    
    // Convertir la virgule en point si nécessaire
    let normalized = cleanedString.replacingOccurrences(of: ",", with: ".")
    
    return Double(normalized) ?? 0.0
}

// Keyboard shortcut notifications
extension Notification.Name {
    static let copySelectedTransactions = Notification.Name("copySelectedTransactions")
    static let cutSelectedTransactions = Notification.Name("cutSelectedTransactions")
    static let pasteSelectedTransactions = Notification.Name("pasteSelectedTransactions")
}
