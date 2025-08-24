
import SwiftUI
import SwiftData
import Combine


// MARK: - Vue racine avec gestion splash screen
struct ContentView: View {
    @EnvironmentObject var containerManager: ContainerManager
    
    var body: some View {
        Group {
            if containerManager.showingSplashScreen {
                SplashScreenView()
            } else {
                MainAppView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: containerManager.showingSplashScreen)
    }
}
