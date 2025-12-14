import SwiftUI
import AppKit

final class WindowControllerManager {
    static let shared = WindowControllerManager()
    
    private var helpWindow: NSWindow?
    
    private init() {}
    
    // Affiche (ou réactive) la fenêtre d’aide
    func showHelpWindow() {
        if let helpWindow, helpWindow.isVisible {
            // Si déjà visible, la ramener au premier plan
            DispatchQueue.main.async {
                helpWindow.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            return
        }
        
        // Créer la fenêtre si elle n’existe pas encore ou a été fermée
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = String(localized: "Application Manual")
        window.isReleasedWhenClosed = false // important pour conserver la référence
        window.center()
        
        let hostingController = NSHostingController(rootView: HelpManualView())
        window.contentViewController = hostingController
        
        // Quand on ferme, on garde l’instance mais on cache la fenêtre
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            // Ne pas nil la fenêtre si tu veux la réutiliser; ici on la garde
            // Option: self?.helpWindow = nil pour forcer une recréation à chaque fois
        }
        
        self.helpWindow = window
        DispatchQueue.main.async {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func closeHelpWindow() {
        helpWindow?.performClose(nil)
    }
}

