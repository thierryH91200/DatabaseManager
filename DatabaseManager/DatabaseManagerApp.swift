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
                Button("Create New Document...") {
                    // Action pour nouveau fichier
                }
                .keyboardShortcut("n")
                
                Button("Open existing document...") {
                    // Action pour fichiers récents
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }
        }
    }
}

final class AppGlobals {
    static let shared = AppGlobals()
    let schema = Schema([Person.self])
    
    private init() {}
}


