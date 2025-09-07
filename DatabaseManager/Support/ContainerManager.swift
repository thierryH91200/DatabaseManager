//
//  ContainerManager.swift
//  DatabaseManager
//
//  Created by thierryH24 on 24/08/2025.
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Container Manager avec gestion fichiers récents
class ContainerManager: ObservableObject {
    @Published var currentContainer: ModelContainer?
    @Published var currentDatabaseName: String = ""
    @Published var currentDatabaseURL: URL?
    @Published var recentFiles: [RecentFile] = []
    @Published var showingSplashScreen = true
    
    private let recentFilesKey = "RecentDatabases"
    private let maxRecentFiles = 10
    
    let schema = AppSchema.shared.schema

    init() {
        loadRecentFiles()
    }
    
    // MARK: - Gestion des fichiers récents
    private func loadRecentFiles() {
        if let data = UserDefaults.standard.data(forKey: recentFilesKey),
           let files = try? JSONDecoder().decode([RecentFile].self, from: data) {
            // Filtrer les fichiers qui existent encore
            recentFiles = files.filter { FileManager.default.fileExists(atPath: $0.url.path) }
                              .sorted { $0.lastAccessed > $1.lastAccessed }
        }
    }
    
    private func saveRecentFiles() {
        if let data = try? JSONEncoder().encode(recentFiles) {
            UserDefaults.standard.set(data, forKey: recentFilesKey)
        }
    }
    
    private func addToRecentFiles(_ file: RecentFile) {
        // Supprimer le fichier s'il existe déjà
        recentFiles.removeAll { $0.url == file.url }
        
        // Ajouter en première position
        recentFiles.insert(file, at: 0)
        
        // Limiter le nombre de fichiers récents
        if recentFiles.count > maxRecentFiles {
            recentFiles = Array(recentFiles.prefix(maxRecentFiles))
        }
        saveRecentFiles()
    }
    
    func removeFromRecentFiles(url: URL) {
        recentFiles.removeAll { $0.url == url }
        saveRecentFiles()
    }
    
    // MARK: - Helpers
    private func sanitizeFileName(_ name: String) -> String {
        name
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "\"", with: "")
    }
    
    // MARK: - Gestion des bases de données (API principale)
    // Crée une base au chemin donné (p.ex. choisi via NSSavePanel)
    @MainActor
    func createNewDatabase(at url: URL) {
        let schema = AppSchema.shared.schema
        
        do {
            // Normaliser l’URL: nom de fichier nettoyé + extension .store
            let baseName = url.deletingPathExtension().lastPathComponent
            let sanitizedFileName = sanitizeFileName(baseName)
            
            // Dossier parent choisi par l'utilisateur dans le NSSavePanel
            let baseDirectory = url.deletingLastPathComponent()
            
            // Créer un sous-dossier portant le nom "sanitizedFileName"
            let parentDir = baseDirectory.appendingPathComponent(sanitizedFileName, isDirectory: true)
            if !FileManager.default.fileExists(atPath: parentDir.path) {
                try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true, attributes: nil)
            }
            
            // Construire l’URL finale: <parentDir>/<sanitizedFileName>.store
            var cleanURL = parentDir.appendingPathComponent(sanitizedFileName)
            if cleanURL.pathExtension != "store" {
                cleanURL = cleanURL.appendingPathExtension("store")
            }
            
//            print("🔧 Création de la base à: \(cleanURL.path)")
            
            // Configurer le container SwiftData
            let config = ModelConfiguration(
                schema: schema,
                url: cleanURL,
                allowsSave: true
            )
            
            let container = try ModelContainer(for: schema, configurations: config)
            let context = container.mainContext
            
            // Centraliser le ModelContext et l’UndoManager
            let globalUndo = UndoManager()
            DataContext.shared.context = context
            DataContext.shared.undoManager = globalUndo
            context.undoManager = globalUndo
            
            // Ajoute une personne de démonstration
            let samplePerson = PersonManager.shared.create(name: "Exemple", town: "Seoul", age: 25)
            openDatabase(at: cleanURL)
            
        } catch {
            print("❌ Erreur lors de la création : \(error)")
            let sqliteError = error as NSError
            print("❌ Code SQLite: \(sqliteError.code)")
            print("❌ Détails: \(sqliteError.userInfo)")
        }
    }
    
    @MainActor func openDatabase(at url: URL) {
        do {
            let config = ModelConfiguration(
                schema: schema,
                url: url
            )
            let container = try ModelContainer(for: schema, configurations: config)
            let context = container.mainContext
            
            // Centraliser le ModelContext et l'UndoManager global
            let globalUndo = UndoManager()
            DataContext.shared.context = context
            DataContext.shared.undoManager = globalUndo
            context.undoManager = globalUndo
            
            // Publier l'état courant
            currentContainer = container
            currentDatabaseURL = url
            currentDatabaseName = url.deletingPathExtension().lastPathComponent
            
            // Ajouter aux fichiers récents
            let recentFile = RecentFile(name: currentDatabaseName, url: url)
            addToRecentFiles(recentFile)
            
            // Ferme le splash screen
            showingSplashScreen = false
            
        } catch {
            print("Erreur lors de l'ouverture : \(error)")
        }
    }
    
    func closeCurrentDatabase() {
        currentContainer = nil
        currentDatabaseURL = nil
        currentDatabaseName = ""
        showingSplashScreen = true
        
        // Optionnel: réinitialiser le contexte global et l'undo manager
        DataContext.shared.context = nil
        DataContext.shared.undoManager = UndoManager()
    }
}
