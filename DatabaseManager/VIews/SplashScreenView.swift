//
//  SplashScreenView.swift
//  DatabaseManager
//
//  Created by thierryH24 on 24/08/2025.
//
//  https://claude.ai/chat/1ef9eddd-a134-44aa-aa9d-f72f9786c080

import SwiftUI
import SwiftData
import Combine
import UniformTypeIdentifiers


// MARK: - Splash Screen
struct SplashScreenView: View {
    @EnvironmentObject var containerManager: ContainerManager
    @State private var showingFilePicker = false
    @State private var showingSavePanel = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Logo/Button
            LeftPanelView()
            
            Divider()
            
            // Fichiers récents
            RecentProjectsListView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .fileImporter(
            isPresented: $showingFilePicker,
            // N’autoriser que .store
            allowedContentTypes: [.store],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    containerManager.openDatabase(at: url)
                }
            case .failure(let error):
                print("Erreur sélection fichier: \(error)")
            }
        }
    }
}

private struct LeftPanelView: View {
    
    @EnvironmentObject var containerManager: ContainerManager
    
    @State private var showingFilePicker = false
    @State private var showResetAlert = false
    @State private var showCopySuccessAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image("iconDataManager")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
            
            Text(String(localized: "Database Manager"))
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Manage your SwiftData databases")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Use interpolation so LocalizedStringResource can handle formatting

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"))")
            .foregroundColor(.secondary)
            
            // Actions principales
            VStack(spacing: 10) {
                // 1
                UniformLabeledButton(String(localized: "Create a new file"),
                                     systemImage: "plus.circle.fill",
                                     minWidth: 300,
                                     minHeight: 30,
                                     style: .borderedProminent) {
                    showSavePanel()
                }
                
                // 2
                UniformLabeledButton(String(localized: "Open existing document..."),
                                     systemImage: "doc.badge.ellipsis",
                                     minWidth: 300,
                                     minHeight: 30,
                                     style: .borderedProminent) {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = true
                    panel.canChooseDirectories = false
                    panel.allowsMultipleSelection = false
                    // N’autoriser que .store
                    panel.allowedContentTypes = [.store]
                    if panel.runModal() == .OK, let url = panel.url {
                        containerManager.openDatabase(at: url)
                    }
                }
                
                // 3
                UniformLabeledButton(String(localized: "Open sample document Project..."),
                                     systemImage: "wand.and.stars",
                                     minWidth: 300,
                                     minHeight: 30,
                                     style: .borderedProminent) {
                    preloadDBData()
                }
                
#if DEBUG
                // 4
                UniformLabeledButton(String(localized: "Reset preferences…"),
                                     systemImage: "gearshape.arrow.triangle.2.circlepath",
                                     minWidth: 300,
                                     minHeight: 30,
                                     style: .borderedProminent,
                                     tint: .red) {
                    showResetAlert = true
                }
                                     .alert("Confirm reset?", isPresented: $showResetAlert) {
                                         Button("Cancel", role: .cancel) {}
                                         Button("Reset", role: .destructive) {
                                             if let appDomain = Bundle.main.bundleIdentifier {
                                                 UserDefaults.standard.removePersistentDomain(forName: appDomain)
                                                 UserDefaults.standard.synchronize()
                                             }
                                         }
                                     } message: {
                                         Text("This operation will delete all application preferences. Are you sure you want to proceed?")
                                     }
#endif
            }
            .padding(.horizontal, 16)
            .background(Color(NSColor.windowBackgroundColor))
            
            Spacer()
        }
        .alert("Copy successful", isPresented: $showCopySuccessAlert) {
            Button(role: .cancel) {
                // No action needed
            } label: {
                Text("✅ OK")
            }
            .frame(width: 50)

        } message: {
            Text("The copy has been successfully completed.")
        }

        .frame(width: 332) // 300 utile + 2*16 padding
    }
    private func showSavePanel() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.store]
        panel.nameFieldStringValue = "New Base"
        panel.canCreateDirectories = true
        panel.allowsOtherFileTypes = false
        
        panel.begin { response in
            if response == .OK, var url = panel.url {
                // Sécurité: forcer .store
                if url.pathExtension.lowercased() != "store" {
                    url.deletePathExtension()
                    url.appendPathExtension("store")
                }
//                print("URL sélectionnée: \(url)")
                containerManager.createNewDatabase(at: url)
            }
        }
    }
    // https://stackoverflow.com/questions/40761140/how-to-pre-load-database-in-core-data-using-swift-3-xcode-8
    func preloadDBData() {
        let folder = "DataBaseManager"
//        let file = "SampleDataBaseManager.store"
        let documentsURL = URL.documentsDirectory
        let newDirectory = documentsURL.appendingPathComponent(folder)
        
        do {
            if !FileManager.default.fileExists(atPath: newDirectory.path) {
                try FileManager.default.createDirectory(at: newDirectory, withIntermediateDirectories: true)
            }
        } catch {
            print("❌ Erreur création base : \(error)")
            return
        }
                        
        guard let sqlitePath = Bundle.main.path(forResource: "SampleManager", ofType: "store") else {
            print("Fichier source introuvable dans le bundle")
            return
        }
        
        let URL1 = URL(fileURLWithPath: sqlitePath)
        let storeURL = newDirectory.appendingPathComponent("SampleManager.store")
        
        // Supprime l'ancien fichier s'il existe déjà à destination
        if FileManager.default.fileExists(atPath: storeURL.path) {
            do {
                try FileManager.default.removeItem(at: storeURL)
            } catch {
                print("Erreur lors de la suppression de l'ancien fichier : \(error)")
            }
        }
        
        do {
            try FileManager.default.copyItem(at: URL1, to: storeURL)
            print("Succes lors de la copie")
            print(storeURL.path)

            DispatchQueue.main.async {
                containerManager.openDatabase(at: storeURL)
                self.showCopySuccessAlert = true
            }
        } catch {
            print("Erreur lors de la copie : \(error)")
        }
    }
}

private struct RecentProjectsListView: View {
    @EnvironmentObject var containerManager: ContainerManager
    
    var body: some View {
        // Fichiers récents
        
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Recent files"))
                .font(.headline)
                .padding(.horizontal)
            
            if !containerManager.recentFiles.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 5) {
                        ForEach(containerManager.recentFiles) { recentFile in
                            RecentFileRow(recentFile: recentFile)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .frame(width: 400)
    }
}
