//
//  SplashScreenView.swift
//  DatabaseManager
//
//  Created by thierryH24 on 24/08/2025.
//

import SwiftUI
import SwiftData
import Combine
import AppKit
internal import UniformTypeIdentifiers

// MARK: - Splash Screen
struct SplashScreenView: View {
    @EnvironmentObject var containerManager: ContainerManager
    @State private var showingFilePicker = false
    @State private var showingSavePanel = false
    
    private func showSavePanel() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.sqlite, .store]
        panel.nameFieldStringValue = "Nouvelle Base"
        panel.canCreateDirectories = true
        panel.allowsOtherFileTypes = false
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                print("URL sélectionnée: \(url)")

//                containerManager.createSimpleDatabase()
                containerManager.createNewDatabase(at: url)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Logo/Titre
            VStack(spacing: 10) {
                Spacer()
                
                Image(systemName: "hammer.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.accentColor)

                Text("Database Manager")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Manage your SwiftData databases")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Actions principales
            VStack(spacing: 0) {
                Button(action: {
                    showSavePanel()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Créer un nouveau fichier")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button(action: {
                    showingFilePicker = true
                }) {
                    HStack {
                        Image(systemName: "folder.fill")
                        Text("Ouvrir un fichier existant")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .frame(width: 300)
            
            // Fichiers récents
            if !containerManager.recentFiles.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Fichiers récents")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView {
                        LazyVStack(spacing: 5) {
                            ForEach(containerManager.recentFiles) { recentFile in
                                RecentFileRow(recentFile: recentFile)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                .frame(width: 400)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType(filenameExtension: "sqlite") ?? .data],
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

