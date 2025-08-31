import SwiftUI
import SwiftData
import Foundation
import Combine
import AppKit
internal import UniformTypeIdentifiers

// MARK: - App principale
@main
struct DatabaseManagerApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var containerManager = ContainerManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(containerManager)
//                .modelContainer(for: Person.self) { config, context in
//                    context.undoManager = UndoManager()   // ⚡ Obligatoire
//                }

                .frame(minWidth: 900, minHeight: 600)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button(String(localized: "Create New Document...")) {
                    // Action pour nouveau fichier
                }
                .keyboardShortcut("n")
                
                Button(String(localized: "Open existing document...")) {
                    // Action pour fichiers récents
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }
            CommandGroup(replacing: .undoRedo) {
                Button(String(localized: "Undo")) {
                    DataContext.shared.undoManager?.undo()
                }
                .keyboardShortcut("z")
                .disabled(!(DataContext.shared.undoManager?.canUndo ?? false))
                Button(String(localized: "Redo")) {
                    DataContext.shared.undoManager?.redo()
                }
                .keyboardShortcut("Z", modifiers: [.command, .shift])
                .disabled(!(DataContext.shared.undoManager?.canRedo ?? false))
            }
        }
    }
}

final class AppGlobals {
    static let shared = AppGlobals()
    let schema = Schema([Person.self])
    
    private init() {}
}

