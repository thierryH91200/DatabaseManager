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
                .frame(minWidth: 900, minHeight: 600)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button(String(localized: "Create New Document...")) {
                    presentSavePanelAndCreate()
                }
                .keyboardShortcut("n")
                
                Button(String(localized: "Open existing document...")) {
                    presentOpenPanelAndOpen()
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
            CommandMenu(String(localized: "Help")) {
                Button(String(localized: "Application Manual")) {
                    WindowControllerManager.shared.showHelpWindow()
                }
                .keyboardShortcut("?", modifiers: [.command])
            }
        }
    }
    
    // MARK: - Helpers pour les panneaux système
    private func presentSavePanelAndCreate() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.store, .sqlite]
        panel.nameFieldStringValue = "New Base"
        panel.canCreateDirectories = true
        panel.allowsOtherFileTypes = false
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                containerManager.createNewDatabase(at: url)
            }
        }
    }
    
    private func presentOpenPanelAndOpen() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.store, .sqlite]
        panel.begin { response in
            if response == .OK, let url = panel.url {
                containerManager.openDatabase(at: url)
            }
        }
    }
}

final class AppGlobals {
    static let shared = AppGlobals()
    let schema = Schema([Person.self])
    
    private init() {}
}

//    @discardableResult
//    func update(name: String? = nil, town: String? = nil, age: Int? = nil) -> Person {
//        let person = Person(name: name, town: town, age: age)
//        modelContext?.insert(person)
//
//        entitiesPerson.append(person)
//        modelContext?.insert(person)
//        return person
//    }
