import SwiftUI
import SwiftData
import Combine

// MARK: - Vue racine
struct ContentView: View {
    @EnvironmentObject var containerManager: ContainerManager
    
    // Deux gestionnaires distincts pour mémoriser/restaurer des tailles différentes
    @StateObject private var splashSizeManager = WindowSizeManager(windowID: "SplashScreen")
    @StateObject private var mainSizeManager   = WindowSizeManager(windowID: "MainWindow")
    
    // Référence à la NSWindow hébergeant cette vue
    @State private var hostingWindow: NSWindow?
    
    var body: some View {
        Group {
            if containerManager.showingSplashScreen {
                SplashScreenView()
                    .onAppear { applyWindowProfile(isSplash: true, animated: true) }
            } else {
                MainAppView()
                    .onAppear { applyWindowProfile(isSplash: false, animated: true) }
            }
        }
        // Accéder à la NSWindow et appliquer le bon profil au premier rendu
        .background(
            WindowAccessor { window in
                guard let window else { return }
                hostingWindow = window
                applyWindowProfile(isSplash: containerManager.showingSplashScreen, animated: false)
            }
        )
        .animation(.easeInOut(duration: 0.25), value: containerManager.showingSplashScreen)
        .onChange(of: containerManager.showingSplashScreen) { _, isSplash in
            applyWindowProfile(isSplash: isSplash, animated: true)
        }
    }
    
    // Applique configuration, taille et contraintes selon l’écran affiché
    private func applyWindowProfile(isSplash: Bool, animated: Bool) {
        guard let window = hostingWindow else { return }
        
        // Choisir le bon manager et ID
        let manager = isSplash ? splashSizeManager : mainSizeManager
        let id = isSplash ? "SplashScreen" : "MainWindow"
        
        // Détacher l’ancien delegate et attacher le bon
        window.delegate = nil
        window.delegate = manager
        
        // Définir des contraintes de taille différentes si souhaité
        if isSplash {
            window.contentMinSize = NSSize(width: 700, height: 500)
            window.contentMaxSize = NSSize(width: 2000, height: 1400)
        } else {
            window.contentMinSize = NSSize(width: 900, height: 600)
            window.contentMaxSize = NSSize(width: 3000, height: 2000)
        }
        
        // Taille par défaut si aucune sauvegarde
        let defaultSize = isSplash
        ? NSSize(width: 800, height: 600)   // Splash
        : NSSize(width: 1200, height: 800)  // Main
        
        // Savoir si on a déjà une taille sauvegardée
        let hasSavedWidth = UserDefaults.standard.double(forKey: "\(id)_width") > 0
        
        if hasSavedWidth {
            // Restaurer la taille/position sauvegardée pour ce profil
            manager.applySavedSize(to: window)
        } else {
            // Appliquer la taille par défaut, centrée
            var frame = window.frame
            frame.size = defaultSize
            if let screenFrame = window.screen?.visibleFrame {
                frame.origin.x = screenFrame.midX - defaultSize.width / 2
                frame.origin.y = screenFrame.midY - defaultSize.height / 2
            }
            setWindowFrame(window, to: frame, animated: animated)
        }
        
        // Optionnel: changer le titre pour repérer l’état
        window.title = isSplash ? "Welcome" : containerManager.currentDatabaseName.isEmpty ? "Main" : containerManager.currentDatabaseName
        //        if let build = Bundle.main.object(forInfoDictionaryKey: "testBuild") as? String {
        //            print("Numéro de test build : \(build)")
    }
    
}

// Anime (ou non) la mise à jour de la frame
private func setWindowFrame(_ window: NSWindow, to frame: NSRect, animated: Bool) {
    if animated {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(frame, display: true)
        }
    } else {
        window.setFrame(frame, display: true)
    }
}

